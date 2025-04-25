/// Service de gestion des quiz
///
/// Gère les opérations CRUD pour les quiz, questions et réponses
/// via Firebase Firestore
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/models/quiz/question_model.dart';
import 'package:quizzzed/models/quiz/quiz_model.dart';
import 'package:quizzzed/services/error_message_service.dart';
import 'package:quizzzed/services/firebase_service.dart';
import 'package:quizzzed/services/logger_service.dart';

class GameService extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  final ErrorMessageService _errorService = ErrorMessageService();

  // Collections Firestore
  CollectionReference get _quizCollection =>
      _firebase.firestore.collection(AppConfig.quizzesCollection);

  CollectionReference get _questionCollection =>
      _firebase.firestore.collection(AppConfig.questionsCollection);

  // État du chargement
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  final logTag = 'QuizService';
  final logger = LoggerService();

  // Méthode sécurisée pour mettre à jour l'état de chargement
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      // On utilise un Future.microtask pour s'assurer que notifyListeners() est appelé
      // après le cycle de construction actuel
      Future.microtask(() => notifyListeners());
    }
  }

  // Méthodes CRUD pour les Quiz

  /// Récupère un quiz par son ID
  Future<QuizModel?> getQuiz(String quizId) async {
    try {
      _setLoading(true);

      DocumentSnapshot doc = await _quizCollection.doc(quizId).get();

      if (doc.exists) {
        return QuizModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      throw Exception(
        _errorService.handleError(
          operation: 'récupération du quiz',
          tag: logTag,
          errorCode: ErrorCode.quizNotFound,
        ),
      );
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'récupération du quiz',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
        errorCode:
            e.toString().contains('not found')
                ? ErrorCode.quizNotFound
                : ErrorCode.operationFailed,
      );
      logger.error(errorMessage, tag: logTag, data: stackTrace);
      throw Exception(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// Récupère un quiz par son ID (alias de getQuiz pour compatibilité)
  Future<QuizModel?> getQuizById(String quizId) async {
    return getQuiz(quizId);
  }

  /// Récupère tous les quiz
  Future<List<QuizModel>> getAllQuizzes({
    String? category,
    String? creatorId,
    bool onlyPublic = true,
    int? limit,
    String? orderBy,
    bool descending = true,
  }) async {
    try {
      _setLoading(true);

      Query query = _quizCollection;

      // Filtres
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      if (creatorId != null) {
        query = query.where('creatorId', isEqualTo: creatorId);
      }

      if (onlyPublic) {
        query = query.where('isPublic', isEqualTo: true);
        query = query.where('isArchived', isEqualTo: false);
      }

      // Ordre
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      } else {
        query = query.orderBy('popularity', descending: true);
      }

      // Limite
      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) =>
                QuizModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'récupération des quiz',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
        errorCode: ErrorCode.operationFailed,
      );
      logger.error(errorMessage, tag: logTag, data: stackTrace);
      // Return empty list instead of throwing to avoid UI crashes
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Récupère les quiz par catégorie
  Future<List<QuizModel>> getQuizzesByCategory(
    String category, {
    int limit = 10,
  }) async {
    return getAllQuizzes(
      category: category,
      limit: limit,
      orderBy: 'popularity',
      descending: true,
    );
  }

  /// Récupère les quiz populaires
  Future<List<QuizModel>> getPopularQuizzes({int limit = 10}) async {
    return getAllQuizzes(limit: limit, orderBy: 'popularity', descending: true);
  }

  /// Récupère les quiz récents
  Future<List<QuizModel>> getRecentQuizzes({int limit = 10}) async {
    return getAllQuizzes(limit: limit, orderBy: 'createdAt', descending: true);
  }

  /// Récupère les quiz créés par l'utilisateur connecté
  Future<List<QuizModel>> getUserQuizzes(String userId) async {
    return getAllQuizzes(
      creatorId: userId,
      onlyPublic: false,
      orderBy: 'updatedAt',
      descending: true,
    );
  }

  /// Crée un nouveau quiz
  Future<QuizModel> createQuiz(QuizModel quiz) async {
    try {
      _setLoading(true);

      DocumentReference docRef = await _quizCollection.add(quiz.toMap());

      return quiz.copyWith(id: docRef.id);
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'création du quiz',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
        errorCode: ErrorCode.operationFailed,
      );
      logger.error(errorMessage, tag: logTag, data: stackTrace);
      throw Exception(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// Met à jour un quiz existant
  Future<void> updateQuiz(QuizModel quiz) async {
    try {
      _setLoading(true);
      await _quizCollection.doc(quiz.id).update(quiz.toMap());
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'mise à jour du quiz',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
        errorCode: ErrorCode.operationFailed,
      );
      logger.error(errorMessage, tag: logTag, data: stackTrace);
      throw Exception(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// Supprime un quiz
  Future<void> deleteQuiz(String quizId) async {
    try {
      _setLoading(true);
      await _quizCollection.doc(quizId).delete();
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'suppression du quiz',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
        errorCode: ErrorCode.operationFailed,
      );
      logger.error(errorMessage, tag: logTag, data: stackTrace);
      throw Exception(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// Incrémente la popularité d'un quiz
  Future<void> incrementPopularity(String quizId) async {
    try {
      await _quizCollection.doc(quizId).update({
        'popularity': FieldValue.increment(1),
      });
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'incrémentation de la popularité',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
        errorCode: ErrorCode.operationFailed,
      );
      logger.error(errorMessage, tag: logTag, data: stackTrace);
      // We don't throw here as this is a non-critical operation
    }
  }

  // Méthodes CRUD pour les Questions

  /// Récupère les questions d'un quiz
  Future<List<QuestionModel>> getQuizQuestions(String quizId) async {
    try {
      _setLoading(true);

      QuerySnapshot snapshot =
          await _questionCollection.where('quizId', isEqualTo: quizId).get();

      return snapshot.docs
          .map(
            (doc) => QuestionModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'récupération des questions',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
        errorCode: ErrorCode.operationFailed,
      );
      logger.error(errorMessage, tag: logTag, data: stackTrace);
      // Return empty list instead of throwing to avoid UI crashes
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Crée une nouvelle question
  Future<QuestionModel> createQuestion(QuestionModel question) async {
    try {
      _setLoading(true);

      DocumentReference docRef = await _questionCollection.add(
        question.toMap(),
      );

      // Ajouter l'ID de la question au quiz
      await _quizCollection.doc(question.quizId).update({
        'questionIds': FieldValue.arrayUnion([docRef.id]),
      });

      return question.copyWith(id: docRef.id);
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'création de la question',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
        errorCode: ErrorCode.operationFailed,
      );
      logger.error(errorMessage, tag: logTag, data: stackTrace);
      throw Exception(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// Met à jour une question existante
  Future<void> updateQuestion(QuestionModel question) async {
    try {
      _setLoading(true);

      await _questionCollection.doc(question.id).update(question.toMap());
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'mise à jour de la question',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
        errorCode: ErrorCode.operationFailed,
      );
      logger.error(errorMessage, tag: logTag, data: stackTrace);
      throw Exception(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// Supprime une question
  Future<void> deleteQuestion(QuestionModel question) async {
    try {
      _setLoading(true);

      WriteBatch batch = _firebase.firestore.batch();

      // Supprimer la question
      batch.delete(_questionCollection.doc(question.id));

      // Retirer l'ID de la question du quiz
      batch.update(_quizCollection.doc(question.quizId), {
        'questionIds': FieldValue.arrayRemove([question.id]),
      });

      await batch.commit();
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'suppression de la question',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
        errorCode: ErrorCode.operationFailed,
      );
      logger.error(errorMessage, tag: logTag, data: stackTrace);
      throw Exception(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Méthodes utilitaires

  /// Récupère les catégories disponibles
  Future<List<String>> getCategories() async {
    try {
      QuerySnapshot snapshot =
          await _quizCollection
              .where('isPublic', isEqualTo: true)
              .where('isArchived', isEqualTo: false)
              .get();

      Set<String> categories = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['category'] != null &&
            data['category'].toString().isNotEmpty) {
          categories.add(data['category']);
        }
      }

      return categories.toList()..sort();
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'récupération des catégories',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
        errorCode: ErrorCode.operationFailed,
      );
      logger.error(errorMessage, tag: logTag, data: stackTrace);
      return [];
    }
  }
}
