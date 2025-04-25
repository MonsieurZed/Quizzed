/// Lobby Activity Controller
///
/// Contrôleur pour la gestion des activités dans un lobby comme
/// le chat, les états de préparation et les événements temporels
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/controllers/interfaces/i_lobby_activity_controller.dart';
import 'package:quizzzed/controllers/lobby/lobby_base_controller.dart';
import 'package:quizzzed/models/chat/chat_message_model.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/chat_service.dart';
import 'package:quizzzed/services/error_message_service.dart';
import 'package:quizzzed/services/firebase_service.dart';

/// Contrôleur pour les activités dans le lobby
class LobbyActivityController extends LobbyBaseController
    implements ILobbyActivityController {
  final ChatService _chatService;
  final ErrorMessageService _errorMessageService = ErrorMessageService();

  // État actuel
  List<ChatMessageModel> _chatMessages = [];
  LobbyModel? _currentLobby;

  // Gestion des streams
  StreamSubscription? _lobbyStreamSubscription;
  StreamSubscription? _chatStreamSubscription;

  // Compteur pour la vérification d'activité
  Timer? _activityCheckTimer;
  static const activityCheckPeriod = Duration(seconds: 15);

  // Durée après laquelle un utilisateur est considéré comme inactif
  static const inactivityThreshold = Duration(minutes: 2);

  // Getters
  List<ChatMessageModel> get chatMessages => _chatMessages;

  @override
  LobbyModel? get currentLobby => _currentLobby;

  // Constructeur avec injection de dépendances
  LobbyActivityController({
    required FirebaseService firebaseService,
    required AuthService authService,
    required ChatService chatService,
  }) : _chatService = chatService,
       super(
         firebaseService: firebaseService,
         authService: authService,
         logTag: 'LobbyActivityController',
       );

  @override
  void dispose() {
    // Nettoyage des ressources
    _lobbyStreamSubscription?.cancel();
    _chatStreamSubscription?.cancel();
    _activityCheckTimer?.cancel();
    super.dispose();
  }

  /// Définir le lobby actuel
  @override
  void setCurrentLobby(LobbyModel? lobby) {
    if (_currentLobby?.id != lobby?.id) {
      _currentLobby = lobby;
      notifyListeners();
    }
  }

  /// Charger un lobby par son ID et activer tous les streams
  Future<void> loadLobbyActivity(String lobbyId) async {
    setLoading(true);
    try {
      logger.debug('Chargement des activités du lobby: $lobbyId', tag: logTag);

      // Charger les données du lobby
      final lobbyDoc = await lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        final errorMsg = _errorMessageService.handleError(
          operation: 'Chargement des activités du lobby',
          tag: logTag,
          errorCode: ErrorCode.lobbyNotFound,
          customMessage: 'Le lobby demandé n\'existe pas ou a été supprimé.',
        );
        throw Exception(errorMsg);
      }

      // Initialiser le lobby actuel
      _currentLobby = LobbyModel.fromMap(
        lobbyDoc.data() as Map<String, dynamic>,
        lobbyDoc.id,
      );
      notifyListeners();

      // Initialiser le stream du chat
      await _initializeChatStream(lobbyId);

      // Initialiser le stream du lobby
      _initializeLobbyStream(lobbyId);

      // Démarrer la vérification d'activité périodique
      _startActivityCheck(lobbyId);

      setLoading(false);
    } catch (e) {
      final errorCode = _errorMessageService.getErrorCodeFromException(e);
      final errorMsg = _errorMessageService.handleError(
        operation: 'Chargement des activités du lobby',
        tag: logTag,
        error: e,
        errorCode: errorCode,
        stackTrace: e is Error ? e.stackTrace : null,
      );
      handleError(errorMsg, e, errorCode);
    }
  }

  /// Initialiser le stream du chat
  Future<void> _initializeChatStream(String lobbyId) async {
    _chatStreamSubscription?.cancel();

    try {
      // Charger les messages initiaux
      _chatMessages = await _chatService.getLobbyMessages(lobbyId);
      notifyListeners();

      // S'abonner aux mises à jour
      _chatStreamSubscription = _chatService
          .getLobbyMessagesStream(lobbyId)
          .listen(
            (messages) {
              _chatMessages = messages;
              notifyListeners();
            },
            onError: (e) {
              _errorMessageService.handleError(
                operation: 'Écoute du stream de chat',
                tag: logTag,
                error: e,
                errorCode: ErrorCode.firebaseError,
              );
            },
          );

      logger.debug(
        'Stream de chat initialisé pour le lobby: $lobbyId',
        tag: logTag,
      );
    } catch (e) {
      _errorMessageService.handleError(
        operation: 'Initialisation du stream de chat',
        tag: logTag,
        error: e,
        errorCode: ErrorCode.firebaseError,
      );
    }
  }

  /// Initialiser le stream du lobby
  void _initializeLobbyStream(String lobbyId) {
    _lobbyStreamSubscription?.cancel();

    _lobbyStreamSubscription = lobbiesRef
        .doc(lobbyId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final lobbyData = snapshot.data() as Map<String, dynamic>;
              setCurrentLobby(LobbyModel.fromMap(lobbyData, snapshot.id));
              logger.debug('Lobby mis à jour depuis le stream', tag: logTag);
            } else {
              setCurrentLobby(null);
              _errorMessageService.handleError(
                operation: 'Vérification du lobby',
                tag: logTag,
                errorCode: ErrorCode.lobbyNotFound,
                customMessage: 'Le lobby $lobbyId n\'existe plus',
                logLevel: LogLevel.warning,
              );
            }
          },
          onError: (e) {
            _errorMessageService.handleError(
              operation: 'Écoute du stream de lobby',
              tag: logTag,
              error: e,
              errorCode: ErrorCode.firebaseError,
            );
          },
        );

    logger.debug(
      'Stream de lobby initialisé pour le lobby: $lobbyId',
      tag: logTag,
    );
  }

  /// Démarrer la vérification périodique d'activité
  void _startActivityCheck(String lobbyId) {
    _activityCheckTimer?.cancel();

    final user = authService.currentFirebaseUser;
    if (user == null) return;

    _activityCheckTimer = Timer.periodic(activityCheckPeriod, (_) async {
      try {
        // Mettre à jour notre propre activité
        await updatePlayerActivity(lobbyId);

        // Vérifier l'activité des autres joueurs si on est l'hôte
        if (_currentLobby?.hostId == user.uid) {
          await checkInactivePlayers(lobbyId);
        }
      } catch (e) {
        _errorMessageService.handleError(
          operation: 'Vérification périodique d\'activité',
          tag: logTag,
          error: e,
          errorCode: ErrorCode.operationFailed,
          logLevel: LogLevel.warning,
        );
      }
    });

    logger.debug(
      'Vérification d\'activité démarrée pour le lobby: $lobbyId',
      tag: logTag,
    );
  }

  /// Nettoyer le lobby actuel et arrêter les streams
  void cleanupLobbyActivity() {
    logger.debug('Nettoyage des activités du lobby', tag: logTag);

    _lobbyStreamSubscription?.cancel();
    _lobbyStreamSubscription = null;

    _chatStreamSubscription?.cancel();
    _chatStreamSubscription = null;

    _activityCheckTimer?.cancel();
    _activityCheckTimer = null;

    _chatMessages = [];
    _currentLobby = null;

    notifyListeners();
  }

  /// Envoyer un message dans le chat du lobby
  Future<bool> sendChatMessage(String lobbyId, String message) async {
    if (message.trim().isEmpty) return false;

    try {
      if (!await verifyUserAuthenticated()) {
        return false;
      }

      final user = authService.currentFirebaseUser!;

      logger.debug(
        'Envoi d\'un message dans le lobby $lobbyId: ${message.substring(0, message.length > 20 ? 20 : message.length)}...',
        tag: logTag,
      );

      await _chatService.sendMessage(
        lobbyId: lobbyId,
        message: message,
        senderId: user.uid,
        senderName: user.displayName ?? 'Utilisateur',
        senderAvatar: user.photoURL ?? '',
        senderColor:
            user.noSuchMethod('userColor' as Invocation) ??
            AppConfig.defaultUserColor,
        channel: ChatChannel.lobby,
      );
      // Mise à jour de l'activité du joueur
      await updatePlayerActivity(lobbyId);

      return true;
    } catch (e) {
      _errorMessageService.handleError(
        operation: 'Envoi de message',
        tag: logTag,
        error: e,
        errorCode: _errorMessageService.getErrorCodeFromException(e),
        logLevel: LogLevel.warning,
      );
      return false;
    }
  }

  /// Mettre à jour l'activité d'un joueur
  @override
  Future<void> updatePlayerActivity(String lobbyId) async {
    try {
      if (!await verifyUserAuthenticated()) {
        return;
      }

      final user = authService.currentFirebaseUser!;

      logger.debug(
        'Mise à jour de l\'activité de l\'utilisateur ${user.uid} dans le lobby: $lobbyId',
        tag: logTag,
      );

      // Vérifier si le lobby existe
      final lobbyDoc = await lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        _errorMessageService.handleError(
          operation: 'Vérification du lobby pour mise à jour d\'activité',
          tag: logTag,
          errorCode: ErrorCode.lobbyNotFound,
          customMessage: 'Le lobby n\'existe plus: $lobbyId',
          logLevel: LogLevel.warning,
        );
        return;
      }

      final lobbyData = lobbyDoc.data() as Map<String, dynamic>;
      final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

      // Vérifier si l'utilisateur est dans ce lobby
      final playerIndex = lobby.players.indexWhere(
        (player) => player.userId == user.uid,
      );

      if (playerIndex < 0) {
        _errorMessageService.handleError(
          operation: 'Vérification du joueur pour mise à jour d\'activité',
          tag: logTag,
          errorCode: ErrorCode.playerNotInLobby,
          customMessage:
              'L\'utilisateur ${user.uid} n\'est pas dans le lobby: $lobbyId',
          logLevel: LogLevel.warning,
        );
        return;
      }

      // Mettre à jour le champ lastActive du joueur
      final updatedPlayers = [...lobby.players];
      updatedPlayers[playerIndex] = updatedPlayers[playerIndex].copyWith(
        lastActive: DateTime.now(),
      );

      await lobbiesRef.doc(lobbyId).update({
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
      });

      // Mettre à jour également le champ lastActive dans la collection users
      await firebaseService.firestore.collection('users').doc(user.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });

      logger.debug(
        'Activité de l\'utilisateur ${user.uid} mise à jour dans le lobby: $lobbyId',
        tag: logTag,
      );
    } catch (e) {
      // Utiliser LogLevel.warning car cette opération est en arrière-plan
      _errorMessageService.handleError(
        operation: 'Mise à jour de l\'activité du joueur',
        tag: logTag,
        error: e,
        errorCode: _errorMessageService.getErrorCodeFromException(e),
        logLevel: LogLevel.warning,
      );
      // Ne pas afficher d'erreur à l'utilisateur pour cette opération en arrière-plan
    }
  }

  /// Vérifier les joueurs inactifs et les retirer si nécessaire
  @override
  Future<void> checkInactivePlayers(String lobbyId) async {
    try {
      if (_currentLobby == null) return;

      final now = DateTime.now();
      final lobby = _currentLobby!;

      logger.debug(
        'Vérification des joueurs inactifs du lobby: $lobbyId',
        tag: logTag,
      );

      // Identifier les joueurs inactifs
      final inactivePlayers =
          lobby.players.where((player) {
            if (player.lastActive == null) return false;

            final timeSinceLastActive = now.difference(player.lastActive!);
            return timeSinceLastActive > inactivityThreshold;
          }).toList();

      if (inactivePlayers.isEmpty) {
        logger.debug('Aucun joueur inactif détecté', tag: logTag);
        return;
      }

      logger.info(
        'Joueurs inactifs détectés: ${inactivePlayers.length}',
        tag: logTag,
      );

      // Retirer les joueurs inactifs
      final updatedPlayers =
          lobby.players.where((player) {
            if (player.lastActive == null) return true;

            final timeSinceLastActive = now.difference(player.lastActive!);
            return timeSinceLastActive <= inactivityThreshold;
          }).toList();

      // Si tous les joueurs sont inactifs, ne pas continuer
      if (updatedPlayers.isEmpty) {
        _errorMessageService.handleError(
          operation: 'Vérification des joueurs inactifs',
          tag: logTag,
          errorCode: ErrorCode.operationFailed,
          customMessage: 'Tous les joueurs sont inactifs, aucune action prise',
          logLevel: LogLevel.warning,
        );
        return;
      }

      // Mettre à jour le lobby
      await lobbiesRef.doc(lobbyId).update({
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour les données des joueurs inactifs
      for (final player in inactivePlayers) {
        await firebaseService.firestore
            .collection('users')
            .doc(player.userId)
            .update({'currentLobbyId': null});

        // Envoyer un message système au chat
        await _chatService.sendLobbySystemMessage(
          lobbyId: lobbyId,
          content: '${player.displayName} a été retiré pour inactivité',
        );
      }

      logger.info(
        'Joueurs inactifs retirés du lobby: ${inactivePlayers.length}',
        tag: logTag,
      );
    } catch (e) {
      _errorMessageService.handleError(
        operation: 'Vérification des joueurs inactifs',
        tag: logTag,
        error: e,
        errorCode: _errorMessageService.getErrorCodeFromException(e),
      );
    }
  }

  /// Démarrer la vérification périodique d'activité
  @override
  void startInactivityTimer(String lobbyId) {
    _activityCheckTimer?.cancel();

    final user = authService.currentFirebaseUser;
    if (user == null) return;

    _activityCheckTimer = Timer.periodic(activityCheckPeriod, (_) async {
      try {
        // Mettre à jour notre propre activité
        await updatePlayerActivity(lobbyId);

        // Vérifier l'activité des autres joueurs si on est l'hôte
        if (_currentLobby?.hostId == user.uid) {
          await checkInactivePlayers(lobbyId);
        }
      } catch (e) {
        logger.error(
          'Erreur lors de la vérification d\'activité: $e',
          tag: logTag,
        );
      }
    });

    logger.debug(
      'Vérification d\'activité démarrée pour le lobby: $lobbyId',
      tag: logTag,
    );
  }

  /// Arrêter le timer de vérification d'activité
  @override
  void stopInactivityTimer() {
    _activityCheckTimer?.cancel();
    _activityCheckTimer = null;
    logger.debug('Timer de vérification d\'activité arrêté', tag: logTag);
  }

  /// Vérifier et supprimer les lobbies inactifs
  @override
  Future<void> checkInactiveLobbies() async {
    try {
      logger.debug('Vérification des lobbies inactifs', tag: logTag);

      // Définir la durée après laquelle un lobby est considéré comme inactif
      final inactiveLobbyThreshold = Duration(hours: 3);
      final now = DateTime.now();

      // Récupérer tous les lobbies non en cours
      final snapshot =
          await lobbiesRef.where('isInProgress', isEqualTo: false).get();

      if (snapshot.docs.isEmpty) {
        logger.debug('Aucun lobby à vérifier', tag: logTag);
        return;
      }

      // Vérifier chaque lobby
      for (final doc in snapshot.docs) {
        final lobbyData = doc.data() as Map<String, dynamic>;
        final lobby = LobbyModel.fromMap(lobbyData, doc.id);

        // Vérifier la dernière mise à jour du lobby
        final updatedAt = lobby.updatedAt;

        final timeSinceUpdate = now.difference(updatedAt);

        // Si le lobby est inactif depuis trop longtemps
        if (timeSinceUpdate > inactiveLobbyThreshold) {
          logger.info('Lobby inactif détecté: ${lobby.id}', tag: logTag);

          // Supprimer le lobby
          await lobbiesRef.doc(lobby.id).delete();

          // Mettre à jour les références des joueurs
          for (final player in lobby.players) {
            try {
              await firebaseService.firestore
                  .collection('users')
                  .doc(player.userId)
                  .update({'currentLobbyId': null});
            } catch (e) {
              _errorMessageService.handleError(
                operation:
                    'Mise à jour du joueur après suppression de lobby inactif',
                tag: logTag,
                error: e,
                errorCode: _errorMessageService.getErrorCodeFromException(e),
                customMessage:
                    'Erreur lors de la mise à jour du joueur ${player.userId}',
                logLevel: LogLevel.warning,
              );
            }
          }

          logger.info('Lobby inactif supprimé: ${lobby.id}', tag: logTag);
        }
      }

      logger.debug('Vérification des lobbies inactifs terminée', tag: logTag);
    } catch (e) {
      _errorMessageService.handleError(
        operation: 'Vérification des lobbies inactifs',
        tag: logTag,
        error: e,
        errorCode: _errorMessageService.getErrorCodeFromException(e),
      );
    }
  }

  Future<bool> endGame(String lobbyId) {
    //TODO: implement endGame
    _errorMessageService.handleError(
      operation: 'Fin de partie',
      tag: logTag,
      errorCode: ErrorCode.notImplemented,
      customMessage: 'La méthode endGame() n\'est pas encore implémentée',
      logLevel: LogLevel.warning,
    );
    throw UnimplementedError('endGame() has not been implemented yet');
  }

  Future<bool> nextQuestion(String lobbyId) {
    //TODO: implement nextQuestion
    _errorMessageService.handleError(
      operation: 'Question suivante',
      tag: logTag,
      errorCode: ErrorCode.notImplemented,
      customMessage: 'La méthode nextQuestion() n\'est pas encore implémentée',
      logLevel: LogLevel.warning,
    );
    throw UnimplementedError('nextQuestion() has not been implemented yet');
  }

  Future<bool> cancelGame(String lobbyId) {
    //TODO: implement cancelGame
    _errorMessageService.handleError(
      operation: 'Annulation de partie',
      tag: logTag,
      errorCode: ErrorCode.notImplemented,
      customMessage: 'La méthode cancelGame() n\'est pas encore implémentée',
      logLevel: LogLevel.warning,
    );
    throw UnimplementedError('cancelGame() has not been implemented yet');
  }

  Future<bool> startGame(String lobbyId) {
    //TODO: implement startGame
    _errorMessageService.handleError(
      operation: 'Démarrage de partie',
      tag: logTag,
      errorCode: ErrorCode.notImplemented,
      customMessage: 'La méthode startGame() n\'est pas encore implémentée',
      logLevel: LogLevel.warning,
    );
    throw UnimplementedError('startGame() has not been implemented yet');
  }

  Future<bool> submitAnswer(
    String lobbyId,
    String questionId,
    String answerId,
  ) {
    //ToDO: implement submitAnswer
    _errorMessageService.handleError(
      operation: 'Soumission de réponse',
      tag: logTag,
      errorCode: ErrorCode.notImplemented,
      customMessage: 'La méthode submitAnswer() n\'est pas encore implémentée',
      logLevel: LogLevel.warning,
    );
    throw UnimplementedError('submitAnswer() has not been implemented yet');
  }
}
