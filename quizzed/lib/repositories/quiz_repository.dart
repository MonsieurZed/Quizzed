import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizzed/models/question.dart';
import 'package:quizzed/models/quiz_session.dart';
import 'package:quizzed/services/database_service.dart';
import 'package:quizzed/services/logging_service.dart';

class QuizRepository {
  final DatabaseService _databaseService = DatabaseService();
  final LoggingService _logger = LoggingService();

  // Create a new quiz session
  Future<String> createQuizSession(QuizSession session) async {
    try {
      _logger.logInfo(
        'Creating quiz session: ${session.title}',
        'QuizRepository.createQuizSession',
      );
      final docRef = await _databaseService.createQuizSession(
        session.toFirestore(),
      );
      _logger.logInfo(
        'Quiz session created with ID: ${docRef.id}',
        'QuizRepository.createQuizSession',
      );
      return docRef.id;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error creating quiz session',
        e,
        stackTrace,
        'QuizRepository.createQuizSession',
      );
      rethrow;
    }
  }

  // Get all quiz sessions
  Stream<List<QuizSession>> getQuizSessions() {
    _logger.logDebug(
      'Streaming all quiz sessions',
      'QuizRepository.getQuizSessions',
    );
    return _databaseService.getQuizSessions().map((snapshot) {
      final sessions =
          snapshot.docs.map((doc) => QuizSession.fromFirestore(doc)).toList();
      _logger.logDebug(
        'Mapped ${sessions.length} quiz sessions from snapshot',
        'QuizRepository.getQuizSessions',
      );
      return sessions;
    });
  }

  // Get a specific quiz session
  Stream<QuizSession?> getQuizSession(String sessionId) {
    _logger.logDebug(
      'Streaming quiz session: $sessionId',
      'QuizRepository.getQuizSession',
    );
    return _databaseService.getQuizSession(sessionId).map((doc) {
      if (doc.exists) {
        _logger.logDebug(
          'Quiz session found: $sessionId',
          'QuizRepository.getQuizSession',
        );
        return QuizSession.fromFirestore(doc);
      }
      _logger.logWarning(
        'Quiz session not found: $sessionId',
        'QuizRepository.getQuizSession',
      );
      return null;
    });
  }

  // Update a quiz session
  Future<void> updateQuizSession(String sessionId, QuizSession session) async {
    try {
      _logger.logInfo(
        'Updating quiz session: $sessionId',
        'QuizRepository.updateQuizSession',
      );
      await _databaseService.updateQuizSession(
        sessionId,
        session.toFirestore(),
      );
      _logger.logInfo(
        'Quiz session updated: $sessionId',
        'QuizRepository.updateQuizSession',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error updating quiz session: $sessionId',
        e,
        stackTrace,
        'QuizRepository.updateQuizSession',
      );
      rethrow;
    }
  }

  // Delete a quiz session
  Future<void> deleteQuizSession(String sessionId) async {
    try {
      _logger.logInfo(
        'Deleting quiz session: $sessionId',
        'QuizRepository.deleteQuizSession',
      );
      await _databaseService.deleteQuizSession(sessionId);
      _logger.logInfo(
        'Quiz session deleted: $sessionId',
        'QuizRepository.deleteQuizSession',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error deleting quiz session: $sessionId',
        e,
        stackTrace,
        'QuizRepository.deleteQuizSession',
      );
      rethrow;
    }
  }

  // Create a new question
  Future<String> createQuestion(Question question) async {
    try {
      _logger.logInfo(
        'Creating question for session: ${question.sessionId}',
        'QuizRepository.createQuestion',
      );
      final docRef = await _databaseService.createQuestion(
        question.toFirestore(),
      );
      _logger.logInfo(
        'Question created with ID: ${docRef.id}',
        'QuizRepository.createQuestion',
      );
      return docRef.id;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error creating question',
        e,
        stackTrace,
        'QuizRepository.createQuestion',
      );
      rethrow;
    }
  }

  // Get all questions for a session
  Stream<List<Question>> getSessionQuestions(String sessionId) {
    _logger.logDebug(
      'Streaming questions for session: $sessionId',
      'QuizRepository.getSessionQuestions',
    );
    return _databaseService.getSessionQuestions(sessionId).map((snapshot) {
      final questions =
          snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
      _logger.logDebug(
        'Mapped ${questions.length} questions from snapshot',
        'QuizRepository.getSessionQuestions',
      );
      return questions;
    });
  }

  // Update a question
  Future<void> updateQuestion(String questionId, Question question) async {
    try {
      _logger.logInfo(
        'Updating question: $questionId',
        'QuizRepository.updateQuestion',
      );
      await _databaseService.updateQuestion(questionId, question.toFirestore());
      _logger.logInfo(
        'Question updated: $questionId',
        'QuizRepository.updateQuestion',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error updating question: $questionId',
        e,
        stackTrace,
        'QuizRepository.updateQuestion',
      );
      rethrow;
    }
  }

  // Delete a question
  Future<void> deleteQuestion(String questionId) async {
    try {
      _logger.logInfo(
        'Deleting question: $questionId',
        'QuizRepository.deleteQuestion',
      );
      await _databaseService.deleteQuestion(questionId);
      _logger.logInfo(
        'Question deleted: $questionId',
        'QuizRepository.deleteQuestion',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error deleting question: $questionId',
        e,
        stackTrace,
        'QuizRepository.deleteQuestion',
      );
      rethrow;
    }
  }

  // Create multiple questions at once
  Future<List<String>> createBulkQuestions(List<Question> questions) async {
    try {
      _logger.logInfo(
        'Creating ${questions.length} questions in bulk',
        'QuizRepository.createBulkQuestions',
      );
      List<String> questionIds = [];

      // Using a batch to insert multiple questions efficiently
      final batch = FirebaseFirestore.instance.batch();

      for (var question in questions) {
        final docRef = FirebaseFirestore.instance.collection('questions').doc();
        batch.set(docRef, question.toFirestore());
        questionIds.add(docRef.id);
      }

      await batch.commit();
      _logger.logInfo(
        '${questionIds.length} questions created in bulk',
        'QuizRepository.createBulkQuestions',
      );
      return questionIds;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error creating bulk questions',
        e,
        stackTrace,
        'QuizRepository.createBulkQuestions',
      );
      rethrow;
    }
  }

  // Get active quiz sessions only
  Stream<List<QuizSession>> getActiveQuizSessions() {
    _logger.logDebug(
      'Streaming active quiz sessions',
      'QuizRepository.getActiveQuizSessions',
    );
    return FirebaseFirestore.instance
        .collection('quiz_sessions')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final sessions =
              snapshot.docs
                  .map((doc) => QuizSession.fromFirestore(doc))
                  .toList();
          _logger.logDebug(
            'Mapped ${sessions.length} active quiz sessions from snapshot',
            'QuizRepository.getActiveQuizSessions',
          );
          return sessions;
        });
  }
}
