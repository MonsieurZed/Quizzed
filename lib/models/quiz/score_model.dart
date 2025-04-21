/// Modèle de score
///
/// Représente le résultat d'un utilisateur à un quiz

import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreModel {
  final String id;
  final String quizId;
  final String userId;
  final String quizTitle;
  final String userName;
  final int score;
  final int maxScore;
  final int timeSpentSec;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime completedAt;

  ScoreModel({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.quizTitle,
    required this.userName,
    required this.score,
    required this.maxScore,
    required this.timeSpentSec,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.completedAt,
  });

  // Constructeur de copie avec modification
  ScoreModel copyWith({
    String? id,
    String? quizId,
    String? userId,
    String? quizTitle,
    String? userName,
    int? score,
    int? maxScore,
    int? timeSpentSec,
    int? correctAnswers,
    int? totalQuestions,
    DateTime? completedAt,
  }) {
    return ScoreModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      userId: userId ?? this.userId,
      quizTitle: quizTitle ?? this.quizTitle,
      userName: userName ?? this.userName,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      timeSpentSec: timeSpentSec ?? this.timeSpentSec,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Conversion depuis Map (Firestore)
  factory ScoreModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return ScoreModel(
      id: id,
      quizId: map['quizId'] ?? '',
      userId: map['userId'] ?? '',
      quizTitle: map['quizTitle'] ?? '',
      userName: map['userName'] ?? '',
      score: map['score'] ?? 0,
      maxScore: map['maxScore'] ?? 0,
      timeSpentSec: map['timeSpentSec'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      completedAt:
          (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Conversion vers Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'userId': userId,
      'quizTitle': quizTitle,
      'userName': userName,
      'score': score,
      'maxScore': maxScore,
      'timeSpentSec': timeSpentSec,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  // Getter pour calculer le pourcentage de réussite
  double get successPercentage {
    if (maxScore <= 0) return 0;
    return (score / maxScore) * 100;
  }

  // Getter pour formater le temps passé en minutes et secondes
  String get formattedTimeSpent {
    int minutes = timeSpentSec ~/ 60;
    int seconds = timeSpentSec % 60;
    return '${minutes > 0 ? '$minutes min ' : ''}${seconds.toString().padLeft(2, '0')} sec';
  }

  @override
  String toString() {
    return 'ScoreModel(quizTitle: $quizTitle, score: $score/$maxScore, correctAnswers: $correctAnswers/$totalQuestions)';
  }
}
