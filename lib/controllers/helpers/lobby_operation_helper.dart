/// Classe utilitaire pour les opérations communes sur les lobbies
///
/// Cette classe fournit des méthodes d'aide pour les opérations fréquemment
/// utilisées dans les différents contrôleurs de lobby.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

      if (errorCode != null) {
        return (false, errorCode);
      }

      if (!isInLobby) {
        return (false, ErrorCode.playerNotInLobby);
      }

      // Mettre à jour l'activité du joueur
      final updatedPlayers = List<LobbyPlayerModel>.from(lobby!.players);
      final playerIndex = updatedPlayers.indexWhere(
        (player) => player.userId == userId,
      );

      if (playerIndex >= 0) {
        // Mettre à jour le timestamp lastActive
        updatedPlayers[playerIndex] = updatedPlayers[playerIndex].copyWith(
          lastActive: DateTime.now(),
        );

        // Mettre à jour le document du lobby
        await lobbiesRef.doc(lobbyId).update({
          'players': updatedPlayers.map((player) => player.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return (true, null);
      } else {
        // Ne devrait pas arriver car verifyPlayerInLobby a déjà vérifié
        return (false, ErrorCode.playerNotInLobby);
      }
    } catch (e) {
      logger.error(
        'Error updating activity for player $userId in lobby $lobbyId: $e',
        tag: logTag,
      );
      return (false, ErrorCode.firebaseError);
    }
  }

  /// Configure un stream pour recevoir les mises à jour d'un lobby en temps réel
  ///
  /// Renvoie:
  /// - Le StreamSubscription créé (à annuler lorsqu'il n'est plus nécessaire)
  /// - Un code d'erreur en cas d'échec
  Stream<DocumentSnapshot<Object?>> getLobbyStream(String lobbyId) {
    logger.debug('Creating lobby stream for ID: $lobbyId', tag: logTag);
    return lobbiesRef.doc(lobbyId).snapshots();
  }

  /// Ajoute un nouveau joueur au lobby
  ///
  /// Renvoie un tuple avec:
  /// - un booléen indiquant si l'ajout a réussi
  /// - le modèle de lobby mis à jour
  /// - un code d'erreur en cas d'échec
  Future<(bool, LobbyModel?, ErrorCode?)> addPlayerToLobby(
    String lobbyId,
    LobbyPlayerModel player,
  ) async {
    try {
      logger.debug(
        'Adding player ${player.userId} to lobby $lobbyId',
        tag: logTag,
      );

      // Récupérer le lobby pour vérifier les conditions d'ajout
      final (lobby, errorCode) = await fetchLobbyById(lobbyId);

      if (errorCode != null) {
        return (false, null, errorCode);
      }

      // Vérifier si le lobby est en cours
      if (lobby!.isInProgress) {
        return (false, lobby, ErrorCode.lobbyInProgress);
      }

      // Vérifier si le lobby est plein
      if (lobby.players.length >= lobby.maxPlayers) {
        return (false, lobby, ErrorCode.lobbyFull);
      }

      // Vérifier si le joueur est déjà dans le lobby
      if (lobby.players.any((p) => p.userId == player.userId)) {
        // Si le joueur est déjà dans le lobby, considérer cela comme un succès
        return (true, lobby, null);
      }

      // Ajouter le joueur en utilisant une transaction pour éviter les conflits
      // Récupérer à nouveau le document pour éviter les conflits d'écriture
      final freshDoc = await lobbiesRef.doc(lobbyId).get();

      if (!freshDoc.exists) {
        return (false, null, ErrorCode.lobbyNotFound);
      }

      final freshData = freshDoc.data() as Map<String, dynamic>;
      final freshLobby = LobbyModel.fromMap(freshData, lobbyId);

      // Vérifier à nouveau les conditions (pourraient avoir changé)
      if (freshLobby.isInProgress) {
        return (false, freshLobby, ErrorCode.lobbyInProgress);
      }

      if (freshLobby.players.length >= freshLobby.maxPlayers) {
        return (false, freshLobby, ErrorCode.lobbyFull);
      }

      if (freshLobby.players.any((p) => p.userId == player.userId)) {
        // Si le joueur est déjà dans le lobby, considérer cela comme un succès
        return (true, freshLobby, null);
      }

      // Ajouter le joueur
      final updatedPlayers = [...freshLobby.players, player];

      // Mettre à jour le document du lobby
      await lobbiesRef.doc(lobbyId).update({
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reconstruire le modèle complet avec le joueur ajouté
      final updatedLobby = freshLobby.copyWith(players: updatedPlayers);

      logger.info(
        'Player ${player.userId} added to lobby $lobbyId',
        tag: logTag,
      );

      return (true, updatedLobby, null);
    } catch (e) {
      logger.error('Error adding player to lobby $lobbyId: $e', tag: logTag);
      return (false, null, ErrorCode.firebaseError);
    }
  }

  /// Supprime un joueur d'un lobby
  ///
  /// Paramètres:
  /// - lobbyId: ID du lobby
  /// - userId: ID du joueur à supprimer
  /// - isLeaving: true si le joueur quitte volontairement, false s'il est expulsé
  /// - shouldDeleteEmptyLobby: si true et que le lobby devient vide, il sera supprimé
  ///
  /// Renvoie un tuple avec:
  /// - un booléen indiquant si la suppression a réussi
  /// - un code d'erreur en cas d'échec
  Future<(bool, ErrorCode?)> removePlayerFromLobby(
    String lobbyId,
    String userId, {
    bool isLeaving = true,
    bool shouldDeleteEmptyLobby = true,
  }) async {
    try {
      logger.debug(
        'Removing player $userId from lobby $lobbyId',
        tag: logTag,
        data: {
          'isLeaving': isLeaving,
          'shouldDeleteEmptyLobby': shouldDeleteEmptyLobby,
        },
      );

      // Récupérer le lobby pour vérifier les conditions
      final (lobby, errorCode) = await fetchLobbyById(lobbyId);

      if (errorCode != null) {
        return (false, errorCode);
      }

      // Vérifier si le joueur est dans le lobby
      final playerIndex = lobby!.players.indexWhere(
        (player) => player.userId == userId,
      );

      if (playerIndex == -1) {
        logger.warning(
          'Player $userId not found in lobby $lobbyId',
          tag: logTag,
        );
        return (false, ErrorCode.playerNotInLobby);
      }

      // Vérifier si le joueur est l'hôte
      final isHost = lobby.hostId == userId;

      // Supprimer le joueur de la liste
      final updatedPlayers = List<LobbyPlayerModel>.from(lobby.players);
      updatedPlayers.removeAt(playerIndex);

      // Si le lobby devient vide et qu'on doit le supprimer
      if (updatedPlayers.isEmpty && shouldDeleteEmptyLobby) {
        await lobbiesRef.doc(lobbyId).delete();
        logger.info('Empty lobby $lobbyId deleted', tag: logTag);
        return (true, null);
      }

      // Si l'hôte quitte, transférer la propriété au joueur suivant
      String newHostId = lobby.hostId;
      if (isHost && updatedPlayers.isNotEmpty) {
        newHostId = updatedPlayers[0].userId;

        // Mettre à jour le premier joueur pour qu'il soit l'hôte
        updatedPlayers[0] = updatedPlayers[0].copyWith(isHost: true);

        logger.info(
          'Host $userId left, transferring ownership to $newHostId',
          tag: logTag,
        );
      }

      // Mettre à jour le document du lobby
      await lobbiesRef.doc(lobbyId).update({
        'players': updatedPlayers.map((player) => player.toMap()).toList(),
        'hostId': newHostId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.info(
        'Player $userId removed from lobby $lobbyId',
        tag: logTag,
        data: {'wasHost': isHost, 'newHostId': isHost ? newHostId : null},
      );
      return (true, null);
    } catch (e) {
      logger.error(
        'Error removing player from lobby $lobbyId: $e',
        tag: logTag,
      );
      return (false, ErrorCode.firebaseError);
    }
  }

  /// Met à jour le statut "prêt" d'un joueur
  Future<(bool, ErrorCode?)> togglePlayerReadyStatus(
    String lobbyId,
    String userId,
  ) async {
    try {
      logger.debug(
        'Toggling ready status for player $userId in lobby $lobbyId',
        tag: logTag,
      );

      final (isInLobby, lobby, errorCode) = await verifyPlayerInLobby(
        lobbyId,
        userId,
      );

      if (errorCode != null) {
        return (false, errorCode);
      }

      if (!isInLobby) {
        return (false, ErrorCode.playerNotInLobby);
      }

      // Trouver le joueur dans la liste
      final playerIndex = lobby!.players.indexWhere(
        (player) => player.userId == userId,
      );

      // Basculer son statut "prêt"
      final updatedPlayers = List<LobbyPlayerModel>.from(lobby.players);
      final currentStatus = updatedPlayers[playerIndex].isReady;
      updatedPlayers[playerIndex] = updatedPlayers[playerIndex].copyWith(
        isReady: !currentStatus,
        lastActive: DateTime.now(),
      );

      // Mettre à jour le document du lobby
      await lobbiesRef.doc(lobbyId).update({
        'players': updatedPlayers.map((player) => player.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.info(
        'Ready status for player $userId in lobby $lobbyId toggled to ${!currentStatus}',
        tag: logTag,
      );
      return (true, null);
    } catch (e) {
      logger.error(
        'Error toggling ready status for player $userId in lobby $lobbyId: $e',
        tag: logTag,
      );
      return (false, ErrorCode.firebaseError);
    }
  }

  /// Transfère la propriété du lobby à un autre joueur
  Future<(bool, ErrorCode?)> transferLobbyOwnership(
    String lobbyId,
    String currentOwnerId,
    String newOwnerId,
  ) async {
    try {
      logger.debug(
        'Transferring ownership of lobby $lobbyId from $currentOwnerId to $newOwnerId',
        tag: logTag,
      );

      // Vérifier si l'utilisateur actuel est l'hôte
      final (isHost, lobby, hostErrorCode) = await verifyUserIsHost(
        lobbyId,
        currentOwnerId,
      );

      if (hostErrorCode != null) {
        return (false, hostErrorCode);
      }

      if (!isHost) {
        return (false, ErrorCode.notAuthorized);
      }

      // Vérifier si le nouveau propriétaire est dans le lobby
      final isNewOwnerInLobby = lobby!.players.any(
        (player) => player.userId == newOwnerId,
      );

      if (!isNewOwnerInLobby) {
        logger.warning(
          'New owner $newOwnerId not found in lobby $lobbyId',
          tag: logTag,
        );
        return (false, ErrorCode.playerNotInLobby);
      }

      // Mettre à jour les statuts d'hôte pour tous les joueurs
      final updatedPlayers =
          lobby.players.map((player) {
            if (player.userId == currentOwnerId) {
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
        'Ownership of lobby $lobbyId transferred from $currentOwnerId to $newOwnerId',
        tag: logTag,
      );
      return (true, null);
    } catch (e) {
      logger.error(
        'Error transferring ownership of lobby $lobbyId: $e',
        tag: logTag,
      );
      return (false, ErrorCode.firebaseError);
    }
  }
}
