import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType {
  qcm, // Multiple choice
  image, // Question with image
  sound, // Question with sound
  video, // Question with video
  open, // Open-ended question
}

enum QuestionDifficulty { easy, medium, hard }

class Question {
  final String? id;
  final String sessionId;
  final String questionText;
  final QuestionType type;
  final String? mediaUrl;
  final List<String>? choices;
  final dynamic
  correctAnswer; // String for open, index or list of indices for QCM
  final int order;
  final QuestionDifficulty difficulty;
  final int points;
  final int timeLimit; // Time limit in seconds

  Question({
    this.id,
    required this.sessionId,
    required this.questionText,
    required this.type,
    this.mediaUrl,
    this.choices,
    this.correctAnswer,
    required this.order,
    required this.difficulty,
    this.points = 10,
    this.timeLimit = 30,
  });

  // Convert a Firestore document to a Question object
  factory Question.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Question(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      questionText: data['questionText'] ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == 'QuestionType.${data['type']}',
        orElse: () => QuestionType.qcm,
      ),
      mediaUrl: data['mediaUrl'],
      choices:
          data['choices'] != null ? List<String>.from(data['choices']) : null,
      correctAnswer: data['correctAnswer'],
      order: data['order'] ?? 0,
      difficulty: QuestionDifficulty.values.firstWhere(
        (e) => e.toString() == 'QuestionDifficulty.${data['difficulty']}',
        orElse: () => QuestionDifficulty.medium,
      ),
      points: data['points'] ?? 10,
      timeLimit: data['timeLimit'] ?? 30,
    );
  }

  // Convert a Question object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'questionText': questionText,
      'type': type.toString().split('.').last,
      'mediaUrl': mediaUrl,
      'choices': choices,
      'correctAnswer': correctAnswer,
      'order': order,
      'difficulty': difficulty.toString().split('.').last,
      'points': points,
      'timeLimit': timeLimit,
    };
  }
}
