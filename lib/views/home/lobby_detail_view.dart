/// Lobby Detail View
///
/// Vue détaillée d'un lobby où les joueurs peuvent interagir avant le début d'une partie.
/// Permet de voir les joueurs présents, le code du lobby, les paramètres et de démarrer la partie.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/controllers/lobby_controller.dart';
import 'package:quizzzed/controllers/quiz_session_controller.dart';
import 'package:quizzzed/models/quiz/lobby_model.dart';
import 'package:quizzzed/models/user/user_model.dart';
import 'package:quizzzed/routes/app_routes.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:quizzzed/widgets/profile/avatar_preview.dart';
import 'package:quizzzed/widgets/shared/avatar_display.dart';
import 'package:quizzzed/widgets/shared/error_display.dart';
import 'package:quizzzed/widgets/shared/loading_display.dart';
import 'package:quizzzed/widgets/shared/section_header.dart';

class LobbyDetailView extends StatefulWidget {
  final String lobbyId;

  const LobbyDetailView({Key? key, required this.lobbyId}) : super(key: key);

  @override
  State<LobbyDetailView> createState() => _LobbyDetailViewState();
}

class _LobbyDetailViewState extends State<LobbyDetailView> {
  bool _isLeavingLobby = false;
  bool _isStartingGame = false;
  bool _isDrawerExpanded = true; // État d'expansion du menu latéral
  final LoggerService logger = LoggerService();
  final String logTag = 'LobbyDetailView';

  @override
  void initState() {
    super.initState();
    _joinLobbyStream();
  }

  @override
  void dispose() {
    // Se désabonner du stream du lobby si nécessaire
    final lobbyController = Provider.of<LobbyController>(
      context,
      listen: false,
    );
    lobbyController.leaveLobbyStream();
    super.dispose();
  }

  Future<void> _joinLobbyStream() async {
    final lobbyController = Provider.of<LobbyController>(
      context,
      listen: false,
    );
    await lobbyController.joinLobbyStream(widget.lobbyId);
  }

  Future<void> _leaveLobby() async {
    setState(() => _isLeavingLobby = true);

    try {
      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );
      await lobbyController.leaveLobby(widget.lobbyId);

      if (mounted) {
        context.goNamed(AppRoutes.lobbies);
      }
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la sortie du lobby : $e',
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la sortie du lobby')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLeavingLobby = false);
      }
    }
  }

  Future<void> _startGame() async {
    setState(() => _isStartingGame = true);

    try {
      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );
      final sessionController = Provider.of<QuizSessionController>(
        context,
        listen: false,
      );

      final sessionId = await lobbyController.startGame(widget.lobbyId);

      if (sessionId != null && mounted) {
        final success = await sessionController.joinSession(sessionId);

        if (success && mounted) {
          context.pushReplacementNamed(
            AppRoutes.quizSession,
            pathParameters: {'id': sessionId},
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors du démarrage de la partie'),
            ),
          );
          setState(() => _isStartingGame = false);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de démarrer la partie')),
        );
        setState(() => _isStartingGame = false);
      }
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors du démarrage de la partie: $e',
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du démarrage de la partie'),
          ),
        );
        setState(() => _isStartingGame = false);
      }
    }
  }

  Future<void> _toggleReadyStatus() async {
    try {
      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );
      await lobbyController.togglePlayerStatus(widget.lobbyId);
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors du changement de statut :  $e',
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du changement de statut')),
        );
      }
    }
  }

  Future<void> _kickPlayer(String playerId) async {
    try {
      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );
      final success = await lobbyController.removePlayerFromLobby(
        widget.lobbyId,
        playerId,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'expulser ce joueur')),
        );
      }
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de l\'expulsion du joueur: $e',
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'expulsion du joueur'),
          ),
        );
      }
    }
  }

  void _copyLobbyCode(String code) {
    Clipboard.setData(ClipboardData(text: code)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copié dans le presse-papier'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  // Construction du menu latéral
  Widget _buildSideNav(ThemeData theme, UserModel? user, bool isSmallScreen) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Accueil',
        'route': AppRoutes.home,
      },
      {
        'icon': Icons.groups_outlined,
        'activeIcon': Icons.groups,
        'label': 'Lobbys',
        'route': AppRoutes.lobbies,
        'isSelected': true,
      },
      {
        'icon': Icons.leaderboard_outlined,
        'activeIcon': Icons.leaderboard,
        'label': 'Classement',
        'route': null, // Non implémenté
      },
      {
        'icon': Icons.add_circle_outlined,
        'activeIcon': Icons.add_circle,
        'label': 'Créer',
        'route': AppRoutes.createLobby,
      },
      {
        'icon': Icons.settings_outlined,
        'activeIcon': Icons.settings,
        'label': 'Paramètres',
        'route': null, // Non implémenté
      },
    ];

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // En-tête du menu avec avatar et nom de l'utilisateur
          if (_isDrawerExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AvatarPreview(
                    avatarUrl:
                        user?.photoUrl ?? 'assets/images/avatars/logo.png',
                    backgroundColor: user?.avatarBackgroundColor,
                    size: 80,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.displayName ?? 'Utilisateur',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          if (!_isDrawerExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: AvatarPreview(
                avatarUrl: user?.photoUrl ?? 'assets/images/avatars/logo.png',
                backgroundColor: user?.avatarBackgroundColor,
                size: 40,
              ),
            ),

          const Divider(),

          // Options de menu
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = item['isSelected'] ?? false;

                return ListTile(
                  leading: Icon(
                    isSelected ? item['activeIcon'] : item['icon'],
                    color:
                        isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                  ),
                  title:
                      _isDrawerExpanded
                          ? Text(
                            item['label'],
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          )
                          : null,
                  selected: isSelected,
                  onTap: () {
                    if (item['route'] != null) {
                      context.goNamed(item['route']);
                    }
                  },
                );
              },
            ),
          ),

          // Bouton pour replier/déplier le menu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(
                _isDrawerExpanded ? Icons.chevron_left : Icons.chevron_right,
              ),
              onPressed: () {
                setState(() {
                  _isDrawerExpanded = !_isDrawerExpanded;
                });
              },
              tooltip: _isDrawerExpanded ? 'Replier' : 'Déplier',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    final UserModel? user = authService.currentUserModel;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Déterminer si le menu doit être replié par défaut sur les petits écrans
    final bool isSmallScreen = screenWidth < 600;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Menu latéral
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width:
                isSmallScreen
                    ? (_isDrawerExpanded ? 250 : 70)
                    : (_isDrawerExpanded ? 250 : 70),
            child: _buildSideNav(theme, user, isSmallScreen),
          ),

          // Ligne de séparation
          VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),

          // Contenu principal
          Expanded(
            child: Consumer<LobbyController>(
              builder: (context, lobbyController, child) {
                final lobby = lobbyController.currentLobby;
                final isLoading = lobbyController.isLoading;
                final hasError = lobbyController.error != null;

                if (isLoading && lobby == null) {
                  return const LoadingDisplay(
                    message: 'Chargement du lobby...',
                  );
                }

                if (hasError) {
                  return ErrorDisplay(
                    title: 'Erreur de chargement',
                    message: lobbyController.error ?? 'Une erreur est survenue',
                    onRetry: _joinLobbyStream,
                    onBack: () => context.goNamed(AppRoutes.lobbies),
                  );
                }

                if (lobby == null) {
                  return ErrorDisplay(
                    title: 'Lobby introuvable',
                    message: 'Ce lobby n\'existe pas ou a été supprimé',
                    onBack: () => context.goNamed(AppRoutes.lobbies),
                  );
                }

                final isHost = lobby.hostId == currentUser.uid;
                final currentPlayer = lobby.players.firstWhere(
                  (p) => p.userId == currentUser.uid,
                  orElse:
                      () => LobbyPlayerModel(
                        userId: currentUser.uid,
                        displayName: currentUser.displayName!,
                        avatarUrl: currentUser.photoURL ?? '',
                        isHost: false,
                        isReady: false,
                        joinedAt: DateTime.now(),
                      ),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations du lobby
                      _buildLobbyHeader(context, lobby),
                      const SizedBox(height: 24),

                      // Liste des joueurs
                      SectionHeader(
                        title:
                            'Joueurs (${lobby.players.length}/${lobby.maxPlayers})',
                        action: Text(
                          '${lobby.minPlayers} minimum pour démarrer',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lobby.players.length,
                        itemBuilder: (context, index) {
                          final player = lobby.players[index];
                          return _buildPlayerItem(
                            context,
                            player,
                            isHost,
                            player.userId == currentUser.uid,
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Boutons d'action
                      _buildActionButtons(
                        context,
                        lobby,
                        isHost,
                        currentPlayer.isReady,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLobbyHeader(BuildContext context, LobbyModel lobby) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  lobby.visibility == LobbyVisibility.private
                      ? Icons.lock
                      : Icons.public,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lobby.name,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getCategoryIcon(lobby.category),
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Catégorie: ${lobby.category}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Code d'accès (si privé)
            if (lobby.visibility == LobbyVisibility.private &&
                lobby.accessCode != null &&
                lobby.accessCode!.isNotEmpty) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _copyLobbyCode(lobby.accessCode!),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Code: ${lobby.accessCode}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.copy,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerItem(
    BuildContext context,
    LobbyPlayerModel player,
    bool isHost,
    bool isCurrentUser,
  ) {
    final theme = Theme.of(context);
    final canKick = isHost && !player.isHost;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isCurrentUser
                ? theme.colorScheme.primaryContainer.withAlpha(
                  (255 * 0.2).toInt(),
                )
                : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isCurrentUser
                  ? theme.colorScheme.primary.withAlpha((255 * 0.3).toInt())
                  : theme.dividerColor,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: AvatarDisplay(avatarUrl: player.avatarUrl, size: 40),
        title: Row(
          children: [
            Expanded(
              child: Text(
                player.displayName,
                style: TextStyle(
                  fontWeight:
                      player.isHost ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (player.isHost)
              Tooltip(
                message: 'Hôte',
                child: Icon(
                  Icons.star,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
              ),
          ],
        ),
        subtitle: Text(
          'A rejoint ${_getTimeAgo(player.joinedAt)}',
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur de statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    player.isReady
                        ? theme.colorScheme.primaryContainer
                        : theme.disabledColor.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                player.isReady ? 'Prêt' : 'En attente',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      player.isReady
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Bouton d'expulsion (visible pour l'hôte uniquement)
            if (canKick)
              IconButton(
                onPressed: () => _kickPlayer(player.userId),
                icon: Icon(
                  Icons.person_remove,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Expulser',
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    LobbyModel lobby,
    bool isHost,
    bool isReady,
  ) {
    final canStart = lobby.canStart && isHost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isHost)
          ElevatedButton.icon(
            onPressed: canStart && !_isStartingGame ? _startGame : null,
            icon:
                _isStartingGame
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.play_arrow),
            label: const Text('Démarrer la partie'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _toggleReadyStatus,
            icon: Icon(isReady ? Icons.check_circle : Icons.not_interested),
            label: Text(isReady ? 'Je ne suis plus prêt' : 'Je suis prêt'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor:
                  isReady
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
            ),
          ),
        if (isHost &&
            !canStart &&
            lobby.players.length >= lobby.minPlayers) ...[
          const SizedBox(height: 12),
          Text(
            'En attente que tous les joueurs soient prêts',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ] else if (isHost && lobby.players.length < lobby.minPlayers) ...[
          const SizedBox(height: 12),
          Text(
            'En attente de plus de joueurs',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'science':
        return Icons.science;
      case 'histoire':
        return Icons.history_edu;
      case 'géographie':
      case 'geographie':
        return Icons.public;
      case 'sport':
        return Icons.sports;
      case 'musique':
        return Icons.music_note;
      case 'cinéma':
      case 'cinema':
        return Icons.movie;
      case 'littérature':
      case 'litterature':
        return Icons.book;
      case 'art':
        return Icons.palette;
      case 'technologie':
        return Icons.computer;
      case 'cuisine':
        return Icons.restaurant;
      default:
        return Icons.quiz;
    }
  }

  // Calcule et formate le temps écoulé depuis que le joueur a rejoint le lobby
  String _getTimeAgo(DateTime joinTime) {
    final now = DateTime.now();
    final difference = now.difference(joinTime);

    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} ${difference.inDays == 1 ? 'jour' : 'jours'}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours} ${difference.inHours == 1 ? 'heure' : 'heures'}';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return 'à l\'instant';
    }
  }
}
