/// Lobby Controller
///
/// Contrôleur principal pour la gestion des lobbies de quiz dans l'application.
/// Ce contrôleur délègue aux contrôleurs spécialisés tout en présentant
/// une interface unifiée pour les vues.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:quizzzed/controllers/interfaces/i_lobby_controller.dart';
import 'package:quizzzed/controllers/lobby/lobby_activity_controller.dart';
import 'package:quizzzed/controllers/lobby/lobby_base_controller.dart';
import 'package:quizzzed/controllers/lobby/lobby_management_controller.dart';
import 'package:quizzzed/controllers/lobby/lobby_player_controller.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';
import 'package:quizzzed/services/chat_service.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/services/error_message_service.dart';

/// Contrôleur principal pour les lobbies qui coordonne les différents aspects
/// de la gestion de lobby (création, joueurs, activité)
class LobbyController extends LobbyBaseController implements ILobbyController {
  // Contrôleurs délégués
  final LobbyManagementController _managementController;
  final LobbyPlayerController _playerController;
  final LobbyActivityController _activityController;

  // Service de messages d'erreur centralisé
  final ErrorMessageService _errorMessageService = ErrorMessageService();

  // Stream subscription pour le lobby actuel
  StreamSubscription<DocumentSnapshot>? _lobbyStreamSubscription;

  // Référence directe au lobby courant pour éviter les problèmes de synchronisation
  LobbyModel? _currentLobby;

  @override
  LobbyModel? get currentLobby => _currentLobby;

  /// Constructeur qui initialise les contrôleurs délégués
  LobbyController({
    required super.firebaseService,
    required super.authService,
    required ChatService chatService,
  }) : _managementController = LobbyManagementController(
         firebaseService: firebaseService,
         authService: authService,
       ),
       _playerController = LobbyPlayerController(
         firebaseService: firebaseService,
         authService: authService,
       ),
       _activityController = LobbyActivityController(
         firebaseService: firebaseService,
         authService: authService,
         chatService: chatService,
       ),
       super(logTag: 'LobbyController') {
    // S'abonner aux changements de lobby dans les contrôleurs délégués
    _subscribeToControllerChanges();
  }

  @override
  void dispose() {
    // Arrêter les écoutes de stream
    _lobbyStreamSubscription?.cancel();

    // Disposer les contrôleurs délégués
    _managementController.dispose();
    _playerController.dispose();
    _activityController.dispose();

    super.dispose();
  }

  /// S'abonne aux changements de lobby dans les contrôleurs délégués
  void _subscribeToControllerChanges() {
    // Écouter les changements de lobby dans les contrôleurs délégués
    _managementController.addListener(_onDelegateControllerChanged);
    _playerController.addListener(_onDelegateControllerChanged);
    _activityController.addListener(_onDelegateControllerChanged);
  }

  /// Réagit aux changements dans les contrôleurs délégués
  void _onDelegateControllerChanged() {
    // Vérifier quel contrôleur a un lobby défini et synchroniser
    if (_managementController.currentLobby != null) {
      setCurrentLobby(_managementController.currentLobby);
    } else if (_playerController.currentLobby != null) {
      setCurrentLobby(_playerController.currentLobby);
    } else if (_activityController.currentLobby != null) {
      setCurrentLobby(_activityController.currentLobby);
    }

    // Synchroniser également l'état de chargement
    if (_managementController.isLoading ||
        _playerController.isLoading ||
        _activityController.isLoading) {
      setLoading(true);
    } else {
      setLoading(false);
    }

    // Propager les erreurs au besoin en utilisant le service centralisé
    if (_managementController.hasError) {
      handleError(
        _managementController.errorMessage,
        _managementController.error,
        _managementController.errorCode,
      );
    } else if (_playerController.hasError) {
      handleError(
        _playerController.errorMessage,
        _playerController.error,
        _playerController.errorCode,
      );
    } else if (_activityController.hasError) {
      handleError(
        _activityController.errorMessage,
        _activityController.error,
        _activityController.errorCode,
      );
    }
  }

  /// Crée un nouveau lobby
  Future<String?> createLobby({
    required String name,
    required String description,
    required int maxPlayers,
    required LobbyVisibility visibility,
    required LobbyJoinPolicy joinPolicy,
    String? quizId,
    String? accessCode,
    Color? userColor,
  }) async {
    clearErrors();

    // Conversion des énumérations entre les deux définitions
    final controllerVisibility =
        visibility == LobbyVisibility.public
            ? LobbyVisibility.public
            : LobbyVisibility.private;

    final controllerJoinPolicy = _convertJoinPolicy(joinPolicy);

    return _managementController.createLobby(
      name: name,
      description: description,
      maxPlayers: maxPlayers,
      visibility: controllerVisibility,
      joinPolicy: controllerJoinPolicy,
      quizId: quizId,
      accessCode: accessCode,
      userColor: userColor,
    );
  }

  /// Met à jour un lobby existant
  Future<bool> updateLobby(
    LobbyModel updatedLobby, {
    required String lobbyId,
    String? name,
    String? description,
    int? maxPlayers,
    LobbyVisibility? visibility,
    LobbyJoinPolicy? joinPolicy,
    String? quizId,
    String? accessCode,
    Color? backgroundColor,
  }) async {
    clearErrors();

    // Conversion des énumérations entre les deux définitions
    final controllerVisibility =
        visibility != null
            ? (visibility == LobbyVisibility.public
                ? LobbyVisibility.public
                : LobbyVisibility.private)
            : null;

    final controllerJoinPolicy =
        joinPolicy != null ? _convertJoinPolicy(joinPolicy) : null;

    return _managementController.updateLobby(
      lobbyId: lobbyId,
      name: name,
      description: description,
      maxPlayers: maxPlayers,
      visibility: controllerVisibility,
      joinPolicy: controllerJoinPolicy,
      quizId: quizId,
      accessCode: accessCode,
      backgroundColor: backgroundColor,
    );
  }

  /// Méthode utilitaire pour convertir l'énumération LobbyJoinPolicy
  LobbyJoinPolicy _convertJoinPolicy(LobbyJoinPolicy policy) {
    switch (policy) {
      case LobbyJoinPolicy.open:
        return LobbyJoinPolicy.open;
      case LobbyJoinPolicy.approval:
        return LobbyJoinPolicy.approval;
      case LobbyJoinPolicy.inviteOnly:
        return LobbyJoinPolicy.inviteOnly;
    }
  }

  /// Supprime un lobby
  Future<bool> deleteLobby(String lobbyId) async {
    clearErrors();
    return _managementController.deleteLobby(lobbyId);
  }

  /// Récupère un lobby par son ID
  Future<LobbyModel?> fetchLobbyById(String lobbyId) async {
    clearErrors();
    return _managementController.fetchLobbyById(lobbyId);
  }

  /// Récupère les lobbies publics
  Future<List<LobbyModel>> fetchPublicLobbies({int limit = 20}) async {
    clearErrors();
    return _managementController.fetchPublicLobbies(limit: limit);
  }

  /// Récupère les lobbies créés par l'utilisateur actuel
  Future<List<LobbyModel>> fetchUserLobbies() async {
    clearErrors();
    return _managementController.fetchUserLobbies();
  }

  /// Rejoindre un lobby existant
  Future<bool> joinLobby(String lobbyId) async {
    clearErrors();
    return _playerController.joinLobby(lobbyId);
  }

  /// Rejoindre un lobby privé avec un code
  Future<bool> joinPrivateLobby(String lobbyId, String code) async {
    clearErrors();
    return _playerController.joinPrivateLobby(lobbyId, code);
  }

  /// Rejoindre un lobby en utilisant uniquement son code
  Future<String?> joinLobbyByCode(String code) async {
    clearErrors();
    return _playerController.joinLobbyByCode(code);
  }

  /// Quitter un lobby
  Future<bool> leaveLobby(String lobbyId) async {
    clearErrors();
    return _playerController.leaveLobby(lobbyId);
  }

  /// Basculer le statut "prêt" d'un joueur
  Future<bool> togglePlayerStatus(String lobbyId) async {
    clearErrors();
    return _playerController.togglePlayerStatus(lobbyId);
  }

  /// Transférer la propriété du lobby à un autre joueur (hôte uniquement)
  Future<bool> transferOwnership(String lobbyId, String newOwnerId) async {
    clearErrors();
    return _playerController.transferOwnership(lobbyId, newOwnerId);
  }

  /// Expulser un joueur du lobby (action de l'hôte)
  Future<bool> kickPlayer(String lobbyId, String playerUserId) async {
    clearErrors();
    return _playerController.kickPlayer(lobbyId, playerUserId);
  }

  /// Démarrer une partie avec le quiz sélectionné
  Future<bool> startGame(String lobbyId) async {
    clearErrors();
    return _activityController.startGame(lobbyId);
  }

  /// Annuler une partie en cours
  Future<bool> cancelGame(String lobbyId) async {
    clearErrors();
    return _activityController.cancelGame(lobbyId);
  }

  /// Passer à la question suivante dans le quiz
  Future<bool> nextQuestion(String lobbyId) async {
    clearErrors();
    return _activityController.nextQuestion(lobbyId);
  }

  /// Mettre fin à la partie actuelle
  Future<bool> endGame(String lobbyId) async {
    clearErrors();
    return _activityController.endGame(lobbyId);
  }

  /// Soumettre une réponse à une question
  Future<bool> submitAnswer(
    String lobbyId,
    String questionId,
    String answerId,
  ) async {
    clearErrors();
    return _activityController.submitAnswer(lobbyId, questionId, answerId);
  }

  /// Rejoindre un stream de lobby pour recevoir les mises à jour en temps réel
  @override
  Future<void> joinLobbyStream(String lobbyId) async {
    setLoading(true);

    try {
      // Annuler tout abonnement existant
      _lobbyStreamSubscription?.cancel();

      logger.debug('Joining lobby stream: $lobbyId', tag: logTag);

      // Vérifier d'abord si le lobby existe
      final docSnapshot = await lobbiesRef.doc(lobbyId).get();

      if (!docSnapshot.exists) {
        logger.warning('Lobby $lobbyId n\'existe pas', tag: logTag);
        // Utiliser la nouvelle méthode handleError avec le service centralisé
        _errorMessageService.handleError(
          operation: 'Vérification de l\'existence du lobby',
          tag: logTag,
          errorCode: ErrorCode.lobbyNotFound,
          customMessage: 'Le lobby n\'existe pas ou a été supprimé',
        );
        handleError(
          'Le lobby n\'existe pas ou a été supprimé',
          null,
          ErrorCode.lobbyNotFound,
        );
        // S'assurer que l'état de chargement est réinitialisé
        setLoading(false);
        return;
      }

      // Créer d'abord le modèle à partir des données
      try {
        final lobbyData = docSnapshot.data() as Map<String, dynamic>;
        final lobby = LobbyModel.fromMap(lobbyData, docSnapshot.id);

        // Définir immédiatement comme lobby courant avant de s'abonner au stream
        setCurrentLobby(lobby);
        logger.debug(
          'Lobby initial chargé avec succès: ${lobby.name}',
          tag: logTag,
        );
      } catch (e) {
        logger.error(
          'Erreur lors du parsing initial des données du lobby',
          tag: logTag,
          data: e,
        );
        handleError(
          'Format des données du lobby invalide',
          e,
          ErrorCode.invalidParameter,
        );
        setLoading(false);
        return;
      }

      // S'abonner aux mises à jour du lobby
      _lobbyStreamSubscription = lobbiesRef
          .doc(lobbyId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                try {
                  final lobbyData = snapshot.data() as Map<String, dynamic>;
                  setCurrentLobby(LobbyModel.fromMap(lobbyData, snapshot.id));
                  logger.debug('Lobby data updated from stream', tag: logTag);

                  // S'assurer que l'état de chargement est réinitialisé après chaque mise à jour
                  setLoading(false);
                } catch (e) {
                  // Utiliser le service centralisé pour gérer l'erreur
                  final errorMessage = _errorMessageService.handleError(
                    operation: 'Traitement des données du lobby',
                    tag: logTag,
                    error: e,
                    errorCode: ErrorCode.firebaseError,
                    stackTrace: e is Error ? e.stackTrace : null,
                  );
                  handleError(errorMessage, e, ErrorCode.firebaseError);
                  setLoading(false);
                }
              } else {
                setCurrentLobby(null);
                logger.warning('Lobby $lobbyId no longer exists', tag: logTag);
                // Informer l'utilisateur que le lobby n'existe plus
                handleError(
                  'Le lobby n\'existe plus ou a été supprimé',
                  null,
                  ErrorCode.lobbyNotFound,
                );
                setLoading(false);
              }
            },
            onError: (e) {
              // Utiliser le service centralisé pour gérer l'erreur de stream
              final errorMessage = _errorMessageService.handleError(
                operation: 'Écoute des mises à jour du lobby',
                tag: logTag,
                error: e,
                errorCode: ErrorCode.firebaseError,
              );
              handleError(errorMessage, e, ErrorCode.firebaseError);
              setLoading(false);
            },
          );

      // S'assurer que l'état de chargement est réinitialisé après l'abonnement
      setLoading(false);
    } catch (e) {
      // Utiliser le service centralisé pour gérer l'erreur
      final errorCode = _errorMessageService.getErrorCodeFromException(e);
      final errorMessage = _errorMessageService.handleError(
        operation: 'Connexion au stream du lobby',
        tag: logTag,
        error: e,
        errorCode: errorCode,
        stackTrace: e is Error ? (e).stackTrace : null,
      );
      handleError(errorMessage, e, errorCode);

      // S'assurer que l'état de chargement est réinitialisé en cas d'erreur
      setLoading(false);
    }
  }

  /// Se désabonner du stream du lobby
  @override
  void leaveLobbyStream() {
    logger.debug('Leaving lobby stream', tag: logTag);
    _lobbyStreamSubscription?.cancel();
    _lobbyStreamSubscription = null;
  }

  /// Afficher un message d'erreur à l'utilisateur via un SnackBar
  /// Utilise le service centralisé de gestion des erreurs
  void showErrorMessage(BuildContext context, String message, ErrorCode? code) {
    _errorMessageService.showErrorSnackBar(context, code, message);
  }

  /// Afficher une boîte de dialogue d'erreur à l'utilisateur
  /// Utilise le service centralisé de gestion des erreurs
  void showErrorDialog(
    BuildContext context,
    String message,
    ErrorCode? code, {
    VoidCallback? onDismiss,
  }) {
    _errorMessageService.showErrorDialog(context, code, message, onDismiss);
  }

  /// Efface les erreurs dans tous les contrôleurs
  void clearErrors() {
    super.clearErrors();
    _managementController.clearErrors();
    _playerController.clearErrors();
    _activityController.clearErrors();
  }

  /// Liste des lobbies publics disponibles
  List<LobbyModel> get publicLobbies => _managementController.publicLobbies;

  /// Charge la liste des lobbies publics disponibles
  Future<void> loadPublicLobbies({bool refresh = false}) async {
    clearErrors();
    return _managementController.loadPublicLobbies(refresh: refresh);
  }

  /// Charge directement un lobby existant sans essayer de le rejoindre
  /// À utiliser pour les lobbies où l'utilisateur est déjà membre
  Future<bool> loadExistingLobby(String lobbyId, {bool refresh = false}) async {
    clearErrors();
    try {
      setLoading(true);
      logger.debug('Début de loadExistingLobby pour ID: $lobbyId', tag: logTag);

      // 1. Vérifier si le contrôleur a déjà ce lobby chargé et qu'on ne force pas le rafraîchissement
      if (!refresh && currentLobby != null && currentLobby!.id == lobbyId) {
        logger.debug('Lobby déjà chargé dans le contrôleur', tag: logTag);
        setLoading(false);
        return true;
      }

      // 2. Tenter de récupérer le document depuis Firestore
      logger.debug('Récupération du document Firestore', tag: logTag);
      // Utiliser Source.server si on force le rafraîchissement
      final docSnapshot = await lobbiesRef
          .doc(lobbyId)
          .get(refresh ? const GetOptions(source: Source.server) : null);

      // 3. Vérifier si le document existe
      if (!docSnapshot.exists) {
        logger.warning(
          'Lobby introuvable dans Firestore: $lobbyId',
          tag: logTag,
        );
        handleError(
          'Ce lobby n\'existe pas ou a été supprimé',
          'Lobby non trouvé',
          ErrorCode.lobbyNotFound,
        );
        setLoading(false);
        return false;
      }

      // 4. Charger les données et créer le modèle
      logger.debug('Document trouvé, création du modèle', tag: logTag);
      try {
        final lobbyData = docSnapshot.data() as Map<String, dynamic>;
        final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

        // 5. Définir comme lobby courant
        setCurrentLobby(lobby);
        logger.debug('Lobby chargé avec succès: ${lobby.name}', tag: logTag);

        // 6. Rejoindre le stream pour les mises à jour en temps réel
        await joinLobbyStream(lobbyId);

        setLoading(false);
        return true;
      } catch (dataError) {
        logger.error(
          'Erreur lors du parsing des données du lobby',
          tag: logTag,
          data: dataError,
        );
        handleError(
          'Format des données du lobby invalide',
          dataError,
          ErrorCode.invalidParameter,
        );
        setLoading(false);
        return false;
      }
    } catch (e) {
      final errorCode = _errorMessageService.getErrorCodeFromException(e);
      final errorMessage = _errorMessageService.handleError(
        operation: 'Chargement du lobby existant',
        tag: logTag,
        error: e,
        errorCode: errorCode,
        stackTrace: e is Error ? e.stackTrace : null,
      );
      handleError(errorMessage, e, errorCode);
      setLoading(false);
      return false;
    }
  }

  /// Méthode de débogage pour vérifier si un lobby existe directement dans Firestore
  Future<Map<String, dynamic>> debugVerifyLobbyExists(String lobbyId) async {
    try {
      logger.debug(
        'DIAGNOSTIC: Vérification directe du lobby $lobbyId',
        tag: 'DEBUG',
      );

      // Vérifier dans la collection principale
      final docSnapshot =
          await firebaseService.firestore
              .collection('lobbies')
              .doc(lobbyId)
              .get();

      if (docSnapshot.exists) {
        logger.debug(
          'DIAGNOSTIC: Lobby trouvé dans la collection "lobbies"',
          tag: 'DEBUG',
        );
        return {
          'exists': true,
          'collection': 'lobbies',
          'data': docSnapshot.data(),
        };
      }

      // Vérifier si le lobby existe peut-être dans une autre collection (pour le déboguer)
      final collectionsToCheck = ['lobbys', 'lobby'];

      for (final collection in collectionsToCheck) {
        try {
          final altSnapshot =
              await firebaseService.firestore
                  .collection(collection)
                  .doc(lobbyId)
                  .get();
          if (altSnapshot.exists) {
            logger.debug(
              'DIAGNOSTIC: Lobby trouvé dans la collection "$collection"',
              tag: 'DEBUG',
            );
            return {
              'exists': true,
              'collection': collection,
              'data': altSnapshot.data(),
            };
          }
        } catch (e) {
          logger.debug(
            'DIAGNOSTIC: Erreur lors de la vérification de $collection: $e',
            tag: 'DEBUG',
          );
        }
      }

      logger.debug(
        'DIAGNOSTIC: Lobby introuvable dans toutes les collections vérifiées',
        tag: 'DEBUG',
      );
      return {'exists': false};
    } catch (e) {
      logger.error(
        'DIAGNOSTIC: Erreur lors de la vérification du lobby: $e',
        tag: 'DEBUG',
      );
      return {'exists': false, 'error': e.toString()};
    }
  }

  /// Définit le lobby courant et s'assure que l'état de chargement est mis à jour
  @override
  void setCurrentLobby(LobbyModel? lobby) {
    logger.debug(
      'setCurrentLobby appelé avec ${lobby?.name ?? 'null'}',
      tag: logTag,
    );

    // Stocker directement dans cette classe
    _currentLobby = lobby;

    // Ensuite propager aux sous-contrôleurs (sans déclencher leur notification)
    if (lobby != null) {
      _managementController.setCurrentLobby(lobby);
      _playerController.setCurrentLobby(lobby);
      _activityController.setCurrentLobby(lobby);
    }

    // Réinitialiser l'état de chargement et notifier
    if (isLoading) {
      // Utiliser le getter public au lieu de _isLoading
      setLoading(false);
    }

    // Utiliser microtask pour éviter les problèmes pendant la construction
    Future.microtask(() => notifyListeners());
    logger.debug(
      'Lobby courant défini et état de chargement réinitialisé',
      tag: logTag,
    );
  }
}
