/// Widget d'affichage du tchat
///
/// Affiche l'interface complète du tchat avec la liste des messages
/// et la zone de saisie pour envoyer de nouveaux messages
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/models/chat/chat_message_model.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/chat_service.dart';
import 'package:quizzzed/utils/color_utils.dart';
import 'package:quizzzed/widgets/chat/chat_bubble.dart';
import 'package:quizzzed/widgets/shared/error_display.dart';
import 'package:quizzzed/widgets/shared/loading_display.dart';

/// Widget qui affiche l'interface complète du tchat
class ChatView extends StatefulWidget {
  /// ID du lobby associé au tchat
  final String lobbyId;

  /// Constructeur
  const ChatView({super.key, required this.lobbyId});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  /// Contrôleur pour le champ de texte
  final TextEditingController _messageController = TextEditingController();

  /// Contrôleur de scroll pour faire défiler automatiquement vers le bas
  final ScrollController _scrollController = ScrollController();

  /// Service de tchat
  late final ChatService _chatService;

  /// Service d'authentification
  late final AuthService _authService;

  /// Canal actif (lobby par défaut)
  ChatChannel _activeChannel = ChatChannel.lobby;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _authService = Provider.of<AuthService>(context, listen: false);

    // Initialiser les streams de chat
    _chatService.joinChatStreams(widget.lobbyId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Vérifie si l'utilisateur peut accéder au chat de lobby
  bool _canAccessLobbyChat() {
    final currentUserModel = _authService.currentUserModel;
    // L'utilisateur peut accéder au chat du lobby s'il est actuellement dans un lobby
    return currentUserModel != null &&
        currentUserModel.currentLobbyId != null &&
        currentUserModel.currentLobbyId == widget.lobbyId;
  }

  /// Change le canal actif
  void _switchChannel(ChatChannel channel) {
    // Si l'utilisateur essaie d'accéder au chat du lobby mais n'est pas dans un lobby,
    // on affiche un message et on ne change pas de canal
    if (channel == ChatChannel.lobby && !_canAccessLobbyChat()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être dans un lobby pour accéder à ce chat'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_activeChannel != channel) {
      setState(() {
        _activeChannel = channel;
      });
    }
  }

  /// Méthode pour envoyer un message
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    // Vérifier si l'utilisateur peut envoyer un message dans ce canal
    if (_activeChannel == ChatChannel.lobby && !_canAccessLobbyChat()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous devez être dans un lobby pour envoyer des messages',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final currentUserFire = _authService.currentFirebaseUser;
    final currentUserModel = _authService.currentUserModel;
    if (currentUserFire == null) return;

    try {
      await _chatService.sendMessage(
        lobbyId: widget.lobbyId,
        message: text,
        senderId: currentUserFire.uid,
        senderName: currentUserModel!.displayName ?? 'Utilisateur',
        senderAvatar: currentUserModel.avatar,
        senderColor: currentUserModel.colorString!,
        channel: _activeChannel, // Utiliser le canal actif
      );

      _messageController.clear();

      // Faire défiler vers le bas après l'envoi d'un message
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi du message: $e')),
        );
      }
    }
  }

  /// Méthode pour faire défiler la liste vers le dernier message
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Vérifie l'accès au chat du lobby pour l'interface utilisateur
    final bool canAccessLobbyChat = _canAccessLobbyChat();

    // Si l'utilisateur est sur le chat du lobby mais n'y a plus accès,
    // basculer automatiquement vers le chat général
    if (_activeChannel == ChatChannel.lobby && !canAccessLobbyChat) {
      // On utilise Future.microtask pour éviter de modifier l'état pendant le build
      Future.microtask(() {
        setState(() {
          _activeChannel = ChatChannel.general;
        });
      });
    }

    return Column(
      children: [
        // En-tête avec sélecteur de canal
        _buildChannelSelector(theme, canAccessLobbyChat),

        // Liste des messages
        Expanded(
          child: StreamBuilder<List<ChatMessageModel>>(
            stream: _chatService.getMessagesForLobby(
              _activeChannel == ChatChannel.general
                  ? 'general'
                  : widget.lobbyId,
              _activeChannel,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorDisplay(
                  title: 'Erreur de chargement',
                  message:
                      'Impossible de charger les messages: ${snapshot.error}',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingDisplay(
                  message: 'Chargement des messages...',
                );
              }

              final messages = snapshot.data ?? [];

              // Trier les messages par horodatage
              messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

              // S'il n'y a pas de messages, afficher un message
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun message pour le moment.\nSoyez le premier à écrire!',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(
                        (0.6 * 255).toInt(),
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              // Faire défiler vers le bas lors du chargement initial
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToBottom(),
              );

              // Afficher la liste des messages
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isCurrentUser =
                      message.userId == _authService.currentFirebaseUser?.uid;

                  return ChatBubble(
                    message: message,
                    isCurrentUser: isCurrentUser,
                  );
                },
              );
            },
          ),
        ),

        // Zone de saisie du message
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, -2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Champ de texte pour le message
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText:
                        _activeChannel == ChatChannel.lobby &&
                                !canAccessLobbyChat
                            ? 'Rejoignez un lobby pour écrire...'
                            : 'Écrire un message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                  enabled:
                      !(_activeChannel == ChatChannel.lobby &&
                          !canAccessLobbyChat),
                ),
              ),
              const SizedBox(width: 8),

              // Bouton d'envoi du message
              FloatingActionButton(
                onPressed:
                    _activeChannel == ChatChannel.lobby && !canAccessLobbyChat
                        ? null // Désactiver le bouton quand on ne peut pas envoyer
                        : _sendMessage,
                elevation: 0,
                tooltip: 'Envoyer',
                mini: true,
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit le sélecteur de canal
  Widget _buildChannelSelector(ThemeData theme, bool canAccessLobbyChat) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<ChatChannel>(
                  segments: [
                    ButtonSegment<ChatChannel>(
                      value: ChatChannel.general,
                      label: const Text('Général'),
                      icon: const Icon(Icons.public),
                    ),
                    ButtonSegment<ChatChannel>(
                      value: ChatChannel.lobby,
                      label: const Text('Lobby'),
                      icon: const Icon(Icons.group),
                    ),
                  ],
                  selected: <ChatChannel>{_activeChannel},
                  onSelectionChanged: (Set<ChatChannel> selection) {
                    _switchChannel(selection.first);
                  },
                ),
              ),
            ],
          ),

          // Ajouter un indicateur visuel si le chat du lobby est verrouillé
          if (!canAccessLobbyChat && _activeChannel == ChatChannel.lobby)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.lock, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Chat verrouillé - Rejoignez un lobby pour participer',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
