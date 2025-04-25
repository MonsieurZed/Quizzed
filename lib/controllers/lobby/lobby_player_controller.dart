/// Lobby Player Controller
///
/// Contrôleur responsable de la gestion des joueurs dans les lobbies
/// Hérite de LobbyBaseController pour les fonctionnalités communes
/// Implémente ILobbyPlayerController pour assurer la conformité à l'interface
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added import for User class
import 'package:quizzzed/controllers/interfaces/i_lobby_player_controller.dart';
import 'package:quizzzed/controllers/lobby/lobby_base_controller.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';
import 'package:quizzzed/models/lobby/lobby_player_model.dart';
import 'package:quizzzed/models/user/user_model.dart';

/// Contrôleur pour la gestion des joueurs dans les lobbies
class LobbyPlayerController extends LobbyBaseController
    implements ILobbyPlayerController {
  // Lobby actuellement actif
  LobbyModel? _currentLobby;

  // Gestion du stream pour les mises à jour en temps réel
  StreamSubscription? _lobbyStreamSubscription;

  // Getter pour le lobby actuellement actif
  @override
  LobbyModel? get currentLobby => _currentLobby;

  // Construction du contrôleur avec injection des dépendances
  LobbyPlayerController({
    required super.firebaseService,
    required super.authService,
  }) : super(logTag: 'LobbyPlayerController');

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

  /// Charger un lobby spécifique par son ID
  @override
  Future<void> loadLobby(String lobbyId) async {
    setLoading(true);

    try {
      logger.debug('Chargement du lobby: $lobbyId', tag: logTag);

      final docSnapshot = await lobbiesRef.doc(lobbyId).get();
      if (docSnapshot.exists) {
        final lobbyData = docSnapshot.data() as Map<String, dynamic>;
        setCurrentLobby(LobbyModel.fromMap(lobbyData, lobbyId));
      } else {
        handleError('Lobby non trouvé', null);
      }

      setLoading(false);
    } catch (e) {
      handleError('Erreur lors du chargement du lobby', e);
    }
  }

  /// Rejoindre un lobby existant
  @override
  Future<bool> joinLobby(String lobbyId) async {
    setLoading(true);

    try {
      if (!await verifyUserAuthenticated()) {
        return false;
      }

      final user = authService.currentFirebaseUser!;
      logger.info(
        'Joueur ${user.uid} tente de rejoindre le lobby: $lobbyId',
        tag: logTag,
      );

      // Debug logging to help identify issues
      logger.debug(
        'Vérification du lobby (collection: ${lobbiesRef.path})',
        tag: logTag,
        data: {'lobbyId': lobbyId},
      );

      // Récupérer le lobby pour vérifier ses propriétés
      final docSnapshot = await lobbiesRef.doc(lobbyId).get();

      // Check if lobby doc exists
      if (!docSnapshot.exists) {
        logger.error(
          'Erreur de joinLobby: Document introuvable',
          tag: logTag,
          data: {'lobbyId': lobbyId, 'collection': lobbiesRef.path},
        );
        handleError(
          'Le lobby n\'existe pas',
          'Lobby non trouvé',
          ErrorCode.lobbyNotFound,
        );
        setLoading(false);
        return false;
      }

      final lobbyData = docSnapshot.data() as Map<String, dynamic>;
      final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

      logger.debug(
        'Détails du lobby récupérés',
        tag: logTag,
        data: {
          'lobbyId': lobbyId,
          'name': lobby.name,
          'playerCount': lobby.players.length,
          'maxPlayers': lobby.maxPlayers,
          'visibility': lobby.visibility.toString(),
        },
      );

      // Vérifier si le lobby est en cours
      if (lobby.isInProgress) {
        handleError(
          'Ce lobby a déjà démarré une partie',
          'Partie en cours',
          ErrorCode.lobbyInProgress,
        );
        setLoading(false);
        return false;
      }

      // Vérifier si le lobby est plein
      if (lobby.players.length >= lobby.maxPlayers) {
        handleError(
          'Ce lobby est plein',
          'Nombre maximum de joueurs atteint',
          ErrorCode.lobbyFull,
        );
        setLoading(false);
        return false;
      }

      // Vérifier si l'utilisateur est déjà dans le lobby
      if (lobby.players.any((player) => player.userId == user.uid)) {
        logger.info('Le joueur est déjà dans ce lobby', tag: logTag);
        setLoading(false);
        return true;
      }

      // Si le lobby est privé et qu'aucun code d'accès n'est fourni, refuser l'accès
      if (lobby.visibility == LobbyVisibility.private) {
        handleError(
          'Ce lobby est privé, veuillez fournir un code d\'accès',
          'Accès refusé',
          ErrorCode.invalidAccessCode,
        );
        setLoading(false);
        return false;
      }

      // Récupérer les informations complètes du joueur
      final userModel = authService.currentUserModel;
      logger.debug(
        'Infos utilisateur récupérées',
        tag: logTag,
        data: {
          'uid': user.uid,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'hasUserModel': userModel != null,
        },
      );

      // Créer le modèle de joueur à partir des informations de l'utilisateur
      final newPlayer = _createPlayerModelFromUser(user, userModel);

      // Ajouter directement le joueur au lobby avec une méthode plus robuste
      try {
        // Récupérer à nouveau le document pour éviter les conflits d'écriture
        final freshDocSnapshot = await lobbiesRef.doc(lobbyId).get();
        if (!freshDocSnapshot.exists) {
          logger.error(
            'Erreur de joinLobby: Document a disparu pendant l\'opération',
            tag: logTag,
          );
          handleError(
            'Le lobby n\'existe plus',
            'Lobby introuvable',
            ErrorCode.lobbyNotFound,
          );
          setLoading(false);
          return false;
        }

        // Fix: properly handle the document data with explicit typing
        final freshData = freshDocSnapshot.data() as Map<String, dynamic>;
        final freshLobby = LobbyModel.fromMap(freshData, lobbyId);
        final updatedPlayers = [...freshLobby.players, newPlayer];

        // Effectuer la mise à jour avec une logique de transaction
        await lobbiesRef.doc(lobbyId).update({
          'players': updatedPlayers.map((player) => player.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        logger.info(
          'Joueur ajouté avec succès au lobby',
          tag: logTag,
          data: {
            'lobbyId': lobbyId,
            'userId': user.uid,
            'newPlayerCount': updatedPlayers.length,
          },
        );
      } catch (updateError) {
        logger.error(
          'Erreur lors de l\'ajout du joueur au lobby',
          tag: logTag,
          data: {'error': updateError.toString(), 'lobbyId': lobbyId},
        );
        handleError(
          'Erreur lors de l\'ajout du joueur au lobby',
          updateError,
          ErrorCode.operationFailed,
        );
        setLoading(false);
        return false;
      }

      // Mettre à jour le champ currentLobbyId de l'utilisateur
      try {
        await firebaseService.firestore
            .collection('users')
            .doc(user.uid)
            .update({
              'currentLobbyId': lobbyId,
              'lastActive': FieldValue.serverTimestamp(),
            });

        logger.info(
          'CurrentLobbyId mis à jour pour l\'utilisateur',
          tag: logTag,
          data: {'userId': user.uid, 'lobbyId': lobbyId},
        );
      } catch (userUpdateError) {
        logger.error(
          'Erreur lors de la mise à jour du currentLobbyId de l\'utilisateur',
          tag: logTag,
          data: {'error': userUpdateError.toString(), 'userId': user.uid},
        );
        // Continue despite this error as the player was already added to the lobby
      }

      logger.info(
        'Joueur ${user.uid} a rejoint le lobby $lobbyId',
        tag: logTag,
      );

      // Load the lobby data to make sure everything is up to date
      await loadLobby(lobbyId);

      setLoading(false);
      return true;
    } catch (e) {
      logger.error(
        'Exception non gérée dans joinLobby',
        tag: logTag,
        data: {'error': e.toString(), 'lobbyId': lobbyId},
      );
      handleError(
        'Erreur lors de la tentative de rejoindre le lobby',
        e,
        ErrorCode.firebaseError,
      );
      setLoading(false);
      return false;
    }
  }

  /// Créer un modèle de joueur à partir des informations de l'utilisateur
  LobbyPlayerModel _createPlayerModelFromUser(User user, UserModel? userModel) {
    // Utiliser un nom d'utilisateur valide en vérifiant plusieurs sources
    final userName =
        user.displayName?.isNotEmpty == true
            ? user.displayName!
            : userModel?.displayName?.isNotEmpty == true
            ? userModel!.displayName!
            : 'Joueur ${user.uid.substring(0, 4)}';

    // Récupérer la couleur d'arrière-plan de l'avatar s'il y en a une
    final color = userModel?.color;

    return LobbyPlayerModel(
      userId: user.uid,
      displayName: userName,
      avatar: user.photoURL ?? '',
      color: color,
      isHost: false,
      isReady: false,
      joinedAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
  }

  /// Rejoindre un lobby privé avec un code
  @override
  Future<bool> joinPrivateLobby(String lobbyId, String code) async {
    setLoading(true);

    try {
      if (!await verifyUserAuthenticated()) {
        return false;
      }

      final user = authService.currentFirebaseUser!;

      logger.info(
        'Joueur ${user.uid} tente de rejoindre le lobby privé: $lobbyId',
        tag: logTag,
      );

      // Vérifier si le lobby existe, s'il est privé et si le code est correct
      final lobbyDoc = await lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        handleError('Le lobby n\'existe pas', null);
        return false;
      }

      final lobbyData = lobbyDoc.data() as Map<String, dynamic>;
      final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

      // Vérifier si le lobby est en cours
      if (lobby.isInProgress) {
        handleError('Ce lobby a déjà démarré une partie', null);
        return false;
      }

      // Vérifier si le lobby est plein
      if (lobby.players.length >= lobby.maxPlayers) {
        handleError('Ce lobby est plein', null);
        return false;
      }

      // Vérifier si l'utilisateur est déjà dans le lobby
      if (lobby.players.any((player) => player.userId == user.uid)) {
        logger.info('Le joueur est déjà dans ce lobby', tag: logTag);
        setLoading(false);
        return true;
      }

      // Vérifier que le lobby est bien privé
      if (lobby.visibility != LobbyVisibility.private) {
        // Si le lobby est public, on peut le rejoindre sans code
        return joinLobby(lobbyId);
      }

      // Vérifier que le code correspond
      if (lobby.accessCode != code) {
        handleError('Code d\'accès incorrect', null);
        return false;
      }

      // Récupérer les informations complètes du joueur
      final userModel = authService.currentUserModel;

      // Utiliser un nom d'utilisateur valide en vérifiant plusieurs sources
      final userName =
          user.displayName?.isNotEmpty == true
              ? user.displayName!
              : userModel?.displayName?.isNotEmpty == true
              ? userModel!.displayName!
              : 'Joueur ${user.uid.substring(0, 4)}';

      // Récupérer la couleur d'arrière-plan de l'avatar s'il y en a une
      final color = userModel?.color;

      // Créer le joueur avec les données complètes
      final newPlayer = LobbyPlayerModel(
        userId: user.uid,
        displayName: userName,
        avatar: user.photoURL ?? '',
        color: color,
        isHost: false,
        isReady: false,
        joinedAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      // Ajouter le joueur au lobby
      final updatedPlayers = [...lobby.players, newPlayer];

      await lobbiesRef.doc(lobbyId).update({
        'players': updatedPlayers.map((player) => player.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour le champ currentLobbyId de l'utilisateur
      await firebaseService.firestore.collection('users').doc(user.uid).update({
        'currentLobbyId': lobbyId,
        'lastActive': FieldValue.serverTimestamp(),
      });

      logger.info(
        'Joueur ${user.uid} a rejoint le lobby privé $lobbyId',
        tag: logTag,
      );
      setLoading(false);
      return true;
    } catch (e) {
      handleError('Erreur lors de la tentative de rejoindre le lobby privé', e);
      return false;
    }
  }

  /// Rejoindre un lobby en utilisant uniquement son code
  @override
  Future<String?> joinLobbyByCode(String code) async {
    setLoading(true);

    try {
      if (!await verifyUserAuthenticated()) {
        return null;
      }

      logger.info('Recherche de lobby par code: $code', tag: logTag);

      // Rechercher un lobby avec le code d'accès fourni
      final snapshot =
          await lobbiesRef
              .where('accessCode', isEqualTo: code)
              .where('isInProgress', isEqualTo: false)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        handleError('Aucun lobby trouvé avec ce code', null);
        return null;
      }

      final lobbyDoc = snapshot.docs.first;
      final lobbyId = lobbyDoc.id;

      // Tenter de rejoindre le lobby
      final success = await joinPrivateLobby(lobbyId, code);

      if (success) {
        logger.info('Lobby rejoint avec succès via le code', tag: logTag);
        return lobbyId;
      } else {
        // L'erreur aura déjà été définie par joinPrivateLobby
        return null;
      }
    } catch (e) {
      handleError('Erreur lors de la recherche du lobby par code', e);
      return null;
    }
  }

  /// Quitter un lobby
  @override
  Future<bool> leaveLobby(String lobbyId) async {
    setLoading(true);

    try {
      if (!await verifyUserAuthenticated()) {
        return false;
      }

      final user = authService.currentFirebaseUser!;

      logger.info('Joueur ${user.uid} quitte le lobby: $lobbyId', tag: logTag);

      // Utiliser la méthode d'aide pour supprimer le joueur du lobby
      final (success, errorCode) = await lobbyHelper.removePlayerFromLobby(
        lobbyId,
        user.uid,
        isLeaving: true,
        shouldDeleteEmptyLobby: true,
      );

      if (!success) {
        // Si le joueur n'est pas dans le lobby ou si le lobby n'existe pas,
        // on efface quand même l'ID du lobby actuel de l'utilisateur
        if (errorCode == ErrorCode.playerNotInLobby ||
            errorCode == ErrorCode.lobbyNotFound) {
          await _clearUserCurrentLobby(user.uid);
          setLoading(false);
          return true;
        }

        // Pour les autres erreurs, les propager
        handleError(
          'Erreur lors de la tentative de quitter le lobby',
          'Impossible de quitter le lobby',
          errorCode,
        );
        return false;
      }

      // Effacer l'ID du lobby actuel de l'utilisateur
      await _clearUserCurrentLobby(user.uid);

      logger.info('Joueur ${user.uid} a quitté le lobby $lobbyId', tag: logTag);
      setLoading(false);
      return true;
    } catch (e) {
      handleError(
        'Erreur lors de la tentative de quitter le lobby',
        e,
        ErrorCode.firebaseError,
      );
      return false;
    }
  }

  /// Méthode utilitaire pour effacer l'ID du lobby actuel de l'utilisateur
  Future<void> _clearUserCurrentLobby(String userId) async {
    await firebaseService.firestore.collection('users').doc(userId).update({
      'currentLobbyId': null,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  /// Mise à jour de l'activité du joueur courant
  @override
  Future<void> updatePlayerActivity(String lobbyId) async {
    try {
      if (!await verifyUserAuthenticated()) {
        return;
      }

      final user = authService.currentFirebaseUser!;

      // Utiliser la méthode d'aide pour mettre à jour l'activité du joueur
      await lobbyHelper.updatePlayerActivity(lobbyId, user.uid);

      // Même en cas d'échec, ne pas afficher d'erreur à l'utilisateur
      // pour cette opération de routine

      // Mettre également à jour l'activité dans la collection users
      await firebaseService.firestore.collection('users').doc(user.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.error(
        'Erreur lors de la mise à jour de l\'activité du joueur: $e',
        tag: logTag,
      );
      // Ne pas afficher d'erreur à l'utilisateur pour cette opération de routine
    }
  }

  /// Basculer le statut "prêt" d'un joueur
  @override
  Future<bool> togglePlayerStatus(String lobbyId) async {
    try {
      if (!await verifyUserAuthenticated()) {
        return false;
      }

      final user = authService.currentFirebaseUser!;

      // Vérifier si le lobby existe
      final lobbyDoc = await lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        handleError('Le lobby n\'existe pas', null);
        return false;
      }

      final lobbyData = lobbyDoc.data() as Map<String, dynamic>;
      final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

      // Vérifier si l'utilisateur est dans le lobby
      final playerIndex = lobby.players.indexWhere(
        (player) => player.userId == user.uid,
      );

      if (playerIndex == -1) {
        handleError('Vous n\'êtes pas dans ce lobby', null);
        return false;
      }

      // Basculer le statut "prêt" du joueur
      final updatedPlayers = List<LobbyPlayerModel>.from(lobby.players);
      final currentStatus = updatedPlayers[playerIndex].isReady;
      updatedPlayers[playerIndex] = updatedPlayers[playerIndex].copyWith(
        isReady: !currentStatus,
        lastActive: DateTime.now(),
      );

      await lobbiesRef.doc(lobbyId).update({
        'players': updatedPlayers.map((player) => player.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.info(
        'Statut du joueur ${user.uid} dans le lobby $lobbyId mis à jour: ${!currentStatus}',
        tag: logTag,
      );
      return true;
    } catch (e) {
      handleError('Erreur lors de la mise à jour du statut du joueur', e);
      return false;
    }
  }

  /// Transférer la propriété du lobby à un autre joueur (hôte uniquement)
  @override
  Future<bool> transferOwnership(String lobbyId, String newOwnerId) async {
    try {
      if (!await verifyUserAuthenticated()) {
        return false;
      }

      final user = authService.currentFirebaseUser!;

      // Vérifier si le lobby existe
      final lobbyDoc = await lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        handleError('Le lobby n\'existe pas', null);
        return false;
      }

      final lobbyData = lobbyDoc.data() as Map<String, dynamic>;
      final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

      // Vérifier si l'utilisateur est l'hôte
      if (lobby.hostId != user.uid) {
        handleError('Seul l\'hôte peut transférer la propriété du lobby', null);
        return false;
      }

      // Vérifier si le nouveau propriétaire est dans le lobby
      final newOwnerIndex = lobby.players.indexWhere(
        (player) => player.userId == newOwnerId,
      );

      if (newOwnerIndex == -1) {
        handleError('Le nouveau propriétaire n\'est pas dans ce lobby', null);
        return false;
      }

      // Mettre à jour les statuts d'hôte pour tous les joueurs
      final updatedPlayers =
          lobby.players.map((player) {
            if (player.userId == user.uid) {
              return player.copyWith(isHost: false);
            } else if (player.userId == newOwnerId) {
              return player.copyWith(isHost: true);
            } else {
              return player;
            }
          }).toList();

      // Mettre à jour le document du lobby
      await lobbiesRef.doc(lobbyId).update({
        'hostId': newOwnerId,
        'players': updatedPlayers.map((player) => player.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.info(
        'Propriété du lobby $lobbyId transférée de ${user.uid} à $newOwnerId',
        tag: logTag,
      );
      return true;
    } catch (e) {
      handleError('Erreur lors du transfert de propriété du lobby', e);
      return false;
    }
  }

  /// Expulser un joueur du lobby (action de l'hôte)
  @override
  Future<bool> kickPlayer(String lobbyId, String playerUserId) async {
    try {
      if (!await verifyUserAuthenticated()) {
        return false;
      }

      final user = authService.currentFirebaseUser!;

      // Vérifier si l'utilisateur est l'hôte du lobby
      final (isHost, lobby) = await verifyUserIsHost(lobbyId);
      if (!isHost || lobby == null) {
        return false;
      }

      // Vérifier qu'on n'essaie pas d'expulser l'hôte
      if (playerUserId == user.uid) {
        handleError(
          'Vous ne pouvez pas vous expulser vous-même',
          'Auto-expulsion impossible',
          ErrorCode.kickSelfNotAllowed,
        );
        return false;
      }

      // Vérifier si le joueur à expulser est dans le lobby
      final playerToKick = lobby.players.firstWhere(
        (player) => player.userId == playerUserId,
      );

      if (playerToKick.userId.isEmpty) {
        handleError(
          'Le joueur à expulser n\'est pas dans ce lobby',
          'Joueur non trouvé dans le lobby',
          ErrorCode.playerNotFound,
        );
        return false;
      }

      // Utiliser la méthode d'aide pour supprimer le joueur du lobby
      // Pas de transfert de propriété ni de suppression du lobby si vide
      final (success, errorCode) = await lobbyHelper.removePlayerFromLobby(
        lobbyId,
        playerUserId,
        isLeaving: false, // Indique une expulsion et non un départ volontaire
        shouldDeleteEmptyLobby:
            false, // Ne pas supprimer le lobby même s'il devient vide
      );

      if (!success) {
        handleError(
          'Erreur lors de l\'expulsion du joueur',
          'Impossible d\'expulser le joueur',
          errorCode,
        );
        return false;
      }

      // Effacer l'ID du lobby actuel du joueur expulsé
      await _clearUserCurrentLobby(playerUserId);

      logger.info(
        'Joueur $playerUserId expulsé du lobby $lobbyId par ${user.uid}',
        tag: logTag,
      );
      return true;
    } catch (e) {
      handleError(
        'Erreur lors de l\'expulsion du joueur',
        e,
        ErrorCode.firebaseError,
      );
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

      // S'abonner aux mises à jour du lobby
      _lobbyStreamSubscription = lobbiesRef
          .doc(lobbyId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                final lobbyData = snapshot.data() as Map<String, dynamic>;
                setCurrentLobby(LobbyModel.fromMap(lobbyData, snapshot.id));
                logger.debug('Lobby updated from stream', tag: logTag);
              } else {
                setCurrentLobby(null);
                logger.warning('Lobby $lobbyId no longer exists', tag: logTag);
              }
            },
            onError: (e) {
              handleError(
                'Erreur lors de l\'écoute des mises à jour du lobby',
                e,
              );
            },
          );

      setLoading(false);
    } catch (e) {
      handleError('Erreur lors de la connexion au stream du lobby', e);
    }
  }

  /// Se désabonner du stream du lobby
  @override
  void leaveLobbyStream() {
    logger.debug('Leaving lobby stream', tag: logTag);
    _lobbyStreamSubscription?.cancel();
    _lobbyStreamSubscription = null;
  }
}
