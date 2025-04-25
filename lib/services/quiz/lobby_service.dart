/// Lobby Service
///
/// Service de gestion des lobbys pour les quiz
/// Permet de créer, rejoindre, modifier et quitter des lobbys
/// Synchronisation en temps réel avec Firestore
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/models/chat/chat_message_model.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';
import 'package:quizzzed/models/lobby/lobby_player_model.dart';
import 'package:quizzzed/models/user/user_model.dart';
import 'package:quizzzed/services/chat_service.dart';
import 'package:quizzzed/services/firebase_service.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:quizzzed/services/error_message_service.dart';

class LobbyService {
  final FirebaseService _firebaseService = FirebaseService();
  final LoggerService _logger = LoggerService();
  final ErrorMessageService _errorService = ErrorMessageService();
  final ChatService _chatService = ChatService();

  // Collection Firestore pour les lobbys
  static const String _collectionName = 'lobbies';

  // Référence à la collection Firestore
  CollectionReference<Map<String, dynamic>> get _lobbysCollection =>
      _firebaseService.firestore.collection(_collectionName);

  // Créer un nouveau lobby
  Future<LobbyModel?> createLobby({
    required UserModel host,
    required String name,
    String? quizId,
    LobbyVisibility visibility = LobbyVisibility.public,
    int maxPlayers = AppConfig.maxPlayersPerLobby,
    int minPlayers = AppConfig.minPlayersToStart,
    bool allowLateJoin = false,
  }) async {
    try {
      // Créer le modèle de lobby
      final lobby = LobbyModel.create(
        hostId: host.uid,
        name: name,
        quizId: quizId,
        visibility: visibility,
        maxPlayers: maxPlayers,
        minPlayers: minPlayers,
        allowLateJoin: allowLateJoin,
      );

      // Ajouter l'hôte comme premier joueur
      final lobbyWithHost = lobby.copyWith(
        players: [LobbyPlayerModel.fromUser(host, isHost: true)],
      );

      // Sauvegarder dans Firestore
      final docRef = await _lobbysCollection.add(lobbyWithHost.toFirestore());

      // Récupérer le lobby avec son ID
      final newLobby = lobbyWithHost.copyWith(id: docRef.id);

      _logger.info(
        'Lobby créé',
        tag: 'LobbyService',
        data: {'lobbyId': newLobby.id, 'name': newLobby.name},
      );

      // Envoyer un message système dans le chat du lobby
      await _chatService.sendSystemMessage(
        lobbyId: newLobby.id,
        text: "Lobby \"${newLobby.name}\" créé par ${host.displayName}",
        channel: ChatChannel.lobby,
      );

      return newLobby;
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de la création du lobby : $e',
        tag: 'LobbyService',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // Rejoindre un lobby existant
  Future<bool> joinLobby(String lobbyId, UserModel user) async {
    try {
      // Vérifier si le lobby existe
      final lobbyDoc = await _lobbysCollection.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        _logger.warning(
          'Tentative de rejoindre un lobby inexistant',
          tag: 'LobbyService',
          data: {'lobbyId': lobbyId},
        );
        return false;
      }

      // Convertir en modèle
      final lobby = LobbyModel.fromFirestore(lobbyDoc);

      // Vérifier si l'utilisateur peut rejoindre
      if (!lobby.canJoin()) {
        _logger.warning(
          'Impossible de rejoindre le lobby',
          tag: 'LobbyService',
          data: {
            'lobbyId': lobbyId,
            'reason':
                lobby.status != LobbyStatus.waitingForPlayers
                    ? 'Lobby en cours ou terminé'
                    : 'Lobby complet',
          },
        );
        return false;
      }

      // Vérifier si l'utilisateur est déjà dans le lobby
      if (lobby.players.any((player) => player.userId == user.uid)) {
        _logger.info(
          'Utilisateur déjà dans le lobby',
          tag: 'LobbyService',
          data: {'lobbyId': lobbyId, 'userId': user.uid},
        );
        return true;
      }

      // Ajouter le joueur au lobby
      final newPlayer = LobbyPlayerModel.fromUser(user);
      final updatedPlayers = [...lobby.players, newPlayer];

      // Mettre à jour le document
      await _lobbysCollection.doc(lobbyId).update({
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      _logger.info(
        'Utilisateur a rejoint le lobby',
        tag: 'LobbyService',
        data: {
          'lobbyId': lobbyId,
          'userId': user.uid,
          'playerCount': updatedPlayers.length,
        },
      );

      // Envoyer un message système dans le chat du lobby
      await _chatService.sendSystemMessage(
        lobbyId: lobbyId,
        text: "${user.displayName} a rejoint le lobby",
        channel: ChatChannel.lobby,
      );

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de la tentative de rejoindre un lobby : $e',
        tag: 'LobbyService',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Rejoindre un lobby privé par code d'accès
  Future<String?> joinPrivateLobbyByCode(
    String accessCode,
    UserModel user,
  ) async {
    try {
      // Rechercher le lobby avec ce code d'accès
      final querySnapshot =
          await _lobbysCollection
              .where('accessCode', isEqualTo: accessCode)
              .where(
                'status',
                isEqualTo: LobbyStatus.waitingForPlayers.toString(),
              )
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        _logger.warning(
          'Aucun lobby trouvé avec ce code d\'accès',
          tag: 'LobbyService',
          data: {'accessCode': accessCode},
        );
        return null;
      }

      final lobbyDoc = querySnapshot.docs.first;
      final lobbyId = lobbyDoc.id;

      // Tenter de rejoindre ce lobby
      final success = await joinLobby(lobbyId, user);

      return success ? lobbyId : null;
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de la recherche par code d\'accès : $e',
        tag: 'LobbyService',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // Mettre à jour le statut de préparation d'un joueur
  Future<bool> updatePlayerReadyStatus(
    String lobbyId,
    String userId,
    bool isReady,
  ) async {
    try {
      // Récupérer le lobby actuel
      final lobbyDoc = await _lobbysCollection.doc(lobbyId).get();
      if (!lobbyDoc.exists) return false;

      final lobby = LobbyModel.fromFirestore(lobbyDoc);

      // Trouver l'index du joueur
      final playerIndex = lobby.players.indexWhere(
        (player) => player.userId == userId,
      );
      if (playerIndex == -1) return false;

      // Récupérer les infos du joueur
      final player = lobby.players[playerIndex];

      // Mettre à jour le statut du joueur
      final updatedPlayers = List<LobbyPlayerModel>.from(lobby.players);
      updatedPlayers[playerIndex] = updatedPlayers[playerIndex].copyWith(
        isReady: isReady,
        lastActive: DateTime.now(),
      );

      // Mettre à jour le document
      await _lobbysCollection.doc(lobbyId).update({
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      // Envoyer un message système dans le chat du lobby
      await _chatService.sendSystemMessage(
        lobbyId: lobbyId,
        text: "${player.displayName} est ${isReady ? 'prêt' : 'en attente'}",
        channel: ChatChannel.lobby,
      );

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de la mise à jour du statut du joueur: $e',
        tag: 'LobbyService',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Quitter un lobby
  Future<bool> leaveLobby(String lobbyId, String userId) async {
    try {
      // Récupérer le lobby actuel
      final lobbyDoc = await _lobbysCollection.doc(lobbyId).get();
      if (!lobbyDoc.exists) return false;

      final lobby = LobbyModel.fromFirestore(lobbyDoc);

      // Trouver le joueur qui quitte
      final player = lobby.players.firstWhere(
        (player) => player.userId == userId,
      );

      // Vérifier si l'utilisateur est l'hôte
      final isHost = lobby.hostId == userId;

      // Si c'est l'hôte, supprimer le lobby
      if (isHost) {
        // Envoyer un message système avant de supprimer le lobby
        await _chatService.sendSystemMessage(
          lobbyId: lobbyId,
          text: "L'hôte ${player.displayName} a quitté - Le lobby a été fermé",
          channel: ChatChannel.lobby,
        );

        await _lobbysCollection.doc(lobbyId).delete();
        _logger.info(
          'Lobby supprimé car l\'hôte l\'a quitté',
          tag: 'LobbyService',
          data: {'lobbyId': lobbyId, 'hostId': userId},
        );
        return true;
      }

      // Sinon, retirer le joueur de la liste
      final updatedPlayers =
          lobby.players.where((player) => player.userId != userId).toList();

      // Mettre à jour le document
      await _lobbysCollection.doc(lobbyId).update({
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      _logger.info(
        'Joueur a quitté le lobby',
        tag: 'LobbyService',
        data: {
          'lobbyId': lobbyId,
          'userId': userId,
          'remainingPlayers': updatedPlayers.length,
        },
      );

      // Envoyer un message système dans le chat du lobby
      await _chatService.sendSystemMessage(
        lobbyId: lobbyId,
        text: "${player.displayName} a quitté le lobby",
        channel: ChatChannel.lobby,
      );

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de la tentative de quitter un lobby: $e',
        tag: 'LobbyService',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Supprimer un joueur du lobby (réservé à l'hôte)
  Future<bool> kickPlayer(
    String lobbyId,
    String hostId,
    String playerIdToKick,
  ) async {
    try {
      // Récupérer le lobby actuel
      final lobbyDoc = await _lobbysCollection.doc(lobbyId).get();
      if (!lobbyDoc.exists) return false;

      final lobby = LobbyModel.fromFirestore(lobbyDoc);

      // Vérifier si l'utilisateur qui fait la demande est bien l'hôte
      if (lobby.hostId != hostId) {
        _logger.warning(
          'Tentative de kick par un non-hôte',
          tag: 'LobbyService',
          data: {
            'lobbyId': lobbyId,
            'requesterId': hostId,
            'actualHostId': lobby.hostId,
          },
        );
        return false;
      }

      // Trouver le joueur qui va être expulsé
      final playerToKick = lobby.players.firstWhere(
        (player) => player.userId == playerIdToKick,
      );

      // Retirer le joueur de la liste
      final updatedPlayers =
          lobby.players
              .where((player) => player.userId != playerIdToKick)
              .toList();

      // Mettre à jour le document
      await _lobbysCollection.doc(lobbyId).update({
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      _logger.info(
        'Joueur expulsé du lobby',
        tag: 'LobbyService',
        data: {
          'lobbyId': lobbyId,
          'kickedPlayerId': playerIdToKick,
          'byHostId': hostId,
        },
      );

      // Envoyer un message système dans le chat du lobby
      await _chatService.sendSystemMessage(
        lobbyId: lobbyId,
        text: "${playerToKick.displayName} a été expulsé du lobby",
        channel: ChatChannel.lobby,
      );

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de l\'expulsion d\'un joueur : $e',
        tag: 'LobbyService',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Mettre à jour les paramètres d'un lobby (réservé à l'hôte)
  Future<bool> updateLobbySettings(
    String lobbyId,
    String hostId, {
    String? name,
    LobbyVisibility? visibility,
    int? maxPlayers,
    int? minPlayers,
    bool? allowLateJoin,
  }) async {
    try {
      // Récupérer le lobby actuel
      final lobbyDoc = await _lobbysCollection.doc(lobbyId).get();
      if (!lobbyDoc.exists) return false;

      final lobby = LobbyModel.fromFirestore(lobbyDoc);

      // Vérifier si l'utilisateur qui fait la demande est bien l'hôte
      if (lobby.hostId != hostId) {
        _logger.warning(
          'Tentative de modification par un non-hôte',
          tag: 'LobbyService',
          data: {
            'lobbyId': lobbyId,
            'requesterId': hostId,
            'actualHostId': lobby.hostId,
          },
        );
        return false;
      }

      // Trouver le nom de l'hôte
      final host = lobby.players.firstWhere(
        (player) => player.userId == hostId,
      );

      // Préparer les mises à jour
      final updates = <String, dynamic>{'updatedAt': Timestamp.now()};

      // Construire le message pour le chat
      String updateMessage =
          "${host.displayName} a modifié les paramètres du lobby:";
      bool hasChanges = false;

      if (name != null) {
        updates['name'] = name;
        updateMessage += "\n- Nom: ${lobby.name} → $name";
        hasChanges = true;
      }

      if (visibility != null) {
        updates['visibility'] = visibility.toString();
        updateMessage +=
            "\n- Visibilité: ${lobby.visibility.toFrench()} → ${visibility.toFrench()}";
        hasChanges = true;

        // Si passage à privé, générer un code d'accès
        if (visibility == LobbyVisibility.private && lobby.accessCode.isEmpty) {
          final code = _generateRandomCode();
          updates['accessCode'] = code;
          updateMessage += "\n- Code d'accès généré: $code";
        }
        // Si passage à public, supprimer le code d'accès
        if (visibility == LobbyVisibility.public) {
          updates['accessCode'] = '';
          updateMessage += "\n- Code d'accès supprimé";
        }
      }

      if (maxPlayers != null) {
        updates['maxPlayers'] = maxPlayers;
        updateMessage += "\n- Joueurs max: ${lobby.maxPlayers} → $maxPlayers";
        hasChanges = true;
      }

      if (minPlayers != null) {
        updates['minPlayers'] = minPlayers;
        updateMessage += "\n- Joueurs min: ${lobby.minPlayers} → $minPlayers";
        hasChanges = true;
      }

      if (allowLateJoin != null) {
        updates['allowLateJoin'] = allowLateJoin;
        updateMessage +=
            "\n- Rejoindre en cours: ${lobby.allowLateJoin ? 'Oui' : 'Non'} → ${allowLateJoin ? 'Oui' : 'Non'}";
        hasChanges = true;
      }

      // Mettre à jour le document
      await _lobbysCollection.doc(lobbyId).update(updates);

      _logger.info(
        'Paramètres du lobby mis à jour',
        tag: 'LobbyService',
        data: {'lobbyId': lobbyId, 'byHostId': hostId, 'updates': updates},
      );

      // Envoyer un message système dans le chat du lobby si des changements ont été effectués
      if (hasChanges) {
        await _chatService.sendSystemMessage(
          lobbyId: lobbyId,
          text: updateMessage,
          channel: ChatChannel.lobby,
        );
      }

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de la mise à jour des paramètres : $e',
        tag: 'LobbyService',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Récupérer un lobby par ID
  Future<LobbyModel?> getLobbyById(String lobbyId) async {
    try {
      final lobbyDoc = await _lobbysCollection.doc(lobbyId).get();
      if (!lobbyDoc.exists) return null;

      return LobbyModel.fromFirestore(lobbyDoc);
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de la récupération du lobby: $e',
        tag: 'LobbyService',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // Obtenir un stream pour les lobbys publics
  Stream<List<LobbyModel>> getPublicLobbiesStream() {
    return _lobbysCollection
        .where('visibility', isEqualTo: LobbyVisibility.public.toString())
        .where('status', isEqualTo: LobbyStatus.waitingForPlayers.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => LobbyModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Obtenir un stream pour un lobby spécifique (pour les updates en temps réel)
  Stream<LobbyModel?> getLobbyStream(String lobbyId) {
    return _lobbysCollection.doc(lobbyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return LobbyModel.fromFirestore(doc);
    });
  }

  // Obtenir les lobbys de l'utilisateur (où il est présent)
  Future<List<LobbyModel>> getUserLobbies(String userId) async {
    try {
      final snapshot =
          await _lobbysCollection
              .where('players', arrayContains: {'userId': userId})
              .get();

      return snapshot.docs.map((doc) => LobbyModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de la récupération des lobbys de l\'utilisateur: $e',
        tag: 'LobbyService',
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // Démarrer un quiz dans un lobby (réservé à l'hôte)
  Future<bool> startLobbyQuiz(String lobbyId, String hostId) async {
    try {
      // Récupérer le lobby actuel
      final lobbyDoc = await _lobbysCollection.doc(lobbyId).get();
      if (!lobbyDoc.exists) return false;

      final lobby = LobbyModel.fromFirestore(lobbyDoc);

      // Vérifier si l'utilisateur est l'hôte
      if (lobby.hostId != hostId) {
        _logger.warning(
          'Tentative de démarrage par un non-hôte',
          tag: 'LobbyService',
          data: {
            'lobbyId': lobbyId,
            'requesterId': hostId,
            'actualHostId': lobby.hostId,
          },
        );
        return false;
      }

      // Récupérer les infos de l'hôte
      final host = lobby.players.firstWhere(
        (player) => player.userId == hostId,
      );

      // Vérifier si le quiz peut démarrer
      if (!lobby.canStart) {
        _logger.warning(
          'Impossible de démarrer le quiz',
          tag: 'LobbyService',
          data: {
            'lobbyId': lobbyId,
            'playerCount': lobby.players.length,
            'minPlayers': lobby.minPlayers,
            'allReady': lobby.players.every((p) => p.isReady),
          },
        );
        return false;
      }

      // Changer l'état du lobby
      await _lobbysCollection.doc(lobbyId).update({
        'status': LobbyStatus.playing.toString(),
        'updatedAt': Timestamp.now(),
      });

      _logger.info(
        'Quiz démarré dans le lobby',
        tag: 'LobbyService',
        data: {
          'lobbyId': lobbyId,
          'quizId': lobby.quizId,
          'playerCount': lobby.players.length,
        },
      );

      // Envoyer un message système dans le chat du lobby
      await _chatService.sendSystemMessage(
        lobbyId: lobbyId,
        text:
            "🎮 ${host.displayName} a démarré la partie avec ${lobby.players.length} joueurs",
        channel: ChatChannel.lobby,
      );

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors du démarrage du quiz: $e',
        tag: 'LobbyService',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Mettre à jour la dernière activité d'un joueur
  Future<void> updatePlayerActivity(String lobbyId, String userId) async {
    try {
      // Récupérer le lobby actuel
      final lobbyDoc = await _lobbysCollection.doc(lobbyId).get();
      if (!lobbyDoc.exists) return;

      final lobby = LobbyModel.fromFirestore(lobbyDoc);

      // Trouver l'index du joueur
      final playerIndex = lobby.players.indexWhere(
        (player) => player.userId == userId,
      );
      if (playerIndex == -1) return;

      // Mettre à jour la dernière activité
      final updatedPlayers = List<LobbyPlayerModel>.from(lobby.players);
      updatedPlayers[playerIndex] = updatedPlayers[playerIndex].copyWith(
        lastActive: DateTime.now(),
      );

      // Mettre à jour le document
      await _lobbysCollection.doc(lobbyId).update({
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
      });
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de la mise à jour de l\'activité du joueur: $e',
        tag: 'LobbyService',
        stackTrace: stackTrace,
      );
    }
  }

  // Méthode pour générer un code d'accès aléatoire
  String _generateRandomCode() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sans I, O, 0, 1 pour éviter confusion
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    String code = '';

    for (int i = 0; i < 6; i++) {
      final index = (random.codeUnitAt(i % random.length) + i) % chars.length;
      code += chars[index];
    }

    return code;
  }
}

// Extension pour la visibilité du lobby
extension LobbyVisibilityExtension on LobbyVisibility {
  String toFrench() {
    switch (this) {
      case LobbyVisibility.public:
        return 'Publique';
      case LobbyVisibility.private:
        return 'Privée';
      default:
        return toString();
    }
  }
}
