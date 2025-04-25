/// Lobby Detail View
///
/// Vue détaillée d'un lobby où les joueurs peuvent interagir avant le début d'une partie.
/// Permet de voir les joueurs présents, le code du lobby, les paramètres et de démarrer la partie.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/controllers/lobby/lobby_controller.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';
import 'package:quizzzed/models/lobby/lobby_player_model.dart';
import 'package:quizzzed/routes/app_routes.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:quizzzed/views/home/lobby/create_lobby_view.dart'; // Import de CreateLobbyView
import 'package:quizzzed/widgets/chat/chat_view.dart'; // Import de ChatView
import 'package:quizzzed/widgets/profile/avatar_preview.dart';
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
  bool _isEditingLobby = false;
  final LoggerService logger = LoggerService();
  final String logTag = 'LobbyDetailView';
  // Référence au controller stockée lors de l'initialisation
  late LobbyController _lobbyController;

  // Animation pour le démarrage du quiz
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isAnimating = false;

  // Controllers pour l'édition du lobby
  final TextEditingController _nameController = TextEditingController();
  String _selectedCategory = 'Général';
  LobbyVisibility _selectedVisibility = LobbyVisibility.public;
  int _maxPlayers = 10;
  int _minPlayers = 2;

  // Variable d'état pour suivre si le chargement est complet
  bool _hasBeenLoaded = false;

  // Variable pour suivre l'état du débogage et du chargement
  bool _isDebugging = true;
  bool _hasCompletedLoading = false;

  // Variable pour suivre si le rafraîchissement est en cours
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Initialiser la référence au controller avec accès direct
    _lobbyController = Provider.of<LobbyController>(context, listen: false);

    // Variable pour suivre si le rafraîchissement est en cours
    _isRefreshing = false;

    logger.debug(
      'initState: Initialisation du LobbyDetailView pour le lobby ${widget.lobbyId}',
      tag: logTag,
    );
    logger.debug(
      'initState: État initial du contrôleur - isLoading: ${_lobbyController.isLoading}, hasError: ${_lobbyController.hasError}, currentLobby: ${_lobbyController.currentLobby != null}',
      tag: logTag,
    );

    // Initialiser les animations avant tout pour éviter des erreurs
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

    // Charger le lobby après l'initialisation de la vue
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logger.debug(
        'postFrameCallback: Démarrage du chargement du lobby',
        tag: logTag,
      );
      _loadLobbyWithDebug();

      // Vérifier l'état du lobby périodiquement pour détecter les problèmes
      _startDebugTimer();
    });
  }

  // Méthode pour charger le lobby avec des logs de débogage détaillés
  Future<void> _loadLobbyWithDebug() async {
    logger.debug(
      '_loadLobbyWithDebug: Début du chargement du lobby ${widget.lobbyId}',
      tag: logTag,
    );

    try {
      // DIAGNOSTIC: Vérifier directement si le lobby existe dans Firestore
      final diagnosticResult = await _lobbyController.debugVerifyLobbyExists(
        widget.lobbyId,
      );
      logger.debug(
        '_loadLobbyWithDebug: DIAGNOSTIC RESULT: $diagnosticResult',
        tag: logTag,
      );

      if (diagnosticResult['exists'] == true) {
        logger.debug(
          '_loadLobbyWithDebug: Lobby trouvé dans la collection "${diagnosticResult['collection']}"',
          tag: logTag,
        );
      } else {
        logger.warning(
          '_loadLobbyWithDebug: Le lobby ${widget.lobbyId} n\'existe pas dans Firestore!',
          tag: logTag,
        );
      }

      logger.debug(
        '_loadLobbyWithDebug: Avant appel à loadExistingLobby - isLoading: ${_lobbyController.isLoading}, currentLobby: ${_lobbyController.currentLobby?.name ?? "null"}',
        tag: logTag,
      );

      // Utiliser loadExistingLobby pour charger le lobby
      final success = await _lobbyController.loadExistingLobby(widget.lobbyId);

      logger.debug(
        '_loadLobbyWithDebug: Après appel à loadExistingLobby - success: $success, isLoading: ${_lobbyController.isLoading}, currentLobby: ${_lobbyController.currentLobby?.name ?? "null"}',
        tag: logTag,
      );

      // Marquer que le chargement est terminé pour la surveillance du débogage
      _hasCompletedLoading = true;

      if (!success && mounted) {
        logger.warning(
          '_loadLobbyWithDebug: Échec du chargement du lobby: ${widget.lobbyId}',
          tag: logTag,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossible de charger ce lobby. Il n\'existe peut-être plus.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        logger.debug(
          '_loadLobbyWithDebug: Lobby chargé avec succès: ${widget.lobbyId}',
          tag: logTag,
        );
      }
    } catch (e, stackTrace) {
      logger.error(
        '_loadLobbyWithDebug: Erreur lors du chargement du lobby: $e',
        tag: logTag,
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Timer pour surveiller l'état du chargement et détecter les problèmes
  Timer? _debugTimer;

  void _startDebugTimer() {
    _debugTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Vérifier l'état du contrôleur et du chargement
      final isLoading = _lobbyController.isLoading;
      final hasLobby = _lobbyController.currentLobby != null;
      final hasError = _lobbyController.hasError;

      logger.debug(
        'DebugTimer: isLoading=$isLoading, hasLobby=$hasLobby, hasError=$hasError, hasCompletedLoading=$_hasCompletedLoading',
        tag: logTag,
      );

      // Si on est toujours en chargement après 5 secondes malgré un completed loading, c'est probablement un bug
      if (_hasCompletedLoading && isLoading && timer.tick > 5) {
        logger.warning(
          'DebugTimer: Détection d\'un état de chargement infini potentiel!',
          tag: logTag,
        );

        // Forcer une mise à jour de l'UI pour voir si ça aide
        if (mounted) {
          setState(() {});
        }
      }

      // Arrêter le timer après 15 secondes pour ne pas gaspiller des ressources
      if (timer.tick > 15) {
        logger.debug('DebugTimer: Arrêt du timer de débogage', tag: logTag);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _debugTimer?.cancel();
    // Se désabonner du stream du lobby en utilisant la référence existante
    try {
      _lobbyController.leaveLobbyStream();
    } catch (e) {
      logger.error('Erreur lors du désabonnement du stream: $e', tag: logTag);
    }

    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinLobbyStream() async {
    try {
      logger.debug(
        'Loading existing lobby with ID: ${widget.lobbyId}',
        tag: logTag,
      );

      // Use loadExistingLobby instead of just joinLobbyStream for more reliable loading
      final success = await _lobbyController.loadExistingLobby(widget.lobbyId);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le lobby est introuvable ou a expiré')),
        );
      }
    } catch (e) {
      logger.error('Error loading lobby: $e', tag: logTag);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement du lobby: $e')),
        );
      }
    }
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

      final sessionId = await lobbyController.startGame(widget.lobbyId);

      if (mounted) {
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
    // État local pour suivre le chargement
    setState(() => _isStartingGame = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentFirebaseUser?.uid;

      // Obtenir le joueur actuel avant de faire la requête
      final LobbyModel? lobby = _lobbyController.currentLobby;
      if (lobby == null || currentUserId == null) {
        logger.error(
          'Tentative de changer le statut sans lobby ou utilisateur',
          tag: logTag,
        );
        return;
      }

      final currentPlayer = lobby.players.firstWhere(
        (p) => p.userId == currentUserId,
        orElse: () => throw Exception('Joueur non trouvé dans le lobby'),
      );

      // Inverser l'état pour l'affichage immédiat (optimistic UI update)
      final bool newReadyStatus = !currentPlayer.isReady;

      logger.debug(
        'Changement du statut du joueur ${currentPlayer.displayName} à ${newReadyStatus ? "prêt" : "pas prêt"}',
        tag: logTag,
      );

      // Appeler l'API pour changer le statut
      final success = await _lobbyController.togglePlayerStatus(widget.lobbyId);

      if (!success && mounted) {
        // En cas d'échec, afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du changement de statut'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (success && mounted) {
        // En cas de succès, afficher un feedback à l'utilisateur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newReadyStatus ? 'Vous êtes prêt !' : 'Vous n\'êtes plus prêt',
            ),
            backgroundColor:
                newReadyStatus
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors du changement de statut: $e',
        tag: logTag,
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Réinitialiser l'état de chargement
      if (mounted) {
        setState(() => _isStartingGame = false);
      }
    }
  }

  Future<void> _kickPlayer(String playerId) async {
    try {
      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );
      final success = await lobbyController.kickPlayer(
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

  // Méthode pour charger le lobby de manière fiable
  Future<void> _loadLobby() async {
    logger.debug('Début de _loadLobby pour ID: ${widget.lobbyId}', tag: logTag);

    try {
      // DIAGNOSTIC: Vérifier directement si le lobby existe dans Firestore
      final diagnosticResult = await _lobbyController.debugVerifyLobbyExists(
        widget.lobbyId,
      );
      logger.debug('DIAGNOSTIC RESULT: $diagnosticResult', tag: logTag);

      if (diagnosticResult['exists'] == true) {
        logger.debug(
          'DIAGNOSTIC: Lobby trouvé dans la collection "${diagnosticResult['collection']}"',
          tag: logTag,
        );
      } else {
        logger.warning(
          'DIAGNOSTIC: Le lobby ${widget.lobbyId} n\'existe pas dans Firestore!',
          tag: logTag,
        );
      }

      // Utiliser directement loadExistingLobby pour charger le lobby
      final success = await _lobbyController.loadExistingLobby(widget.lobbyId);

      // IMPORTANT: Forcer l'arrêt du chargement après 500ms, même si le contrôleur est toujours en chargement
      // Cela permettra d'éviter le chargement en boucle
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _lobbyController.isLoading) {
          logger.debug(
            'Forçage de l\'arrêt de l\'état de chargement',
            tag: logTag,
          );
          _lobbyController.forceLoadingReset();
        }
      });

      if (!success && mounted) {
        logger.warning(
          'Échec du chargement du lobby: ${widget.lobbyId}',
          tag: logTag,
        );

        // Montrer un message d'erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossible de charger ce lobby. Il n\'existe peut-être plus.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        logger.debug(
          'Lobby chargé avec succès: ${widget.lobbyId}',
          tag: logTag,
        );
      }
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors du chargement du lobby: $e',
        tag: logTag,
        stackTrace: stackTrace,
      );

      // S'assurer que l'état de chargement est désactivé en cas d'erreur
      _lobbyController.forceLoadingReset();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode pour afficher l'état complet du contrôleur et des états locaux
  void _logCompleteDebugState() {
    final controllerLobby = _lobbyController.currentLobby;
    logger.error('========== DEBUG DÉTAILLÉ ==========', tag: 'CRITICAL_DEBUG');
    logger.error('Lobby ID: ${widget.lobbyId}', tag: 'CRITICAL_DEBUG');
    logger.error(
      'Controller State: isLoading=${_lobbyController.isLoading}, hasError=${_lobbyController.hasError}, errorMessage=${_lobbyController.errorMessage}',
      tag: 'CRITICAL_DEBUG',
    );
    logger.error(
      'Controller Lobby: ${controllerLobby != null ? "PRÉSENT (name: ${controllerLobby.name})" : "NULL"}',
      tag: 'CRITICAL_DEBUG',
    );
    logger.error(
      'Local State: hasCompletedLoading=$_hasCompletedLoading, isDebugging=$_isDebugging',
      tag: 'CRITICAL_DEBUG',
    );
    logger.error('====================================', tag: 'CRITICAL_DEBUG');

    // Essayer de corriger l'état du contrôleur si le lobby est présent mais isLoading est toujours true
    if (controllerLobby != null && _lobbyController.isLoading) {
      logger.error(
        'TENTATIVE DE CORRECTION: Réinitialisation forcée de l\'état de chargement',
        tag: 'CRITICAL_DEBUG',
      );
      _lobbyController.forceLoadingReset();
      // Forcer une mise à jour de l'UI
      if (mounted) {
        Future.microtask(() => setState(() {}));
      }
    }
  }

  // Méthode pour rafraîchir le lobby courant sans quitter la vue
  Future<void> _refreshLobby() async {
    logger.debug(
      '_refreshLobby: Rafraîchissement du lobby ${widget.lobbyId}',
      tag: logTag,
    );

    // Indiquer visuellement que le rafraîchissement est en cours
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Forcer un rechargement du lobby en utilisant loadExistingLobby
      final success = await _lobbyController.loadExistingLobby(
        widget.lobbyId,
        refresh: true,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de rafraîchir le lobby'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Afficher un message de succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lobby rafraîchi'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      logger.error(
        '_refreshLobby: Erreur lors du rafraîchissement du lobby: $e',
        tag: logTag,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // S'assurer de réinitialiser l'état de rafraîchissement
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Méthode pour naviguer vers l'écran d'édition du lobby
  void _navigateToEditLobby() {
    if (_lobbyController.currentLobby != null) {
      // Ouvrir une nouvelle page avec la vue de création de lobby en mode édition
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder:
            (context) => Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: CreateLobbyView(
                lobbyToEdit: _lobbyController.currentLobby,
              ),
            ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le lobby n\'est pas chargé')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentFirebaseUser;
    final theme = Theme.of(context);

    if (currentUser == null) {
      return const Center(child: Text('Utilisateur non connecté'));
    }

    if (_isAnimating) {
      return _buildStartGameAnimation(theme);
    }

    // Log complete debug state for investigation
    _logCompleteDebugState();

    // Force loading reset if controller is still loading
    if (_lobbyController.isLoading) {
      Future.microtask(() => _lobbyController.forceLoadingReset());
    }

    // Use direct property for lobby from controller
    final directLobby = _lobbyController.currentLobby;

    if (directLobby != null) {
      // SOLUTION: Si le lobby est chargé, l'afficher immédiatement sans conditions
      final isHost = directLobby.hostId == currentUser.uid;
      final currentPlayer = directLobby.players.firstWhere(
        (p) => p.userId == currentUser.uid,
        orElse:
            () => LobbyPlayerModel(
              userId: currentUser.uid,
              displayName: currentUser.displayName!,
              avatar: currentUser.photoURL ?? '',
              isHost: false,
              isReady: false,
              joinedAt: DateTime.now(),
            ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations du lobby (en haut)
          _buildLobbyHeader(context, directLobby),

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
                        'Joueurs (${directLobby.players.length}/${directLobby.maxPlayers})',
                    action: Text(
                      '${directLobby.minPlayers} minimum pour démarrer',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Affichage des joueurs en grille
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: directLobby.players.length,
                    itemBuilder: (context, index) {
                      final player = directLobby.players[index];
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
        ],
      );
    }

    // SOLUTION: Si le lobby n'est pas encore chargé, charger directement
    // le lobby à partir de Firebase puis afficher un indicateur pendant le chargement
    if (!_hasCompletedLoading) {
      // Lancer un chargement immédiat
      _loadLobbyWithDebug();

      // Forcer une mise à jour après un délai court
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _lobbyController.forceLoadingReset();
          setState(() {
            _hasCompletedLoading = true;
          });
        }
      });
    }

    // Charger à nouveau si nécessaire après quelques secondes pour corriger tout problème
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted &&
          _lobbyController.currentLobby == null &&
          !_lobbyController.hasError) {
        logger.debug(
          'Relance du chargement après délai',
          tag: 'DEBUG_AUTO_RELOAD',
        );
        _loadLobbyWithDebug();
      }
    });

    // Afficher un indicateur de chargement avec un bouton pour forcer le chargement
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text(
            'Chargement du lobby...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Text(
            'Lobby ID: ${widget.lobbyId}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
              // Force un nouveau chargement
              _lobbyController.forceLoadingReset();
              _loadLobbyWithDebug();

              // Force une mise à jour de l'UI
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Forcer le chargement'),
            // Pas besoin de style personnalisé, le bouton utilisera le thème par défaut
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/home/lobbies'),
            child: const Text('Retour à la liste des lobbies'),
          ),
        ],
      ),
    );
  }

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
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentFirebaseUser;

    // Vérifier si l'utilisateur est l'hôte ou non
    final isHost = lobby.hostId == currentUser?.uid;

    // Récupérer le joueur actuel dans le lobby
    final currentPlayer = lobby.players.firstWhere(
      (p) => p.userId == currentUser?.uid,
      orElse:
          () => LobbyPlayerModel(
            userId: currentUser?.uid ?? '',
            displayName: currentUser?.displayName ?? 'Utilisateur',
            avatar: currentUser?.photoURL ?? '',
            isHost: false,
            isReady: false,
            joinedAt: DateTime.now(),
          ),
    );

    // Vérifier si le lobby peut démarrer
    final canStart = lobby.canStart && isHost;

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
          // Informations principales du lobby
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

              // Bouton de chat
              IconButton(
                icon: const Icon(Icons.chat),
                tooltip: 'Ouvrir le chat du lobby',
                onPressed: () => _navigateToChat(lobby.id),
              ),

              // Bouton d'édition du lobby (pour l'hôte uniquement)
              if (isHost)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _navigateToEditLobby,
                  tooltip: 'Modifier les paramètres du lobby',
                ),

              // Bouton de rafraîchissement
              IconButton(
                icon:
                    _isRefreshing
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.refresh),
                onPressed: _isRefreshing ? null : _refreshLobby,
                tooltip: 'Rafraîchir le lobby',
              ),
            ],
          ),

          // Code d'accès privé (si applicable) - Version améliorée
          if (lobby.visibility == LobbyVisibility.private &&
              lobby.accessCode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 4.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      Icon(
                        Icons.key,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Code d\'accès privé',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onPrimaryContainer
                                    .withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            SelectableText(
                              lobby.accessCode,
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copier le code',
                        onPressed: () => _copyLobbyCode(lobby.accessCode),
                        color: theme.colorScheme.primary,
                        iconSize: 20,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        tooltip: 'Partager le code',
                        onPressed: () => _shareLobbyCode(lobby),
                        color: theme.colorScheme.primary,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ),
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
              const Spacer(),
              Text(
                '${lobby.players.length}/${lobby.maxPlayers} joueurs',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),

          // Boutons d'action déplacés de bas en haut
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouton principal (Démarrer la partie ou Je suis prêt)
              Expanded(
                child:
                    isHost
                        ? ElevatedButton.icon(
                          onPressed:
                              canStart && !_isStartingGame ? _startGame : null,
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
                        )
                        : ElevatedButton.icon(
                          onPressed: _toggleReadyStatus,
                          icon: Icon(
                            currentPlayer.isReady
                                ? Icons.check_circle
                                : Icons.not_interested,
                          ),
                          label: Text(
                            currentPlayer.isReady
                                ? 'Je ne suis plus prêt'
                                : 'Je suis prêt',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                currentPlayer.isReady
                                    ? theme.colorScheme.secondaryContainer
                                    : null,
                            foregroundColor:
                                currentPlayer.isReady
                                    ? theme.colorScheme.onSecondaryContainer
                                    : null,
                          ),
                        ),
              ),
              const SizedBox(width: 8),

              // Bouton pour quitter le lobby (plus petit en icône)
              IconButton(
                onPressed: _isLeavingLobby ? null : _leaveLobby,
                icon:
                    _isLeavingLobby
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.exit_to_app),
                tooltip: 'Quitter le lobby',
              ),

              // Bouton pour supprimer le lobby (uniquement pour l'hôte)
              if (isHost)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    onPressed: _isLeavingLobby ? null : _deleteLobby,
                    icon:
                        _isLeavingLobby
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.delete_forever),
                    tooltip: 'Supprimer le lobby',
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
            ],
          ),

          // Message informatif pour l'hôte
          if (isHost &&
              !canStart &&
              lobby.players.length >= lobby.minPlayers) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'En attente que tous les joueurs soient prêts',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isHost && lobby.players.length < lobby.minPlayers) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'En attente de plus de joueurs (${lobby.players.length}/${lobby.minPlayers} minimum)',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    // Amélioration de la gestion de la couleur de fond pour l'avatar

    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isCurrentUser
                  ? theme.colorScheme.primary.withAlpha((255 * 0.5).toInt())
                  : player.color!.withAlpha((255 * 0.5).toInt()),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color:
              isCurrentUser
                  ? theme.colorScheme.primaryContainer.withAlpha(
                    (255 * 0.2).toInt(),
                  )
                  : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),

            // Conteneur pour le badge d'hôte avec hauteur fixe pour maintenir l'alignement
            SizedBox(
              height: 24, // Hauteur fixe pour le conteneur du badge
              child:
                  player.isHost
                      ? Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: player.color!.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: player.color!, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 14, color: player.color!),
                            const SizedBox(width: 4),
                            Text(
                              'HÔTE',
                              style: TextStyle(
                                color: player.color!,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                      : const SizedBox(), // Espace vide pour les joueurs non-hôtes
            ),

            // Avatar du joueur avec contrainte de taille
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: AvatarDisplay(
                    avatar: player.avatar,
                    color: player.color,
                    size: 80,
                  ),
                ),

                // Indicateur de statut (prêt/non prêt)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: player.isReady ? Colors.green : Colors.grey,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    player.isReady ? Icons.check : Icons.access_time,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Nom du joueur
            Text(
              player.displayName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: player.isHost ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Temps écoulé depuis que le joueur a rejoint
            Text(
              'Rejoint ${_getTimeAgo(player.joinedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Actions (expulser et transfert de propriété)
            SizedBox(
              height: (canKick || (isHost && !player.isHost)) ? 36 : 0,
              child:
                  (canKick || (isHost && !player.isHost))
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (canKick)
                            IconButton(
                              onPressed: () => _kickPlayer(player.userId),
                              icon: const Icon(Icons.person_remove, size: 18),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Expulser',
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.errorContainer,
                                foregroundColor:
                                    theme.colorScheme.onErrorContainer,
                                padding: const EdgeInsets.all(4),
                              ),
                            ),

                          if (canKick && isHost && !player.isHost)
                            const SizedBox(width: 8),

                          if (isHost && !player.isHost)
                            IconButton(
                              onPressed:
                                  () => _transferOwnership(
                                    player.userId,
                                    player.displayName,
                                  ),
                              icon: const Icon(
                                Icons.admin_panel_settings,
                                size: 18,
                              ),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Transférer la propriété',
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                foregroundColor:
                                    theme.colorScheme.onPrimaryContainer,
                                padding: const EdgeInsets.all(4),
                              ),
                            ),
                        ],
                      )
                      : const SizedBox(), // Espace vide si aucune action n'est disponible
            ),
          ],
        ),
      ),
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

  void _showEditLobbyDialog(BuildContext context, LobbyModel lobby) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le lobby'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom du lobby'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items:
                      <String>[
                        'Général',
                        'Science',
                        'Histoire',
                        'Géographie',
                        'Sport',
                        'Musique',
                        'Cinéma',
                        'Littérature',
                        'Art',
                        'Technologie',
                        'Cuisine',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _minPlayers.toString(),
                  decoration: const InputDecoration(labelText: 'Min joueurs'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _minPlayers = int.parse(value);
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _isEditingLobby = false;
                });
                await _updateLobby(lobby);
                Navigator.of(context).pop();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateLobby(LobbyModel lobby) async {
    try {
      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );

      final updatedLobby = lobby.copyWith(
        name: _nameController.text,
        category: _selectedCategory,
        visibility: _selectedVisibility,
        maxPlayers: _maxPlayers,
        minPlayers: _minPlayers,
      );

      await lobbyController.updateLobby(updatedLobby, lobbyId: lobby.id);
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la mise à jour du lobby : $e',
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour du lobby'),
          ),
        );
      }
    }
  }

  // Méthode pour naviguer vers le chat du lobby
  void _navigateToChat(String lobbyId) {
    // Utiliser une bottom sheet pour afficher le chat
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // En-tête du chat
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat),
                      const SizedBox(width: 12),
                      Text(
                        'Chat du lobby',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Fermer',
                      ),
                    ],
                  ),
                ),

                // Contenu du chat
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: ChatView(lobbyId: lobbyId),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _shareLobbyCode(LobbyModel lobby) {
    // Créer un message de partage
    final message =
        'Rejoins mon lobby Quizzzed !\n'
        'Nom du lobby: ${lobby.name}\n'
        'Catégorie: ${lobby.category}\n'
        'Code d\'accès: ${lobby.accessCode}';

    // Afficher une boîte de dialogue avec le message à partager
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Partager le code du lobby'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Voici le message à partager:'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: SelectableText(message),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Conseil: Copiez ce message et partagez-le via votre application préférée.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copier'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copié dans le presse-papier'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }
}
