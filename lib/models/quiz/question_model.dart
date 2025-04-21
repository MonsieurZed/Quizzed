/// Modèle de question
///
/// Représente une question dans un quiz avec son texte et ses options de réponse
library;

import 'package:quizzzed/models/quiz/answer_model.dart';

enum QuestionType {
  multipleChoice, // Choix multiple avec une seule bonne réponse
  multipleAnswer, // Choix multiple avec plusieurs bonnes réponses
  trueFalse, // Vrai ou faux
  shortAnswer, // Réponse courte textuelle
}

class QuestionModel {
  final String id;
  final String text;
  final String quizId;
  final QuestionType type;
  final List<AnswerModel> answers;
  final String? imageUrl;
  final int points;
  final String? explanation; // Explication affichée après réponse
  final int
  order; // Position de la question dans le quiz (pour l'ordre d'affichage)

  QuestionModel({
    required this.id,
    required this.text,
    required this.quizId,
    required this.type,
    required this.answers,
    this.imageUrl,
    required this.points,
    this.explanation,
    this.order = 0, // Valeur par défaut
  });

  // Constructeur de copie avec modification
  QuestionModel copyWith({
    String? id,
    String? text,
    String? quizId,
    QuestionType? type,
    List<AnswerModel>? answers,
    String? imageUrl,
    int? points,
    String? explanation,
    int? order,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      quizId: quizId ?? this.quizId,
      type: type ?? this.type,
      answers: answers ?? this.answers,
      imageUrl: imageUrl ?? this.imageUrl,
      points: points ?? this.points,
      explanation: explanation ?? this.explanation,
      order: order ?? this.order,
    );
  }

  // Conversion depuis Map (Firestore)
  factory QuestionModel.fromMap(Map<String, dynamic> map, String id) {
    return QuestionModel(
      id: id,
      text: map['text'] ?? '',
      quizId: map['quizId'] ?? '',
      type: _parseQuestionType(map['type'] ?? 'multipleChoice'),
      answers: _parseAnswers(map['answers'] ?? []),
      imageUrl: map['imageUrl'],
      points: map['points'] ?? 10,
      explanation: map['explanation'],
      order: map['order'] ?? 0,
    );
  }

  // Conversion du type de question depuis la chaîne
  static QuestionType _parseQuestionType(String typeStr) {
    switch (typeStr) {
      case 'multipleAnswer':
        return QuestionType.multipleAnswer;
      case 'trueFalse':
        return QuestionType.trueFalse;
      case 'shortAnswer':
        return QuestionType.shortAnswer;
      case 'multipleChoice':
      default:
        return QuestionType.multipleChoice;
    }
  }

  // Conversion du type de question vers la chaîne
  String get typeString {
    switch (type) {
      case QuestionType.multipleAnswer:
        return 'multipleAnswer';
      case QuestionType.trueFalse:
        return 'trueFalse';
      case QuestionType.shortAnswer:
        return 'shortAnswer';
      case QuestionType.multipleChoice:
        return 'multipleChoice';
    }
  }

  // Conversion des réponses depuis la liste de maps
  static List<AnswerModel> _parseAnswers(List<dynamic> answers) {
    return answers.map((answer) => AnswerModel.fromMap(answer)).toList();
  }

  // Conversion vers Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'quizId': quizId,
      'type': typeString,
      'answers': answers.map((a) => a.toMap()).toList(),
      'imageUrl': imageUrl,
      'points': points,
      'explanation': explanation,
      'order': order,
    };
  }

  // Obtenir toutes les réponses correctes
  List<AnswerModel> get correctAnswers {
    return answers.where((answer) => answer.isCorrect).toList();
  }

  // Vérifier si la question a au moins une réponse correcte
  bool get hasCorrectAnswer {
    return answers.any((answer) => answer.isCorrect);
  }

  // Obtenir le texte pour l'interface utilisateur en fonction du type de question
  String get typeLabel {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Choix unique';
      case QuestionType.multipleAnswer:
        return 'Choix multiples';
      case QuestionType.trueFalse:
        return 'Vrai ou faux';
      case QuestionType.shortAnswer:
        return 'Réponse courte';
    }
  }

  @override
  String toString() {
    return 'QuestionModel(id: $id, text: $text, type: $typeString, order: $order)';
  }
}
