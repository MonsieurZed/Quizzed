import 'package:quizzed/models/player.dart';
import 'package:quizzed/services/database_service.dart';
import 'package:quizzed/services/logging_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerRepository {
  final DatabaseService _databaseService = DatabaseService();
  final LoggingService _logger = LoggingService();
  final CollectionReference _playersCollection = FirebaseFirestore.instance
      .collection('players');

  // Create or update a player
  Future<void> savePlayer(Player player) async {
    try {
      _logger.logInfo(
        'Saving player: ${player.id}, nickname: ${player.nickname}',
        'PlayerRepository.savePlayer',
      );
      await _databaseService.upsertPlayer(player.id, player.toFirestore());
      _logger.logInfo(
        'Player saved successfully: ${player.id}',
        'PlayerRepository.savePlayer',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error saving player: ${player.id}',
        e,
        stackTrace,
        'PlayerRepository.savePlayer',
      );
      rethrow;
    }
  }

  // Get all players
  Stream<List<Player>> getPlayers() {
    _logger.logDebug('Streaming all players', 'PlayerRepository.getPlayers');
    return _databaseService.getPlayers().map((snapshot) {
      final players =
          snapshot.docs.map((doc) => Player.fromFirestore(doc)).toList();
      _logger.logDebug(
        'Mapped ${players.length} players from snapshot',
        'PlayerRepository.getPlayers',
      );
      return players;
    });
  }

  // Get a specific player
  Future<Player?> getPlayer(String playerId) async {
    try {
      _logger.logInfo(
        'Fetching player by ID: $playerId',
        'PlayerRepository.getPlayer',
      );
      DocumentSnapshot doc = await _playersCollection.doc(playerId).get();
      Player? player = doc.exists ? Player.fromFirestore(doc) : null;

      if (player != null) {
        _logger.logInfo(
          'Player found: $playerId, nickname: ${player.nickname}',
          'PlayerRepository.getPlayer',
        );
      } else {
        _logger.logWarning(
          'Player not found: $playerId',
          'PlayerRepository.getPlayer',
        );
      }

      return player;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error getting player: $playerId',
        e,
        stackTrace,
        'PlayerRepository.getPlayer',
      );
      rethrow;
    }
  }

  // Get players by session
  Stream<List<Player>> getSessionPlayers(String sessionId) {
    _logger.logDebug(
      'Streaming players for session: $sessionId',
      'PlayerRepository.getSessionPlayers',
    );
    return _databaseService.getSessionPlayers(sessionId).map((snapshot) {
      final players =
          snapshot.docs.map((doc) => Player.fromFirestore(doc)).toList();
      _logger.logDebug(
        'Mapped ${players.length} session players from snapshot',
        'PlayerRepository.getSessionPlayers',
      );
      return players;
    });
  }

  // Update player score
  Future<void> updatePlayerScore(String playerId, int score) async {
    try {
      _logger.logInfo(
        'Updating player score: $playerId, score increment: $score',
        'PlayerRepository.updatePlayerScore',
      );
      await _playersCollection.doc(playerId).update({
        'score': FieldValue.increment(score),
      });
      _logger.logInfo(
        'Player score updated: $playerId, score increment: $score',
        'PlayerRepository.updatePlayerScore',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error updating player score: $playerId',
        e,
        stackTrace,
        'PlayerRepository.updatePlayerScore',
      );
      rethrow;
    }
  }

  // Update player answers
  Future<void> savePlayerAnswer(
    String playerId,
    String questionId,
    dynamic answer,
  ) async {
    try {
      _logger.logInfo(
        'Saving answer for player: $playerId, question: $questionId',
        'PlayerRepository.savePlayerAnswer',
      );
      await _playersCollection.doc(playerId).update({
        'answers.$questionId': answer,
      });
      _logger.logInfo(
        'Player answer saved: $playerId, question: $questionId',
        'PlayerRepository.savePlayerAnswer',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error saving player answer - Player: $playerId, Question: $questionId',
        e,
        stackTrace,
        'PlayerRepository.savePlayerAnswer',
      );
      rethrow;
    }
  }

  // Register player to a session
  Future<void> joinSession(String playerId, String sessionId) async {
    try {
      _logger.logInfo(
        'Player $playerId joining session: $sessionId',
        'PlayerRepository.joinSession',
      );
      await _playersCollection.doc(playerId).update({
        'currentSessionId': sessionId,
        'sessionHistory': FieldValue.arrayUnion([sessionId]),
      });
      _logger.logInfo(
        'Player $playerId joined session: $sessionId',
        'PlayerRepository.joinSession',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error joining session - Player: $playerId, Session: $sessionId',
        e,
        stackTrace,
        'PlayerRepository.joinSession',
      );
      rethrow;
    }
  }

  // Leave current session
  Future<void> leaveSession(String playerId) async {
    try {
      _logger.logInfo(
        'Player $playerId leaving current session',
        'PlayerRepository.leaveSession',
      );
      await _playersCollection.doc(playerId).update({'currentSessionId': null});
      _logger.logInfo(
        'Player $playerId left current session',
        'PlayerRepository.leaveSession',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error leaving session - Player: $playerId',
        e,
        stackTrace,
        'PlayerRepository.leaveSession',
      );
      rethrow;
    }
  }

  // Create a new anonymous player
  Future<Player> createAnonymousPlayer(
    String nickname, {
    String? avatarUrl,
    String? colorHex,
  }) async {
    try {
      _logger.logInfo(
        'Creating anonymous player with nickname: $nickname',
        'PlayerRepository.createAnonymousPlayer',
      );

      // Create a document with auto-generated ID
      DocumentReference docRef = _playersCollection.doc();

      Player newPlayer = Player(
        id: docRef.id,
        nickname: nickname,
        avatarUrl: avatarUrl,
        colorHex: colorHex ?? '#39FF14',
        score: 0,
      );

      await docRef.set(newPlayer.toFirestore());

      _logger.logInfo(
        'Anonymous player created: ${newPlayer.id}, nickname: $nickname',
        'PlayerRepository.createAnonymousPlayer',
      );

      return newPlayer;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error creating anonymous player with nickname: $nickname',
        e,
        stackTrace,
        'PlayerRepository.createAnonymousPlayer',
      );
      rethrow;
    }
  }
}
