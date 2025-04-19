import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizzed/models/player.dart';
import 'package:quizzed/models/question.dart';
import 'package:quizzed/models/quiz_session.dart';
import 'package:quizzed/services/logging_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LoggingService _logger = LoggingService();

  // Collection references
  final CollectionReference quizSessions = FirebaseFirestore.instance
      .collection('quiz_sessions');
  final CollectionReference questions = FirebaseFirestore.instance.collection(
    'questions',
  );
  final CollectionReference players = FirebaseFirestore.instance.collection(
    'players',
  );

  // Initialize Firestore settings
  DatabaseService() {
    _initializeFirestore();
  }

  // Configure Firestore settings
  void _initializeFirestore() {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      _logger.logInfo(
        'Firestore configured with persistence enabled',
        'DatabaseService._initializeFirestore',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Failed to initialize Firestore settings',
        e,
        stackTrace,
        'DatabaseService._initializeFirestore',
      );
    }
  }

  // Create a new quiz session
  Future<DocumentReference> createQuizSession(
    Map<String, dynamic> sessionData,
  ) async {
    try {
      _logger.logInfo(
        'Creating quiz session: ${sessionData['title']}',
        'DatabaseService.createQuizSession',
      );
      final docRef = await quizSessions.add(sessionData);
      _logger.logInfo(
        'Quiz session created with ID: ${docRef.id}',
        'DatabaseService.createQuizSession',
      );
      return docRef;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error creating quiz session',
        e,
        stackTrace,
        'DatabaseService.createQuizSession',
      );
      throw e;
    }
  }

  // Create a session using QuizSession model
  Future<DocumentReference> createQuizSessionFromModel(
    QuizSession session,
  ) async {
    try {
      _logger.logInfo(
        'Creating quiz session from model: ${session.title}',
        'DatabaseService.createQuizSessionFromModel',
      );
      final docRef = await quizSessions.add(session.toFirestore());
      _logger.logInfo(
        'Quiz session created with ID: ${docRef.id}',
        'DatabaseService.createQuizSessionFromModel',
      );
      return docRef;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error creating quiz session from model',
        e,
        stackTrace,
        'DatabaseService.createQuizSessionFromModel',
      );
      throw e;
    }
  }

  // Get all quiz sessions
  Stream<QuerySnapshot> getQuizSessions() {
    _logger.logDebug(
      'Streaming all quiz sessions',
      'DatabaseService.getQuizSessions',
    );
    return quizSessions.orderBy('createdAt', descending: true).snapshots();
  }

  // Get a specific quiz session
  Stream<DocumentSnapshot> getQuizSession(String sessionId) {
    _logger.logDebug(
      'Streaming quiz session: $sessionId',
      'DatabaseService.getQuizSession',
    );
    return quizSessions.doc(sessionId).snapshots();
  }

  // Get active quiz sessions
  Stream<QuerySnapshot> getActiveQuizSessions() {
    _logger.logDebug(
      'Streaming active quiz sessions',
      'DatabaseService.getActiveQuizSessions',
    );
    return quizSessions
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update a quiz session
  Future<void> updateQuizSession(
    String sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      _logger.logInfo(
        'Updating quiz session: $sessionId',
        'DatabaseService.updateQuizSession',
      );
      await quizSessions.doc(sessionId).update(sessionData);
      _logger.logInfo(
        'Quiz session updated: $sessionId',
        'DatabaseService.updateQuizSession',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error updating quiz session: $sessionId',
        e,
        stackTrace,
        'DatabaseService.updateQuizSession',
      );
      throw e;
    }
  }

  // Delete a quiz session
  Future<void> deleteQuizSession(String sessionId) async {
    try {
      _logger.logInfo(
        'Deleting quiz session and related questions: $sessionId',
        'DatabaseService.deleteQuizSession',
      );
      // First, get all questions related to this session
      final questionsSnapshot =
          await questions.where('sessionId', isEqualTo: sessionId).get();

      // Delete each question in a batch
      final batch = _firestore.batch();
      for (var doc in questionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Also delete the session document
      batch.delete(quizSessions.doc(sessionId));

      // Commit the batch
      await batch.commit();
      _logger.logInfo(
        'Quiz session and ${questionsSnapshot.docs.length} questions deleted: $sessionId',
        'DatabaseService.deleteQuizSession',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error deleting quiz session: $sessionId',
        e,
        stackTrace,
        'DatabaseService.deleteQuizSession',
      );
      throw e;
    }
  }

  // Create a new question in a quiz session
  Future<DocumentReference> createQuestion(
    Map<String, dynamic> questionData,
  ) async {
    try {
      _logger.logInfo(
        'Creating question for session: ${questionData['sessionId']}',
        'DatabaseService.createQuestion',
      );
      final docRef = await questions.add(questionData);
      _logger.logInfo(
        'Question created with ID: ${docRef.id}',
        'DatabaseService.createQuestion',
      );
      return docRef;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error creating question',
        e,
        stackTrace,
        'DatabaseService.createQuestion',
      );
      throw e;
    }
  }

  // Create a question from Question model
  Future<DocumentReference> createQuestionFromModel(Question question) async {
    try {
      _logger.logInfo(
        'Creating question from model for session: ${question.sessionId}',
        'DatabaseService.createQuestionFromModel',
      );
      final docRef = await questions.add(question.toFirestore());
      _logger.logInfo(
        'Question created with ID: ${docRef.id}',
        'DatabaseService.createQuestionFromModel',
      );
      return docRef;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error creating question from model',
        e,
        stackTrace,
        'DatabaseService.createQuestionFromModel',
      );
      throw e;
    }
  }

  // Get all questions for a specific session
  Stream<QuerySnapshot> getSessionQuestions(String sessionId) {
    _logger.logDebug(
      'Streaming questions for session: $sessionId',
      'DatabaseService.getSessionQuestions',
    );
    return questions
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('order', descending: false)
        .snapshots();
  }

  // Get all questions for a specific session as a Future (one-time read)
  Future<List<Question>> getSessionQuestionsAsList(String sessionId) async {
    try {
      _logger.logInfo(
        'Fetching questions list for session: $sessionId',
        'DatabaseService.getSessionQuestionsAsList',
      );
      final snapshot =
          await questions
              .where('sessionId', isEqualTo: sessionId)
              .orderBy('order', descending: false)
              .get();

      final questionsList =
          snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
      _logger.logInfo(
        'Retrieved ${questionsList.length} questions for session: $sessionId',
        'DatabaseService.getSessionQuestionsAsList',
      );
      return questionsList;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error getting session questions as list for session: $sessionId',
        e,
        stackTrace,
        'DatabaseService.getSessionQuestionsAsList',
      );
      throw e;
    }
  }

  // Update a question
  Future<void> updateQuestion(
    String questionId,
    Map<String, dynamic> questionData,
  ) async {
    try {
      _logger.logInfo(
        'Updating question: $questionId',
        'DatabaseService.updateQuestion',
      );
      await questions.doc(questionId).update(questionData);
      _logger.logInfo(
        'Question updated: $questionId',
        'DatabaseService.updateQuestion',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error updating question: $questionId',
        e,
        stackTrace,
        'DatabaseService.updateQuestion',
      );
      throw e;
    }
  }

  // Delete a question
  Future<void> deleteQuestion(String questionId) async {
    try {
      _logger.logInfo(
        'Deleting question: $questionId',
        'DatabaseService.deleteQuestion',
      );
      await questions.doc(questionId).delete();
      _logger.logInfo(
        'Question deleted: $questionId',
        'DatabaseService.deleteQuestion',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error deleting question: $questionId',
        e,
        stackTrace,
        'DatabaseService.deleteQuestion',
      );
      throw e;
    }
  }

  // Register a player or update their data
  Future<void> upsertPlayer(
    String playerId,
    Map<String, dynamic> playerData,
  ) async {
    try {
      _logger.logInfo(
        'Upserting player: $playerId',
        'DatabaseService.upsertPlayer',
      );
      await players.doc(playerId).set(playerData, SetOptions(merge: true));
      _logger.logInfo(
        'Player upserted: $playerId',
        'DatabaseService.upsertPlayer',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error upserting player: $playerId',
        e,
        stackTrace,
        'DatabaseService.upsertPlayer',
      );
      throw e;
    }
  }

  // Register a player from Player model
  Future<void> upsertPlayerFromModel(Player player) async {
    try {
      _logger.logInfo(
        'Upserting player from model: ${player.id}',
        'DatabaseService.upsertPlayerFromModel',
      );
      await players
          .doc(player.id)
          .set(player.toFirestore(), SetOptions(merge: true));
      _logger.logInfo(
        'Player upserted from model: ${player.id}',
        'DatabaseService.upsertPlayerFromModel',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error upserting player from model: ${player.id}',
        e,
        stackTrace,
        'DatabaseService.upsertPlayerFromModel',
      );
      throw e;
    }
  }

  // Get all players
  Stream<QuerySnapshot> getPlayers() {
    _logger.logDebug('Streaming all players', 'DatabaseService.getPlayers');
    return players.snapshots();
  }

  // Get a specific player
  Stream<DocumentSnapshot> getPlayer(String playerId) {
    _logger.logDebug(
      'Streaming player: $playerId',
      'DatabaseService.getPlayer',
    );
    return players.doc(playerId).snapshots();
  }

  // Get a player as a Future (one-time read)
  Future<Player?> getPlayerById(String playerId) async {
    try {
      _logger.logInfo(
        'Fetching player by ID: $playerId',
        'DatabaseService.getPlayerById',
      );
      final doc = await players.doc(playerId).get();
      Player? player = doc.exists ? Player.fromFirestore(doc) : null;
      _logger.logInfo(
        'Player ${player != null ? "found" : "not found"}: $playerId',
        'DatabaseService.getPlayerById',
      );
      return player;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error getting player by ID: $playerId',
        e,
        stackTrace,
        'DatabaseService.getPlayerById',
      );
      throw e;
    }
  }

  // Get players in a specific session
  Stream<QuerySnapshot> getSessionPlayers(String sessionId) {
    _logger.logDebug(
      'Streaming players for session: $sessionId',
      'DatabaseService.getSessionPlayers',
    );
    return players
        .where('currentSessionId', isEqualTo: sessionId)
        .orderBy('score', descending: true)
        .snapshots();
  }

  // Record a player's answer
  Future<void> recordPlayerAnswer(
    String playerId,
    String questionId,
    dynamic answer,
  ) async {
    try {
      _logger.logInfo(
        'Recording answer for player: $playerId, question: $questionId',
        'DatabaseService.recordPlayerAnswer',
      );
      // Get current answers or create empty map
      DocumentSnapshot playerDoc = await players.doc(playerId).get();
      Map<String, dynamic> playerData =
          playerDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> answers =
          (playerData['answers'] ?? {}) as Map<String, dynamic>;

      // Add new answer
      answers[questionId] = answer;

      // Update player document
      await players.doc(playerId).update({'answers': answers});
      _logger.logInfo(
        'Answer recorded for player: $playerId, question: $questionId',
        'DatabaseService.recordPlayerAnswer',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error recording player answer - Player: $playerId, Question: $questionId',
        e,
        stackTrace,
        'DatabaseService.recordPlayerAnswer',
      );
      throw e;
    }
  }

  // Update player score
  Future<void> updatePlayerScore(String playerId, int scoreIncrement) async {
    try {
      _logger.logInfo(
        'Updating player score: $playerId, increment: $scoreIncrement',
        'DatabaseService.updatePlayerScore',
      );
      await players.doc(playerId).update({
        'score': FieldValue.increment(scoreIncrement),
      });
      _logger.logInfo(
        'Player score updated: $playerId, increment: $scoreIncrement',
        'DatabaseService.updatePlayerScore',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error updating player score: $playerId',
        e,
        stackTrace,
        'DatabaseService.updatePlayerScore',
      );
      throw e;
    }
  }

  // Manually award points to multiple players
  Future<void> awardPointsToPlayers(List<String> playerIds, int points) async {
    try {
      _logger.logInfo(
        'Awarding $points points to ${playerIds.length} players',
        'DatabaseService.awardPointsToPlayers',
      );
      WriteBatch batch = _firestore.batch();
      for (String playerId in playerIds) {
        batch.update(players.doc(playerId), {
          'score': FieldValue.increment(points),
        });
      }
      await batch.commit();
      _logger.logInfo(
        'Points awarded to ${playerIds.length} players',
        'DatabaseService.awardPointsToPlayers',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error awarding points to players',
        e,
        stackTrace,
        'DatabaseService.awardPointsToPlayers',
      );
      throw e;
    }
  }

  // Get current quiz session standings (players sorted by score)
  Future<List<Player>> getSessionStandings(String sessionId) async {
    try {
      _logger.logInfo(
        'Fetching standings for session: $sessionId',
        'DatabaseService.getSessionStandings',
      );
      final snapshot =
          await players
              .where('currentSessionId', isEqualTo: sessionId)
              .orderBy('score', descending: true)
              .get();

      final playersList =
          snapshot.docs.map((doc) => Player.fromFirestore(doc)).toList();
      _logger.logInfo(
        'Retrieved standings for ${playersList.length} players in session: $sessionId',
        'DatabaseService.getSessionStandings',
      );
      return playersList;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error getting session standings for session: $sessionId',
        e,
        stackTrace,
        'DatabaseService.getSessionStandings',
      );
      throw e;
    }
  }

  // Get players who have answered a specific question
  Future<List<Player>> getPlayersWhoAnswered(String questionId) async {
    try {
      _logger.logInfo(
        'Fetching players who answered question: $questionId',
        'DatabaseService.getPlayersWhoAnswered',
      );
      final snapshot =
          await players.where('answers.$questionId', isNull: false).get();

      final playersList =
          snapshot.docs.map((doc) => Player.fromFirestore(doc)).toList();
      _logger.logInfo(
        'Found ${playersList.length} players who answered question: $questionId',
        'DatabaseService.getPlayersWhoAnswered',
      );
      return playersList;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error getting players who answered question: $questionId',
        e,
        stackTrace,
        'DatabaseService.getPlayersWhoAnswered',
      );
      throw e;
    }
  }

  // Get the validation percentage for an open answer
  Future<int> getAnswerValidationPercentage(
    String questionId,
    String answer,
  ) async {
    try {
      _logger.logInfo(
        'Calculating validation percentage for question: $questionId',
        'DatabaseService.getAnswerValidationPercentage',
      );
      // Get all players who answered this question
      final snapshot =
          await players.where('answers.$questionId', isNull: false).get();

      if (snapshot.docs.isEmpty) {
        _logger.logInfo(
          'No answers found for question: $questionId',
          'DatabaseService.getAnswerValidationPercentage',
        );
        return 0;
      }

      int totalVotes = 0;
      int validationVotes = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> answers = data['answers'] as Map<String, dynamic>;

        if (answers[questionId] == answer) {
          validationVotes++;
        }
        totalVotes++;
      }

      final percentage = (validationVotes / totalVotes * 100).round();
      _logger.logInfo(
        'Validation percentage for question $questionId: $percentage% ($validationVotes/$totalVotes)',
        'DatabaseService.getAnswerValidationPercentage',
      );
      return percentage;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error calculating answer validation percentage for question: $questionId',
        e,
        stackTrace,
        'DatabaseService.getAnswerValidationPercentage',
      );
      return 0;
    }
  }
}
