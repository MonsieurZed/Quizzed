/// Lobby Detail View
///
/// Vue détaillée d'un lobby où les joueurs peuvent interagir avant le début d'une partie.
/// Permet de voir les joueurs présents, le code du lobby, les paramètres et de démarrer la partie.
library;

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

  const LobbyDetailView({super.key, required this.lobbyId});

  @override
  State<LobbyDetailView> createState() => _LobbyDetailViewState();
}

class _LobbyDetailViewState extends State<LobbyDetailView>
    with SingleTickerProviderStateMixin {
  bool _isLeavingLobby = false;
  bool _isStartingGame = false;
  bool _isDrawerExpanded = true; // État d'expansion du menu latéral
  final LoggerService logger = LoggerService();
  final String logTag = 'LobbyDetailView';

  // Animation pour le démarrage du quiz
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _joinLobbyStream();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 20.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToQuizSession();
      }
    });
  }

  @override
  void dispose() {
    // Se désabonner du stream du lobby si nécessaire
    // Utiliser try-catch pour éviter les erreurs avec les widgets désactivés
    try {
      if (mounted) {
        final lobbyController = Provider.of<LobbyController>(
          context,
          listen: false,
        );
        lobbyController.leaveLobbyStream();
      }
    } catch (e) {
      logger.error('Erreur lors du désabonnement du stream: $e', tag: logTag);
    }

    _animationController.dispose();
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
        // Utiliser pushReplacementNamed au lieu de goNamed pour préserver le menu latéral
        context.pushReplacementNamed(AppRoutes.lobbies);
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
          // Démarrer l'animation de transition
          setState(() {
            _isAnimating = true;
          });
          _animationController.forward();
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

  void _navigateToQuizSession() {
    if (!mounted) return;
    // TODO
    // final sessionController = Provider.of<QuizSessionController>(
    //   context,
    //   listen: false,
    // );

    // if (sessionController.currentSession != null) {
    //   context.pushReplacementNamed(
    //     AppRoutes.quizSession,
    //     pathParameters: {'id': sessionController.currentSession!.id},
    //   );
    // } else {
    //   setState(() {
    //     _isAnimating = false;
    //     _isStartingGame = false;
    //   });
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Erreur lors du démarrage de la partie')),
    //   );
    // }
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

  // Méthode pour supprimer le lobby (pour l'hôte uniquement)
  Future<void> _deleteLobby() async {
    // Demander une confirmation avant de supprimer
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer le lobby'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer ce lobby ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLeavingLobby = true);

    try {
      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );

      final success = await lobbyController.deleteLobby(widget.lobbyId);

      if (success && mounted) {
        // Utiliser pushReplacementNamed au lieu de goNamed pour préserver l'état du menu
        context.pushReplacementNamed(AppRoutes.lobbies);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression du lobby'),
          ),
        );
        setState(() => _isLeavingLobby = false);
      }
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la suppression du lobby : $e',
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression du lobby'),
          ),
        );
        setState(() => _isLeavingLobby = false);
      }
    }
  }

  // Méthode pour transférer la propriété du lobby à un autre joueur
  Future<void> _transferOwnership(String newOwnerId, String playerName) async {
    // Demander une confirmation avant de transférer la propriété
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Transférer la propriété'),
            content: Text(
              'Êtes-vous sûr de vouloir transférer la propriété du lobby à $playerName ?\n\n'
              'Vous ne serez plus l\'hôte du lobby et ne pourrez plus le supprimer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Transférer'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLeavingLobby = true);

    try {
      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );

      final success = await lobbyController.transferOwnership(
        widget.lobbyId,
        newOwnerId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La propriété a été transférée à $playerName'),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du transfert de propriété'),
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors du transfert de propriété : $e',
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du transfert de propriété'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLeavingLobby = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    final UserModel? user = authService.currentUserModel;
    final theme = Theme.of(context);

    if (currentUser == null) {
      return const Center(child: Text('Utilisateur non connecté'));
    }

    if (_isAnimating) {
      return _buildStartGameAnimation(theme);
    }

    return Consumer<LobbyController>(
      builder: (context, lobbyController, child) {
        final lobby = lobbyController.currentLobby;
        final isLoading = lobbyController.isLoading;
        final hasError = lobbyController.error != null;

        if (isLoading && lobby == null) {
          return const LoadingDisplay(message: 'Chargement du lobby...');
        }

        if (hasError) {
          return ErrorDisplay(
            title: 'Erreur de chargement',
            message: lobbyController.error ?? 'Une erreur est survenue',
            onRetry: _joinLobbyStream,
            onBack: () => context.go('/home/lobbies'),
          );
        }

        if (lobby == null) {
          return ErrorDisplay(
            title: 'Lobby introuvable',
            message: 'Ce lobby n\'existe pas ou a été supprimé',
            onBack: () => context.go('/home/lobbies'),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du lobby (en haut)
            _buildLobbyHeader(context, lobby),

            // Conteneur pour le reste du contenu avec défilement
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
            ),

            // Boutons d'action (en bas)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildActionButtons(
                context,
                lobby,
                isHost,
                currentPlayer.isReady,
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget pour l'animation de démarrage du quiz
  Widget _buildStartGameAnimation(ThemeData theme) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Stack(
            children: [
              // Cercle animé qui grandit
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              // Texte qui apparaît progressivement
              Center(
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'C\'est parti !',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Préparez-vous, le quiz commence...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLobbyHeader(BuildContext context, LobbyModel lobby) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha((255 * 0.1).toInt()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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

              // Code d'accès (si privé)
              if (lobby.visibility == LobbyVisibility.private &&
                  lobby.accessCode.isNotEmpty)
                InkWell(
                  onTap: () => _copyLobbyCode(lobby.accessCode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
          ),
          const SizedBox(height: 8),
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
        ],
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
        leading: AvatarDisplay(
          avatarUrl: player.avatarUrl,
          backgroundColor:
              player.avatarBackgroundColor != null
                  ? Color(
                    int.parse(
                      player.avatarBackgroundColor!.replaceFirst('#', '0xff'),
                    ),
                  )
                  : null, // Ajout de la couleur de fond
          size: 40,
        ),
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
                message: 'Propriétaire du lobby',
                child: Icon(Icons.star, size: 18, color: Colors.amber),
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

            // Bouton de transfert de propriété (visible pour l'hôte uniquement)
            if (isHost && !player.isHost)
              IconButton(
                onPressed:
                    () => _transferOwnership(player.userId, player.displayName),
                icon: Icon(
                  Icons.admin_panel_settings,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Transférer la propriété',
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
    final theme = Theme.of(context);

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

        const SizedBox(height: 8),

        // Bouton pour quitter le lobby (pour tous les joueurs)
        OutlinedButton.icon(
          onPressed: _isLeavingLobby ? null : _leaveLobby,
          icon:
              _isLeavingLobby
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.exit_to_app),
          label: const Text('Quitter le lobby'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),

        // Bouton pour supprimer le lobby (uniquement pour l'hôte)
        if (isHost) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _isLeavingLobby ? null : _deleteLobby,
            icon:
                _isLeavingLobby
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.delete_forever),
            label: const Text('Supprimer le lobby'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],

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
