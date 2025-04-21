/// Service de gestion des scores
///
/// Gère l'enregistrement des scores et la récupération des classements
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/models/quiz/score_model.dart';
import 'package:quizzzed/services/firebase_service.dart';
import 'package:quizzzed/services/logger_service.dart';

class ScoreService extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();

  // Collections Firestore
  CollectionReference get _scoreCollection =>
      _firebase.firestore.collection(AppConfig.scoresCollection);

  // État du chargement
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final logTag = 'ScoreService';
  final logger = LoggerService();

  /// Sauvegarde un nouveau score
  Future<ScoreModel> saveScore(ScoreModel score) async {
    try {
      _isLoading = true;
      notifyListeners();

      DocumentReference docRef = await _scoreCollection.add(score.toMap());

      return score.copyWith(id: docRef.id);
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de l\'enregistrement du score: $e',
        tag: logTag,
        data: stackTrace,
      );
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère le meilleur score d'un utilisateur pour un quiz
  Future<ScoreModel?> getUserBestScore(String userId, String quizId) async {
    try {
      _isLoading = true;
      notifyListeners();

      QuerySnapshot snapshot =
          await _scoreCollection
              .where('userId', isEqualTo: userId)
              .where('quizId', isEqualTo: quizId)
              .orderBy('score', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      DocumentSnapshot doc = snapshot.docs.first;
      return ScoreModel.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la récupération du meilleur score: $e',
        tag: logTag,
        data: stackTrace,
      );
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère l'historique des scores d'un utilisateur
  Future<List<ScoreModel>> getUserScores(
    String userId, {
    int limit = 20,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      QuerySnapshot snapshot =
          await _scoreCollection
              .where('userId', isEqualTo: userId)
              .orderBy('completedAt', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs
          .map(
            (doc) => ScoreModel.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la récupération des scores de l\'utilisateur: $e',
        stackTrace: stackTrace,
      );
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère le classement global pour un quiz
  Future<List<ScoreModel>> getQuizLeaderboard(
    String quizId, {
    int limit = 10,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      QuerySnapshot snapshot =
          await _scoreCollection
              .where('quizId', isEqualTo: quizId)
              .orderBy('score', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs
          .map(
            (doc) => ScoreModel.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la récupération du classement: $e',
        tag: logTag,
        data: stackTrace,
      );
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les statistiques globales d'un utilisateur
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      QuerySnapshot snapshot =
          await _scoreCollection.where('userId', isEqualTo: userId).get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalQuizzes': 0,
          'totalScore': 0,
          'averageScore': 0.0,
          'bestScore': 0,
          'totalCorrectAnswers': 0,
          'totalQuestions': 0,
          'successRate': 0.0,
        };
      }

      List<ScoreModel> scores =
          snapshot.docs
              .map(
                (doc) => ScoreModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  id: doc.id,
                ),
              )
              .toList();

      // Calculer les statistiques globales
      int totalQuizzes = scores.length;
      int totalScore = scores.fold(0, (sum, score) => sum + score.score);
      double averageScore = totalQuizzes > 0 ? totalScore / totalQuizzes : 0.0;
      int bestScore =
          scores.isEmpty
              ? 0
              : scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
      int totalCorrectAnswers = scores.fold(
        0,
        (sum, score) => sum + score.correctAnswers,
      );
      int totalQuestions = scores.fold(
        0,
        (sum, score) => sum + score.totalQuestions,
      );
      double successRate =
          totalQuestions > 0
              ? (totalCorrectAnswers / totalQuestions) * 100
              : 0.0;

      return {
        'totalQuizzes': totalQuizzes,
        'totalScore': totalScore,
        'averageScore': averageScore,
        'bestScore': bestScore,
        'totalCorrectAnswers': totalCorrectAnswers,
        'totalQuestions': totalQuestions,
        'successRate': successRate,
      };
    } catch (e) {
      logger.error(
        'Erreur lors de la récupération des statistiques de l\'utilisateur: $e',
      );
      return {
        'totalQuizzes': 0,
        'totalScore': 0,
        'averageScore': 0.0,
        'bestScore': 0,
        'totalCorrectAnswers': 0,
        'totalQuestions': 0,
        'successRate': 0.0,
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les scores récents (global)
  Future<List<ScoreModel>> getRecentScores({int limit = 10}) async {
    try {
      _isLoading = true;
      notifyListeners();

      QuerySnapshot snapshot =
          await _scoreCollection
              .orderBy('completedAt', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs
          .map(
            (doc) => ScoreModel.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la récupération des scores récents: $e',
        tag: logTag,
        data: stackTrace,
      );
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calcule le rang d'un utilisateur dans le classement d'un quiz
  Future<int> getUserRankInQuiz(String userId, String quizId) async {
    try {
      // Récupérer d'abord le meilleur score de l'utilisateur
      ScoreModel? userBestScore = await getUserBestScore(userId, quizId);

      if (userBestScore == null) {
        return 0; // Non classé
      }

      // Compter combien de scores sont meilleurs que celui de l'utilisateur
      QuerySnapshot betterScores =
          await _scoreCollection
              .where('quizId', isEqualTo: quizId)
              .where('score', isGreaterThan: userBestScore.score)
              .get();

      // Le rang est le nombre de scores meilleurs + 1
      return betterScores.docs.length + 1;
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors du calcul du rang: $e',
        tag: logTag,
        data: stackTrace,
      );
      return 0;
    }
  }
}
