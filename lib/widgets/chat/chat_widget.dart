/// Widget de chat complet
///
/// Affiche une liste de messages avec une zone de saisie pour en envoyer de nouveaux
/// Ce widget combine les fonctionnalités de l'ancien ChatWidget et ChatView
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/models/chat/chat_message_model.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/chat_service.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:quizzzed/utils/color_utils.dart';
import 'package:quizzzed/widgets/chat/chat_bubble.dart';
import 'package:quizzzed/controllers/lobby/lobby_controller.dart';
import 'package:quizzzed/widgets/shared/error_display.dart';
import 'package:quizzzed/widgets/shared/loading_display.dart';

class ChatWidget extends StatefulWidget {
  final String lobbyId;
  final double height;
  final bool showSendButton;
  final bool useFloatingInput;
  final bool autoFocus;
  final bool showChannelSelector;
  final bool initiallyShowEmojiPicker;

  const ChatWidget({
    super.key,
    required this.lobbyId,
    this.height = 300,
    this.showSendButton = true,
    this.useFloatingInput = true,
    this.autoFocus = false,
    this.showChannelSelector = true,
    this.initiallyShowEmojiPicker = false,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LoggerService _logger = LoggerService();
  final String _logTag = 'ChatWidget';

  bool _isLoading = false;
  bool _sendingMessage = false;
  bool _showEmojiPicker = false;
  final FocusNode _focusNode = FocusNode();

  // Index de l'onglet actif (0 = Général, 1 = Lobby)
  int _activeTabIndex = 1;
  ChatChannel _activeChannel = ChatChannel.lobby;

  // Contrôleur pour la TabBar
  late TabController _tabController;

  // Pour stocker le nom du lobby
  String _lobbyName = 'Lobby';

  late final ChatService _chatService;

  @override
  void initState() {
    super.initState();
    // Initialiser le contrôleur TabBar avec 2 onglets
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    _chatService = ChatService();

    // Par défaut, on commence sur l'onglet de lobby si un lobbyId est disponible
    _activeTabIndex = widget.lobbyId != 'general' ? 1 : 0;
    _tabController.index = _activeTabIndex;
    _activeChannel =
        _activeTabIndex == 0 ? ChatChannel.general : ChatChannel.lobby;

    _showEmojiPicker = widget.initiallyShowEmojiPicker;

    // Initialiser les streams de chat
    _chatService.joinChatStreams(widget.lobbyId);

    _loadMessages();
    _loadLobbyName();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging ||
        _tabController.index != _activeTabIndex) {
      setState(() {
        _activeTabIndex = _tabController.index;
        _activeChannel =
            _activeTabIndex == 0 ? ChatChannel.general : ChatChannel.lobby;
      });
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      // Chargement des messages déjà fait via le stream
    } catch (error, stackTrace) {
      _logger.error(
        'Erreur lors du chargement des messages: $error',
        tag: _logTag,
        stackTrace: stackTrace,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLobbyName() async {
    try {
      if (widget.lobbyId == 'general') {
        setState(() => _lobbyName = 'Général');
        return;
      }

      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );

      // Set up a listener for lobby changes instead of trying to access it directly
      lobbyController.loadLobby(widget.lobbyId);

      // Add a listener to update the lobby name when it changes
      lobbyController.addListener(() {
        if (mounted && lobbyController.currentLobby != null) {
          setState(() => _lobbyName = lobbyController.currentLobby!.name);
        }
      });
    } catch (error, stackTrace) {
      _logger.error(
        'Erreur lors du chargement du nom du lobby: $error',
        tag: _logTag,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sendingMessage = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentFirebaseUser;
    if (currentUser == null) {
      _logger.error(
        'Impossible d\'envoyer un message: utilisateur non connecté',
        tag: _logTag,
      );
      setState(() => _sendingMessage = false);
      return;
    }

    try {
      final lobbyId =
          _activeChannel == ChatChannel.general ? 'general' : widget.lobbyId;

      await _chatService.sendMessage(
        lobbyId: lobbyId,
        message: text,
        senderId: authService.currentUserModel!.uid,
        senderName: authService.currentUserModel!.displayName ?? 'Utilisateur',
        senderColor:
            ColorUtils.toStorageValue(authService.currentUserModel!.color)!,
        channel: _activeChannel,
      );

      _messageController.clear();

      // Fermer le sélecteur d'emojis s'il est ouvert
      if (_showEmojiPicker) {
        setState(() {
          _showEmojiPicker = false;
        });
      }

      // Faire défiler vers le bas
      _scrollToBottom();
    } catch (error) {
      _logger.error('Erreur lors de l\'envoi du message: $error', tag: _logTag);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi du message: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingMessage = false);
      }
    }
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    _messageController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    // Permettre l'envoi avec "Enter" sans modificateurs
    // (mais pas avec "Shift+Enter" qui doit insérer une nouvelle ligne)
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          !event.isShiftPressed &&
          !event.isControlPressed &&
          !event.isAltPressed) {
        _sendMessage();
      }
    }
  }

  // Méthode pour faire défiler la liste vers le dernier message
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

    return Column(
      children: [
        // Optionnellement afficher le sélecteur de canal
        if (widget.showChannelSelector) _buildChannelSelector(theme),

        // Liste des messages
        Expanded(child: _buildMessageList()),

        // Zone de saisie des messages
        _buildInputArea(theme),

        // Sélecteur d'emojis
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(onEmojiSelected: _onEmojiSelected),
          ),
      ],
    );
  }

  Widget _buildChannelSelector(ThemeData theme) {
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
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.public), text: 'Général'),
          Tab(icon: Icon(Icons.group), text: 'Lobby'),
        ],
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
        indicatorColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<ChatMessageModel>>(
      stream: _chatService.getMessagesForLobby(
        _activeChannel == ChatChannel.general ? 'general' : widget.lobbyId,
        _activeChannel,
      ),
      builder: (context, snapshot) {
        final theme = Theme.of(context);

        if (snapshot.hasError) {
          return ErrorDisplay(
            title: 'Erreur de chargement',
            message: 'Impossible de charger les messages: ${snapshot.error}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return const LoadingDisplay(message: 'Chargement des messages...');
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

        // Faire défiler vers le bas lors du chargement initial des messages
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final authService = Provider.of<AuthService>(
              context,
              listen: false,
            );
            final isCurrentUser =
                message.userId == authService.currentFirebaseUser?.uid;

            return ChatBubble(message: message, isCurrentUser: isCurrentUser);
          },
        );
      },
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow:
            widget.useFloatingInput
                ? [
                  BoxShadow(
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ]
                : null,
      ),
      child: Row(
        children: [
          // Bouton d'emoji (optionnel)
          IconButton(
            icon: Icon(
              _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
              color: theme.iconTheme.color?.withOpacity(0.7),
            ),
            onPressed: _toggleEmojiPicker,
          ),

          // Zone de saisie
          Expanded(
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: _handleKeyEvent,
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Écrire un message...',
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
                onTap: () {
                  if (_showEmojiPicker) {
                    setState(() {
                      _showEmojiPicker = false;
                    });
                  }
                },
                autofocus: widget.autoFocus,
              ),
            ),
          ),

          // Bouton d'envoi
          if (widget.showSendButton)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: FloatingActionButton(
                onPressed: _sendingMessage ? null : _sendMessage,
                elevation: 0,
                tooltip: 'Envoyer',
                mini: true,
                child:
                    _sendingMessage
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.send),
              ),
            ),
        ],
      ),
    );
  }
}
