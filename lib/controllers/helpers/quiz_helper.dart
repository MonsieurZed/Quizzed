/// Helper pour la gestion des quiz et questions
///
/// Cette classe contient des méthodes utilitaires pour manipuler
/// les quiz et questions de manière cohérente dans l'application.
/// Elle fournit des abstractions pour les patterns récurrents.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/models/quiz/quiz_model.dart';
import 'package:quizzzed/models/quiz/question_model.dart';
import 'package:quizzzed/services/logger_service.dart';

/// Helper pour les opérations liées aux quiz
class QuizHelper {
  final CollectionReference quizzesRef;
  final LoggerService logger;
  final String logTag;

  /// Constructeur du helper
  QuizHelper({
    required this.quizzesRef,
    required this.logger,
    required this.logTag,
  });

  /// Récupère un quiz par son ID
  ///
  /// Renvoie le quiz et un code d'erreur si la récupération échoue
  Future<(QuizModel?, ErrorCode?)> fetchQuizById(String quizId) async {
    try {
      logger.debug('Fetching quiz with ID: $quizId', tag: logTag);

      final docSnapshot = await quizzesRef.doc(quizId).get();

      if (!docSnapshot.exists) {
        logger.warning('Quiz not found: $quizId', tag: logTag);
        return (null, ErrorCode.quizNotFound);
      }

      final quizData = docSnapshot.data() as Map<String, dynamic>;
      final quizModel = QuizModel.fromMap(quizData, docSnapshot.id);

      return (quizModel, null);
    } catch (e) {
      logger.error('Error fetching quiz $quizId: $e', tag: logTag);
      return (null, ErrorCode.firebaseError);
    }
  }

  /// Récupère les questions d'un quiz
  Future<(List<QuestionModel>, ErrorCode?)> fetchQuestionsForQuiz(
    String quizId,
  ) async {
    try {
      logger.debug('Fetching questions for quiz: $quizId', tag: logTag);

      final questionsCollection = quizzesRef
          .doc(quizId)
          .collection('questions');
      final snapshot = await questionsCollection.orderBy('order').get();

      if (snapshot.docs.isEmpty) {
        logger.warning('No questions found for quiz $quizId', tag: logTag);
        return (<QuestionModel>[], ErrorCode.noQuestionsInQuiz);
      }

      final questions =
          snapshot.docs
              .map((doc) => QuestionModel.fromMap(doc.data(), doc.id))
              .toList();

      logger.debug(
        'Fetched ${questions.length} questions for quiz $quizId',
        tag: logTag,
      );
      return (questions, null);
    } catch (e) {
      logger.error(
        'Error fetching questions for quiz $quizId: $e',
        tag: logTag,
      );
      return (<QuestionModel>[], ErrorCode.firebaseError);
    }
  }

  /// Vérifie si un quiz a des questions
  Future<(bool, ErrorCode?)> verifyQuizHasQuestions(String quizId) async {
    try {
      final questionsCollection = quizzesRef
          .doc(quizId)
          .collection('questions');
      final snapshot = await questionsCollection.limit(1).get();

      final hasQuestions = snapshot.docs.isNotEmpty;

      if (!hasQuestions) {
        logger.warning('Quiz $quizId has no questions', tag: logTag);
        return (false, ErrorCode.noQuestionsInQuiz);
      }

      return (true, null);
    } catch (e) {
      logger.error(
        'Error verifying questions for quiz $quizId: $e',
        tag: logTag,
      );
      return (false, ErrorCode.firebaseError);
    }
  }

  /// Récupère une question spécifique d'un quiz
  Future<(QuestionModel?, ErrorCode?)> fetchQuestionById(
    String quizId,
    String questionId,
  ) async {
    try {
      logger.debug(
        'Fetching question $questionId for quiz $quizId',
        tag: logTag,
      );

      final questionDoc =
          await quizzesRef
              .doc(quizId)
              .collection('questions')
              .doc(questionId)
              .get();

      if (!questionDoc.exists) {
        logger.warning(
          'Question $questionId not found in quiz $quizId',
          tag: logTag,
        );
        return (null, ErrorCode.questionNotFound);
      }

      final questionData = questionDoc.data() as Map<String, dynamic>;
      final questionModel = QuestionModel.fromMap(questionData, questionDoc.id);

      return (questionModel, null);
    } catch (e) {
      logger.error(
        'Error fetching question $questionId for quiz $quizId: $e',
        tag: logTag,
      );
      return (null, ErrorCode.firebaseError);
    }
  }

  /// Vérifie si une réponse est correcte pour une question donnée
  Future<(bool, bool, ErrorCode?)> verifyAnswer(
    String quizId,
    String questionId,
    String answerId,
  ) async {
    try {
      logger.debug(
        'Verifying answer $answerId for question $questionId in quiz $quizId',
        tag: logTag,
      );

      final (question, errorCode) = await fetchQuestionById(quizId, questionId);

      if (errorCode != null) {
        return (false, false, errorCode);
      }

      // Vérifier si l'ID de réponse existe dans la question
      final answerExists = question!.answers.any(
        (answer) => answer.id == answerId,
      );

      if (!answerExists) {
        logger.warning(
          'Answer $answerId not found in question $questionId',
          tag: logTag,
        );
        return (false, false, ErrorCode.answerNotFound);
      }

      // Trouver la réponse et déterminer si elle est correcte
      final answer = question.answers.firstWhere((a) => a.id == answerId);
      final isCorrect = answer.isCorrect;

      logger.debug(
        'Answer $answerId for question $questionId is ${isCorrect ? 'correct' : 'incorrect'}',
        tag: logTag,
      );

      return (true, isCorrect, null);
    } catch (e) {
      logger.error(
        'Error verifying answer $answerId for question $questionId: $e',
        tag: logTag,
      );
      return (false, false, ErrorCode.firebaseError);
    }
  }

  /// Calcule le temps restant pour répondre à une question
  int calculateRemainingTime(DateTime startTime, int timeLimit) {
    final now = DateTime.now();
    final elapsedSeconds = now.difference(startTime).inSeconds;
    final remainingSeconds = timeLimit - elapsedSeconds;

    return remainingSeconds > 0 ? remainingSeconds : 0;
  }

  /// Calcule le score d'une réponse en fonction du temps restant
  int calculateScore(bool isCorrect, int remainingTime, int maxScore) {
    if (!isCorrect) return 0;

    // Le score est proportionnel au temps restant
    // Si le temps est écoulé, le score est 0
    if (remainingTime <= 0) return 0;

    // Calculer le score en fonction du temps restant
    return (maxScore * remainingTime / 100).round();
  }
}
