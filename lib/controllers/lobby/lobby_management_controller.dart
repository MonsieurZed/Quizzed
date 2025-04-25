/// Lobby Management Controller
///
/// Contrôleur responsable de la gestion CRUD des lobbies de quiz
/// Hérite de LobbyBaseController pour les fonctionnalités communes
/// Implémente ILobbyManagementController pour assurer la conformité à l'interface
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizzzed/controllers/interfaces/i_lobby_management_controller.dart';
import 'package:quizzzed/controllers/lobby/lobby_base_controller.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/error_message_service.dart';
import 'package:quizzzed/services/firebase_service.dart';
import 'package:quizzzed/models/lobby/lobby_player_model.dart';

/// Contrôleur pour la gestion des lobbies (création, récupération, mise à jour, suppression)
class LobbyManagementController extends LobbyBaseController
    implements ILobbyManagementController {
  // Service de gestion des messages d'erreur
  final ErrorMessageService _errorMessageService = ErrorMessageService();

  // Données des lobbies
  List<LobbyModel> _publicLobbies = [];
  LobbyModel? _currentLobby;

  // Gestion du stream pour les mises à jour en temps réel
  StreamSubscription? _lobbyStreamSubscription;

  // Constantes pour la pagination
  static const int _lobbiesPerPage = 10;
  DocumentSnapshot? _lastDocumentSnapshot;
  bool _hasMoreLobbies = true;

  // Getters pour les données
  @override
  List<LobbyModel> get publicLobbies => _publicLobbies;

  @override
  LobbyModel? get currentLobby => _currentLobby;

  /// Indique s'il existe d'autres lobbies à charger
  bool get hasMoreLobbies => _hasMoreLobbies;

  // Construction du contrôleur avec injection des dépendances
  LobbyManagementController({
    required FirebaseService firebaseService,
    required AuthService authService,
  }) : super(
         firebaseService: firebaseService,
         authService: authService,
         logTag: 'LobbyManagementController',
       );

  @override
  void dispose() {
    // Nettoyer les ressources lors de la destruction du contrôleur
    _lobbyStreamSubscription?.cancel();
    super.dispose();
  }

  /// Définir le lobby courant
  @override
  void setCurrentLobby(LobbyModel? lobby) {
    if (_currentLobby?.id != lobby?.id) {
      _currentLobby = lobby;
      notifyListeners();
    }
  }

  /// Charger la liste des lobbies publics disponibles
  @override
  Future<void> loadPublicLobbies({bool refresh = false}) async {
    setLoading(true);

    try {
      logger.debug('Loading public lobbies', tag: logTag);

      // Réinitialiser la pagination si c'est un rafraîchissement
      if (refresh) {
        _publicLobbies = [];
        _lastDocumentSnapshot = null;
        _hasMoreLobbies = true;
      }

      // Récupérer l'ID du lobby actuel de l'utilisateur
      final currentLobbyId = authService.currentUserModel?.currentLobbyId;
      LobbyModel? userCurrentLobby;

      // Construire la requête de base
      var query = lobbiesRef
          .where('visibility', isEqualTo: 'public')
          .where('isInProgress', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(_lobbiesPerPage);

      // Ajouter le startAfter si ce n'est pas la première page
      if (_lastDocumentSnapshot != null) {
        query = query.startAfterDocument(_lastDocumentSnapshot!);
      }

      // Exécuter la requête
      final snapshot = await query.get();

      // Mettre à jour le dernier document pour la pagination
      if (snapshot.docs.isNotEmpty) {
        _lastDocumentSnapshot = snapshot.docs.last;
      }

      // Vérifier s'il y a d'autres lobbies à charger
      _hasMoreLobbies = snapshot.docs.length >= _lobbiesPerPage;

      // Convertir les documents en modèles
      final loadedLobbies =
          snapshot.docs
              .map(
                (doc) => LobbyModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .where((lobby) => lobby.players.length < lobby.maxPlayers)
              .toList();

      // Ajouter les lobbies chargés à la liste existante (sauf en cas de rafraîchissement)
      if (refresh) {
        _publicLobbies = loadedLobbies;
      } else {
        _publicLobbies.addAll(loadedLobbies);
      }

      // Si l'utilisateur a un lobby actuel et c'est un rafraîchissement, le récupérer
      if (currentLobbyId != null && refresh) {
        logger.debug('User has a current lobby: $currentLobbyId', tag: logTag);

        // Vérifier si le lobby actuel est déjà dans la liste (lobby public)
        int index = _publicLobbies.indexWhere(
          (lobby) => lobby.id == currentLobbyId,
        );

        if (index >= 0) {
          // Si le lobby est dans la liste, le retirer pour le placer en haut
          userCurrentLobby = _publicLobbies.removeAt(index);
        } else {
          // Si le lobby n'est pas dans la liste (probablement un lobby privé), le récupérer
          try {
            final lobbyDoc = await lobbiesRef.doc(currentLobbyId).get();

            if (lobbyDoc.exists) {
              userCurrentLobby = LobbyModel.fromMap(
                lobbyDoc.data() as Map<String, dynamic>,
                lobbyDoc.id,
              );
            }
          } catch (e) {
            _errorMessageService.handleError(
              operation: 'Récupération du lobby actuel',
              tag: logTag,
              error: e,
              errorCode: ErrorCode.firebaseError,
              logLevel: LogLevel.warning,
            );
            // Si une erreur se produit, on continue sans le lobby actuel
          }
        }

        // Ajouter le lobby actuel en haut de la liste s'il a été trouvé
        if (userCurrentLobby != null) {
          // On vérifie si le lobby est en cours ou plein avant de l'ajouter
          if (!userCurrentLobby.isInProgress &&
              userCurrentLobby.players.length < userCurrentLobby.maxPlayers) {
            _publicLobbies.insert(0, userCurrentLobby);
          }
        }
      }

      logger.debug(
        'Loaded ${loadedLobbies.length} public lobbies (total: ${_publicLobbies.length})',
        tag: logTag,
      );
      setLoading(false);
    } catch (e) {
      final errorCode = _errorMessageService.getErrorCodeFromException(e);
      final errorMsg = _errorMessageService.handleError(
        operation: 'Chargement des lobbies publics',
        tag: logTag,
        error: e,
        errorCode: errorCode,
        stackTrace: e is Error ? e.stackTrace : null,
      );
      handleError(errorMsg, e, errorCode);
    }
  }

  /// Charger davantage de lobbies publics (pagination)
  Future<void> loadMorePublicLobbies() async {
    if (!_hasMoreLobbies || isLoading) return;

    await loadPublicLobbies(refresh: false);
  }

  /// Charger un lobby spécifique par son ID
  @override
  Future<void> loadLobby(String lobbyId) async {
    setLoading(true);

    try {
      logger.debug('Loading lobby with ID: $lobbyId', tag: logTag);

      // Configurer un écouteur pour les mises à jour en temps réel
      lobbiesRef
          .doc(lobbyId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                _currentLobby = LobbyModel.fromMap(
                  snapshot.data() as Map<String, dynamic>,
                  snapshot.id,
                );
                notifyListeners();
                logger.debug(
                  'Lobby updated: ${_currentLobby?.name}',
                  tag: logTag,
                );
              } else {
                _currentLobby = null;
                notifyListeners();
                _errorMessageService.handleError(
                  operation: 'Vérification de l\'existence du lobby',
                  tag: logTag,
                  errorCode: ErrorCode.lobbyNotFound,
                  customMessage: 'Le lobby $lobbyId n\'existe plus',
                  logLevel: LogLevel.warning,
                );
              }
            },
            onError: (e) {
              final errorCode = _errorMessageService.getErrorCodeFromException(
                e,
              );
              final errorMsg = _errorMessageService.handleError(
                operation: 'Écoute des mises à jour du lobby',
                tag: logTag,
                error: e,
                errorCode: errorCode,
              );
              handleError(errorMsg, e, errorCode);
            },
          );

      setLoading(false);
    } catch (e) {
      final errorCode = _errorMessageService.getErrorCodeFromException(e);
      final errorMsg = _errorMessageService.handleError(
        operation: 'Chargement du lobby',
        tag: logTag,
        error: e,
        errorCode: errorCode,
      );
      handleError(errorMsg, e, errorCode);
    }
  }

  /// Créer un nouveau lobby
  @override
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
    setLoading(true);

    try {
      if (!await verifyUserAuthenticated()) {
        return null;
      }

      // Vérifier que le nom du lobby n'est pas vide
      if (name.trim().isEmpty) {
        _errorMessageService.handleError(
          operation: 'Création de lobby',
          tag: logTag,
          errorCode: ErrorCode.lobbyNameRequired,
          customMessage: 'Le nom du lobby ne peut pas être vide',
        );
        handleError(
          'Le nom du lobby ne peut pas être vide',
          null,
          ErrorCode.lobbyNameRequired,
        );
        return null;
      }

      final user = authService.currentFirebaseUser!;

      logger.info(
        'Creating new lobby: $name, visibility: $visibility, '
        'max players: $maxPlayers',
        tag: logTag,
      );

      // Générer un code d'accès pour les lobbies privés si aucun n'est fourni
      String? finalAccessCode = accessCode;
      if (visibility == LobbyVisibility.private && accessCode == null) {
        finalAccessCode = generateAccessCode();
        logger.debug('Generated access code: $finalAccessCode', tag: logTag);
      }

      // Récupérer le modèle d'utilisateur complet
      final userModel = authService.currentUserModel;

      // Utiliser un nom d'utilisateur valide en vérifiant plusieurs sources
      final userName =
          user.displayName?.isNotEmpty == true
              ? user.displayName!
              : userModel?.displayName?.isNotEmpty == true
              ? userModel!.displayName!
              : 'Joueur ${user.uid.substring(0, 4)}';

      // Utiliser la couleur fournie ou celle du modèle utilisateur
      final Color playerColor = userColor ?? userModel?.color ?? Colors.blue;

      // Créer le joueur hôte avec les données complètes
      final hostPlayer = LobbyPlayerModel(
        userId: user.uid,
        displayName: userName,
        avatar: userModel?.avatar ?? user.photoURL ?? '',
        color: playerColor,
        isHost: true,
        isReady: true,
        joinedAt: DateTime.now(),
      );
      ;

      // Créer le lobby dans Firestore
      final docRef = await lobbiesRef.add({
        'name': name,
        'hostId': user.uid,
        'description': description,
        'visibility':
            visibility == LobbyVisibility.private ? 'private' : 'public',
        'accessCode': finalAccessCode ?? '',
        'maxPlayers': maxPlayers,
        'minPlayers': 2, // Valeur par défaut
        'joinPolicy': joinPolicy.toString().split('.').last,
        'quizId': quizId ?? '',
        'isInProgress': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'players': [hostPlayer.toMap()],
      });

      logger.info('Lobby created with ID: ${docRef.id}', tag: logTag);
      setLoading(false);
      return docRef.id;
    } catch (e) {
      final errorCode = _errorMessageService.getErrorCodeFromException(e);
      final errorMsg = _errorMessageService.handleError(
        operation: 'Création d\'un lobby',
        tag: logTag,
        error: e,
        errorCode: errorCode,
        stackTrace: e is Error ? (e).stackTrace : null,
      );
      handleError(errorMsg, e, errorCode);
      return null;
    }
  }

  /// Modifier les paramètres d'un lobby existant (hôte uniquement)
  @override
  Future<bool> updateLobby({
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
    try {
      if (!await verifyUserAuthenticated()) {
        return false;
      }

      // Vérifier si l'utilisateur est l'hôte
      final (isHost, lobby) = await verifyUserIsHost(lobbyId);
      if (!isHost || lobby == null) {
        handleError(
          'Seul l\'hôte peut modifier les paramètres du lobby',
          null,
          ErrorCode.notAuthorized,
        );
        return false;
      }

      // Préparer les mises à jour
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Appliquer les modifications si elles sont spécifiées
      if (name != null && name.trim().isNotEmpty) {
        updates['name'] = name.trim();
      }

      if (description != null && description.trim().isNotEmpty) {
        updates['description'] = description.trim();
      }

      if (visibility != null) {
        updates['visibility'] =
            visibility == LobbyVisibility.private ? 'private' : 'public';

        // Générer un nouveau code si le lobby devient privé et qu'un code n'est pas fourni
        if (visibility == LobbyVisibility.private &&
            lobby.visibility != LobbyVisibility.private &&
            accessCode == null) {
          updates['accessCode'] = generateAccessCode();
        } else if (visibility == LobbyVisibility.public) {
          // Supprimer le code si le lobby devient public et qu'un code n'est pas fourni
          updates['accessCode'] = '';
        }
      }

      // Appliquer le code d'accès s'il est fourni
      if (accessCode != null) {
        updates['accessCode'] = accessCode;
      }

      if (maxPlayers != null) {
        // S'assurer que maxPlayers >= nombre actuel de joueurs
        if (maxPlayers < lobby.players.length) {
          handleError(
            'Le nombre maximum de joueurs ne peut pas être inférieur au nombre actuel de joueurs',
            null,
            ErrorCode.invalidParameter,
          );
          return false;
        }
        updates['maxPlayers'] = maxPlayers;
      }

      if (joinPolicy != null) {
        updates['joinPolicy'] = joinPolicy.toString().split('.').last;
      }

      if (quizId != null) {
        updates['quizId'] = quizId;
      }

      if (backgroundColor != null) {
        updates['backgroundColor'] = backgroundColor.value;
      }

      // Mettre à jour le document
      await lobbiesRef.doc(lobbyId).update(updates);
      logger.info('Lobby settings updated for $lobbyId', tag: logTag);
      return true;
    } catch (e) {
      handleError(
        'Erreur lors de la modification des paramètres du lobby',
        e,
        ErrorCode.firebaseError,
      );
      return false;
    }
  }

  // Cette méthode est conservée pour la rétrocompatibilité
  @Deprecated('Utilisez updateLobby à la place')
  Future<bool> updateLobbySettings(
    String lobbyId, {
    String? category,
    int? maxPlayers,
    int? minPlayers,
    String? name,
    LobbyVisibility? visibility,
  }) async {
    return updateLobby(
      lobbyId: lobbyId,
      name: name,
      description: category,
      maxPlayers: maxPlayers,
      visibility: visibility,
    );
  }

  /// Vérifier si l'utilisateur actuel a déjà un lobby
  @override
  Future<bool> userHasExistingLobby() async {
    try {
      if (!await verifyUserAuthenticated()) {
        return false;
      }

      final user = authService.currentFirebaseUser!;

      logger.debug(
        'Checking if user ${user.uid} already has a lobby',
        tag: logTag,
      );

      // Rechercher les lobbies où l'utilisateur est l'hôte et qui ne sont pas terminés
      final snapshot =
          await lobbiesRef
              .where('hostId', isEqualTo: user.uid)
              .where('isInProgress', isEqualTo: false)
              .limit(1)
              .get();

      final hasLobby = snapshot.docs.isNotEmpty;

      if (hasLobby) {
        logger.info(
          'User ${user.uid} already has an active lobby: ${snapshot.docs.first.id}',
          tag: logTag,
        );
      }

      return hasLobby;
    } catch (e) {
      final errorCode = _errorMessageService.getErrorCodeFromException(e);
      final errorMsg = _errorMessageService.handleError(
        operation: 'Vérification des lobbies existants',
        tag: logTag,
        error: e,
        errorCode: errorCode,
        logLevel:
            LogLevel.warning, // Warning car ce n'est pas une erreur critique
      );
      handleError(errorMsg, e, errorCode);
      return false;
    }
  }

  /// Supprimer un lobby (accessible uniquement pour l'hôte)
  @override
  Future<bool> deleteLobby(String lobbyId) async {
    setLoading(true);

    try {
      if (!await verifyUserAuthenticated()) {
        return false;
      }

      final user = authService.currentFirebaseUser!;

      logger.info(
        'User ${user.uid} attempting to delete lobby: $lobbyId',
        tag: logTag,
      );

      // Vérifier si l'utilisateur est l'hôte
      final lobbyDoc = await lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        setLoading(false);
        return true; // Le lobby n'existe déjà plus
      }

      final lobbyData = lobbyDoc.data() as Map<String, dynamic>;
      final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

      if (lobby.hostId != user.uid) {
        _errorMessageService.handleError(
          operation: 'Suppression de lobby',
          tag: logTag,
          errorCode: ErrorCode.notAuthorized,
          customMessage: 'Seul l\'hôte peut supprimer le lobby',
        );
        handleError(
          'Seul l\'hôte peut supprimer le lobby',
          null,
          ErrorCode.notAuthorized,
        );
        return false;
      }

      // Supprimer le lobby
      await lobbiesRef.doc(lobbyId).delete();
      logger.info('Lobby deleted successfully: $lobbyId', tag: logTag);

      // Réinitialiser le lobby actuel si c'était celui-là
      if (_currentLobby?.id == lobbyId) {
        _currentLobby = null;
        notifyListeners();
      }

      setLoading(false);
      return true;
    } catch (e) {
      final errorCode = _errorMessageService.getErrorCodeFromException(e);
      final errorMsg = _errorMessageService.handleError(
        operation: 'Suppression de lobby',
        tag: logTag,
        error: e,
        errorCode: errorCode,
      );
      handleError(errorMsg, e, errorCode);
      return false;
    }
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
        setLoading(false);
        final errorMsg = _errorMessageService.handleError(
          operation: 'Vérification de l\'existence du lobby',
          tag: logTag,
          errorCode: ErrorCode.lobbyNotFound,
          customMessage: 'Le lobby n\'existe pas ou a été supprimé',
        );
        handleError(errorMsg, null, ErrorCode.lobbyNotFound);
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
                  logger.debug('Lobby updated from stream', tag: logTag);
                } catch (e) {
                  final errorMsg = _errorMessageService.handleError(
                    operation: 'Traitement des données du lobby',
                    tag: logTag,
                    error: e,
                    errorCode: ErrorCode.dataParsingError,
                    stackTrace: e is Error ? (e).stackTrace : null,
                  );
                  handleError(errorMsg, e, ErrorCode.dataParsingError);
                }
              } else {
                setCurrentLobby(null);
                _errorMessageService.handleError(
                  operation: 'Suivi du lobby',
                  tag: logTag,
                  errorCode: ErrorCode.lobbyNotFound,
                  customMessage: 'Le lobby $lobbyId n\'existe plus',
                  logLevel: LogLevel.warning,
                );
              }
            },
            onError: (e) {
              final errorCode = _errorMessageService.getErrorCodeFromException(
                e,
              );
              final errorMsg = _errorMessageService.handleError(
                operation: 'Écoute des mises à jour du lobby',
                tag: logTag,
                error: e,
                errorCode: errorCode,
              );
              handleError(errorMsg, e, errorCode);
            },
          );

      setLoading(false);
    } catch (e) {
      final errorCode = _errorMessageService.getErrorCodeFromException(e);
      final errorMsg = _errorMessageService.handleError(
        operation: 'Connexion au stream du lobby',
        tag: logTag,
        error: e,
        errorCode: errorCode,
        stackTrace: e is Error ? (e).stackTrace : null,
      );
      handleError(errorMsg, e, errorCode);
    }
  }

  /// Se désabonner du stream du lobby
  @override
  void leaveLobbyStream() {
    logger.debug('Leaving lobby stream', tag: logTag);
    _lobbyStreamSubscription?.cancel();
    _lobbyStreamSubscription = null;
  }

  /// Récupère un lobby par son ID
  @override
  Future<LobbyModel?> fetchLobbyById(String lobbyId) async {
    try {
      logger.debug('Fetching lobby with ID: $lobbyId', tag: logTag);

      final docSnapshot = await lobbiesRef.doc(lobbyId).get();
      if (!docSnapshot.exists) {
        _errorMessageService.handleError(
          operation: 'Récupération du lobby par ID',
          tag: logTag,
          errorCode: ErrorCode.lobbyNotFound,
          customMessage: 'Lobby introuvable: $lobbyId',
          logLevel: LogLevel.warning,
        );
        return null;
      }

      final lobbyData = docSnapshot.data() as Map<String, dynamic>;
      return LobbyModel.fromMap(lobbyData, docSnapshot.id);
    } catch (e) {
      final errorCode = _errorMessageService.getErrorCodeFromException(e);
      final errorMsg = _errorMessageService.handleError(
        operation: 'Récupération du lobby',
        tag: logTag,
        error: e,
        errorCode: errorCode,
      );
      handleError(errorMsg, e, errorCode);
      return null;
    }
  }

  /// Récupère les lobbies publics avec une limite optionnelle
  @override
  Future<List<LobbyModel>> fetchPublicLobbies({int limit = 20}) async {
    try {
      logger.debug('Fetching public lobbies, limit: $limit', tag: logTag);

      final snapshot =
          await lobbiesRef
              .where('visibility', isEqualTo: 'public')
              .where('isInProgress', isEqualTo: false)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                LobbyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .where((lobby) => lobby.players.length < lobby.maxPlayers)
          .toList();
    } catch (e) {
      final errorCode = _errorMessageService.getErrorCodeFromException(e);
      final errorMsg = _errorMessageService.handleError(
        operation: 'Récupération des lobbies publics',
        tag: logTag,
        error: e,
        errorCode: errorCode,
      );
      handleError(errorMsg, e, errorCode);
      return [];
    }
  }

  /// Récupère les lobbies créés par l'utilisateur actuel
  @override
  Future<List<LobbyModel>> fetchUserLobbies() async {
    try {
      if (!await verifyUserAuthenticated()) {
        return [];
      }

      final user = authService.currentFirebaseUser!;
      logger.debug('Fetching lobbies for user: ${user.uid}', tag: logTag);

      final snapshot =
          await lobbiesRef
              .where('hostId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                LobbyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      final errorCode = _errorMessageService.getErrorCodeFromException(e);
      final errorMsg = _errorMessageService.handleError(
        operation: 'Récupération des lobbies de l\'utilisateur',
        tag: logTag,
        error: e,
        errorCode: errorCode,
      );
      handleError(errorMsg, e, errorCode);
      return [];
    }
  }
}
