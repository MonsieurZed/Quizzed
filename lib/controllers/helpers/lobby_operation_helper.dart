/// Classe utilitaire pour les opérations communes sur les lobbies
///
/// Cette classe fournit des méthodes d'aide pour les opérations fréquemment
/// utilisées dans les différents contrôleurs de lobby.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';
import 'package:quizzzed/models/lobby/lobby_player_model.dart';
import 'package:quizzzed/services/logger_service.dart';

/// Classe d'aide pour les opérations sur les lobbies
/// Peut être utilisée par extension ou par composition
class LobbyOperationHelper {
  final CollectionReference lobbiesRef;
  final LoggerService logger;
  final String logTag;

  /// Constructeur
  LobbyOperationHelper({
    required this.lobbiesRef,
    required this.logger,
    required this.logTag,
  });

  /// Récupérer un lobby par son ID
  ///
  /// Renvoie null et un code d'erreur si le lobby n'existe pas
  Future<(LobbyModel?, ErrorCode?)> fetchLobbyById(String lobbyId) async {
    try {
      logger.debug('Fetching lobby with ID: $lobbyId', tag: logTag);

      final docSnapshot = await lobbiesRef.doc(lobbyId).get();

      if (!docSnapshot.exists) {
        logger.warning('Lobby not found: $lobbyId', tag: logTag);
        return (null, ErrorCode.lobbyNotFound);
      }

      final lobbyData = docSnapshot.data() as Map<String, dynamic>;
      final lobbyModel = LobbyModel.fromMap(lobbyData, docSnapshot.id);

      return (lobbyModel, null);
    } catch (e) {
      logger.error('Error fetching lobby $lobbyId: $e', tag: logTag);
      return (null, ErrorCode.firebaseError);
    }
  }

  /// Vérifie si l'utilisateur est l'hôte du lobby
  ///
  /// Renvoie un tuple avec:
  /// - un booléen indiquant si l'utilisateur est l'hôte
  /// - le modèle de lobby si la récupération a réussi
  /// - un code d'erreur en cas d'échec
  Future<(bool, LobbyModel?, ErrorCode?)> verifyUserIsHost(
    String lobbyId,
    String userId,
  ) async {
    try {
      logger.debug(
        'Verifying if user $userId is host of lobby $lobbyId',
        tag: logTag,
      );

      final (lobby, errorCode) = await fetchLobbyById(lobbyId);

      if (errorCode != null) {
        return (false, null, errorCode);
      }

      if (lobby!.hostId != userId) {
        logger.warning(
          'User $userId is not the host of lobby $lobbyId',
          tag: logTag,
        );
        return (false, lobby, ErrorCode.notAuthorized);
      }

      return (true, lobby, null);
    } catch (e) {
      logger.error(
        'Error verifying host status for lobby $lobbyId: $e',
        tag: logTag,
      );
      return (false, null, ErrorCode.firebaseError);
    }
  }

  /// Vérifie si un joueur est dans un lobby
  ///
  /// Renvoie un tuple avec:
  /// - un booléen indiquant si le joueur est dans le lobby
  /// - le modèle de lobby si la récupération a réussi
  /// - un code d'erreur en cas d'échec
  Future<(bool, LobbyModel?, ErrorCode?)> verifyPlayerInLobby(
    String lobbyId,
    String userId,
  ) async {
    try {
      logger.debug(
        'Verifying if player $userId is in lobby $lobbyId',
        tag: logTag,
      );

      final (lobby, errorCode) = await fetchLobbyById(lobbyId);

      if (errorCode != null) {
        return (false, null, errorCode);
      }

      final bool isInLobby = lobby!.players.any(
        (player) => player.userId == userId,
      );

      if (!isInLobby) {
        logger.warning('Player $userId is not in lobby $lobbyId', tag: logTag);
        return (false, lobby, ErrorCode.playerNotInLobby);
      }

      return (true, lobby, null);
    } catch (e) {
      logger.error(
        'Error verifying player presence in lobby $lobbyId: $e',
        tag: logTag,
      );
      return (false, null, ErrorCode.firebaseError);
    }
  }

  /// Met à jour l'activité d'un joueur dans un lobby
  Future<(bool, ErrorCode?)> updatePlayerActivity(
    String lobbyId,
    String userId,
  ) async {
    try {
      logger.debug(
        'Updating activity for player $userId in lobby $lobbyId',
        tag: logTag,
      );

      final (isInLobby, lobby, errorCode) = await verifyPlayerInLobby(
        lobbyId,
        userId,
      );

      if (!isInLobby || errorCode != null) {
        return (false, errorCode);
      }

      // Trouver l'index du joueur dans la liste
      final playerIndex = lobby!.players.indexWhere(
        (player) => player.userId == userId,
      );

      if (playerIndex == -1) {
        // Ce cas ne devrait pas se produire grâce à la vérification précédente
        return (false, ErrorCode.playerNotInLobby);
      }

      // Mettre à jour la liste des joueurs avec le joueur actif
      final updatedPlayers = List<LobbyPlayerModel>.from(lobby.players);
      updatedPlayers[playerIndex] = updatedPlayers[playerIndex].copyWith(
        lastActive: DateTime.now(),
      );

      // Mettre à jour le document Firestore
      await lobbiesRef.doc(lobbyId).update({
        'players': updatedPlayers.map((player) => player.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.debug(
        'Player activity updated successfully for $userId in $lobbyId',
        tag: logTag,
      );

      return (true, null);
    } catch (e) {
      logger.error(
        'Error updating player activity in lobby $lobbyId: $e',
        tag: logTag,
      );
      return (false, ErrorCode.firebaseError);
    }
  }

  /// Supprime un joueur d'un lobby
  Future<(bool, ErrorCode?)> removePlayerFromLobby(
    String lobbyId,
    String userId, {
    bool isLeaving = true,
    bool shouldDeleteEmptyLobby = true,
  }) async {
    try {
      logger.debug(
        'Removing player $userId from lobby $lobbyId (isLeaving: $isLeaving)',
        tag: logTag,
      );

      final (isInLobby, lobby, errorCode) = await verifyPlayerInLobby(
        lobbyId,
        userId,
      );

      if (!isInLobby || errorCode != null) {
        return (false, errorCode);
      }

      // Liste des joueurs sans le joueur à retirer
      final updatedPlayers =
          lobby!.players.where((player) => player.userId != userId).toList();

      // Si c'était l'hôte et qu'il reste des joueurs, transférer l'hôte
      bool transferredHost = false;
      if (lobby.hostId == userId && updatedPlayers.isNotEmpty) {
        // Sélectionner le joueur qui a rejoint le plus tôt comme nouvel hôte
        updatedPlayers.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

        // Mettre à jour le premier joueur pour qu'il devienne l'hôte
        final newHostIndex = 0;
        updatedPlayers[newHostIndex] = updatedPlayers[newHostIndex].copyWith(
          isHost: true,
        );

        transferredHost = true;

        logger.info(
          'Host $userId left lobby $lobbyId. New host: ${updatedPlayers[newHostIndex].userId}',
          tag: logTag,
        );
      }

      // S'il ne reste plus de joueurs et que shouldDeleteEmptyLobby est true, supprimer le lobby
      if (updatedPlayers.isEmpty && shouldDeleteEmptyLobby) {
        await lobbiesRef.doc(lobbyId).delete();
        logger.info('Lobby $lobbyId deleted as it became empty', tag: logTag);
        return (true, null);
      }

      // Sinon, mettre à jour le lobby avec la nouvelle liste de joueurs
      await lobbiesRef.doc(lobbyId).update({
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'hostId': transferredHost ? updatedPlayers[0].userId : lobby.hostId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.info(
        'Player $userId ${isLeaving ? "left" : "was removed from"} lobby $lobbyId',
        tag: logTag,
      );

      return (true, null);
    } catch (e) {
      logger.error(
        'Error removing player $userId from lobby $lobbyId: $e',
        tag: logTag,
      );
      return (false, ErrorCode.firebaseError);
    }
  }

  /// Ajoute un joueur à un lobby
  Future<(bool, ErrorCode?)> addPlayerToLobby(
    String lobbyId,
    LobbyPlayerModel player,
  ) async {
    try {
      logger.debug(
        'Adding player ${player.userId} to lobby $lobbyId',
        tag: logTag,
      );

      final (lobby, errorCode) = await fetchLobbyById(lobbyId);

      if (errorCode != null) {
        return (false, errorCode);
      }

      // Vérifier si le lobby n'est pas plein
      if (lobby!.players.length >= lobby.maxPlayers) {
        logger.warning('Lobby $lobbyId is full', tag: logTag);
        return (false, ErrorCode.lobbyFull);
      }

      // Vérifier si le lobby n'est pas en cours de partie
      if (lobby.isInProgress) {
        logger.warning('Lobby $lobbyId is in progress', tag: logTag);
        return (false, ErrorCode.lobbyInProgress);
      }

      // Vérifier si le joueur n'est pas déjà dans le lobby
      final bool isAlreadyInLobby = lobby.players.any(
        (p) => p.userId == player.userId,
      );

      if (isAlreadyInLobby) {
        logger.warning(
          'Player ${player.userId} is already in lobby $lobbyId',
          tag: logTag,
        );
        return (false, ErrorCode.playerAlreadyInLobby);
      }

      // Ajouter le joueur à la liste
      final updatedPlayers = List<LobbyPlayerModel>.from(lobby.players)
        ..add(player);

      // Mettre à jour le document
      await lobbiesRef.doc(lobbyId).update({
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.info('Player ${player.userId} joined lobby $lobbyId', tag: logTag);

      return (true, null);
    } catch (e) {
      logger.error(
        'Error adding player ${player.userId} to lobby $lobbyId: $e',
        tag: logTag,
      );
      return (false, ErrorCode.firebaseError);
    }
  }
}
