/// Service de gestion des questions
///
/// Fournit les fonctionnalités pour interagir avec les questions dans Firestore
/// - Création, récupération, mise à jour et suppression de questions
/// - Gestion des réponses associées

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/models/quiz/question_model.dart';
import 'package:quizzzed/models/quiz/answer_model.dart';
import 'package:quizzzed/models/quiz/quiz_model.dart';
import 'package:quizzzed/services/firebase_service.dart';
import 'package:quizzzed/services/logger_service.dart';

class QuestionService extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();

  bool _isLoading = false;
  List<QuestionModel> _questions = [];

  // Getters
  bool get isLoading => _isLoading;
  List<QuestionModel> get questions => _questions;
  final logTag = 'QuestionService';
  final logger = LoggerService();
  // Obtenir toutes les questions d'un quiz
  Future<List<QuestionModel>> getQuizQuestions(String quizId) async {
    try {
      _isLoading = true;
      notifyListeners();

      logger.debug(
        'Récupération des questions pour le quiz $quizId',
        tag: logTag,
      );

      final snapshot =
          await _firebase.firestore
              .collection(AppConfig.questionsCollection)
              .where('quizId', isEqualTo: quizId)
              .orderBy('order')
              .get();

      _questions =
          snapshot.docs.map((doc) {
            try {
              Map<String, dynamic> data = doc.data();
              return QuestionModel.fromMap(data, doc.id);
            } catch (e) {
              logger.error(
                'Erreur lors du parsing de la question ${doc.id}',
                tag: logTag,
                data: e,
              );
              // Retourner une question "factice" en cas d'erreur pour ne pas bloquer l'application
              return QuestionModel(
                id: doc.id,
                text: 'Erreur de chargement de la question',
                quizId: quizId,
                type: QuestionType.multipleChoice,
                answers: [],
                points: 0,
              );
            }
          }).toList();

      logger.debug('${_questions.length} questions récupérées', tag: logTag);
      return _questions;
    } catch (e) {
      logger.error(
        'Erreur lors de la récupération des questions',
        tag: logTag,
        data: e,
      );
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter une nouvelle question à un quiz
  Future<QuestionModel?> addQuestion({
    required String quizId,
    required String text,
    required QuestionType type,
    required List<AnswerModel> answers,
    int points = 10,
    int? order,
    String? imageUrl,
    String? explanation,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Si l'ordre n'est pas spécifié, prendre le dernier ordre + 1
      if (order == null) {
        final questionsCount = await _getQuestionsCount(quizId);
        order = questionsCount;
      }

      // Créer une référence pour la nouvelle question
      final questionRef =
          _firebase.firestore.collection(AppConfig.questionsCollection).doc();

      // Générer des IDs pour les réponses
      final List<AnswerModel> answersWithIds =
          answers.asMap().entries.map((entry) {
            return entry.value.copyWith(
              id: '${questionRef.id}_answer_${entry.key}',
            );
          }).toList();

      // Créer la nouvelle question
      final question = QuestionModel(
        id: questionRef.id,
        quizId: quizId,
        text: text,
        type: type,
        answers: answersWithIds,
        points: points,
        order: order,
        imageUrl: imageUrl,
        explanation: explanation,
      );

      // Enregistrer la question dans Firestore
      await questionRef.set(question.toMap());

      // Mettre à jour le nombre de questions dans le document du quiz
      await _incrementQuestionCount(quizId);

      // Ajouter à la liste locale
      _questions.add(question);
      _sortQuestions();
      notifyListeners();

      return question;
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de l\'ajout de la question: $e',
        tag: logTag,
        data: stackTrace,
      );
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour une question existante
  Future<bool> updateQuestion(QuestionModel question) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Mettre à jour la question dans Firestore
      await _firebase.firestore
          .collection(AppConfig.questionsCollection)
          .doc(question.id)
          .update(question.toMap());

      // Mettre à jour dans la liste locale
      final index = _questions.indexWhere((q) => q.id == question.id);
      if (index >= 0) {
        _questions[index] = question;
        _sortQuestions();
        notifyListeners();
      }

      return true;
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la mise à jour de la question: $e',
        tag: logTag,
        data: stackTrace,
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Supprimer une question
  Future<bool> deleteQuestion(String questionId, String quizId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Supprimer la question
      await _firebase.firestore
          .collection(AppConfig.questionsCollection)
          .doc(questionId)
          .delete();

      // Décrémenter le nombre de questions dans le quiz
      await _decrementQuestionCount(quizId);

      // Mettre à jour l'ordre des questions
      final remainingQuestions =
          _questions.where((q) => q.id != questionId).toList();
      int order = 0;

      final batch = _firebase.firestore.batch();
      for (final question in remainingQuestions) {
        question.copyWith(order: order);
        batch.update(
          _firebase.firestore
              .collection(AppConfig.questionsCollection)
              .doc(question.id),
          {'order': order},
        );
        order++;
      }

      await batch.commit();

      // Mettre à jour la liste locale
      _questions.removeWhere((q) => q.id == questionId);
      _sortQuestions();
      notifyListeners();

      return true;
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la suppression de la question: $e',
        tag: logTag,
        data: stackTrace,
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Réorganiser l'ordre des questions
  Future<bool> reorderQuestions(List<String> questionIds) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Créer un lot (batch) de mises à jour
      final batch = _firebase.firestore.batch();

      // Mettre à jour l'ordre de chaque question
      for (int i = 0; i < questionIds.length; i++) {
        batch.update(
          _firebase.firestore
              .collection(AppConfig.questionsCollection)
              .doc(questionIds[i]),
          {'order': i},
        );
      }

      await batch.commit();

      // Mettre à jour les ordres dans la liste locale
      for (int i = 0; i < questionIds.length; i++) {
        final index = _questions.indexWhere((q) => q.id == questionIds[i]);
        if (index >= 0) {
          _questions[index] = _questions[index].copyWith(order: i);
        }
      }

      _sortQuestions();
      notifyListeners();

      return true;
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la réorganisation des questions: $e',
        tag: logTag,
        data: stackTrace,
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Incrémenter le nombre de questions dans un quiz
  Future<void> _incrementQuestionCount(String quizId) async {
    await _firebase.firestore
        .collection(AppConfig.quizzesCollection)
        .doc(quizId)
        .update({
          'questionCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Décrémenter le nombre de questions dans un quiz
  Future<void> _decrementQuestionCount(String quizId) async {
    await _firebase.firestore
        .collection(AppConfig.quizzesCollection)
        .doc(quizId)
        .update({
          'questionCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Obtenir le nombre de questions pour un quiz
  Future<int> _getQuestionsCount(String quizId) async {
    try {
      final doc =
          await _firebase.firestore
              .collection(AppConfig.quizzesCollection)
              .doc(quizId)
              .get();

      if (!doc.exists || doc.data() == null) {
        return 0;
      }

      final quiz = QuizModel.fromMap(doc.data()!, doc.id);
      return quiz.questionCount;
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la récupération du nombre de questions: $e',
        tag: logTag,
        data: stackTrace,
      );
      return 0;
    }
  }

  // Trier les questions par ordre
  void _sortQuestions() {
    _questions.sort((a, b) => a.order.compareTo(b.order));
  }
}
