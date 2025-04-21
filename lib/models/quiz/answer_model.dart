/// Modèle de réponse
///
/// Représente une option de réponse à une question dans un quiz

class AnswerModel {
  final String id;
  final String text;
  final bool isCorrect;
  final String? explanation; // Explication de la réponse si nécessaire

  const AnswerModel({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.explanation,
  });

  // Constructeur de copie avec modification
  AnswerModel copyWith({
    String? text,
    bool? isCorrect,
    String? explanation,
    required String id,
  }) {
    return AnswerModel(
      id: id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
      explanation: explanation ?? this.explanation,
    );
  }

  // Conversion depuis Map (Firestore)
  factory AnswerModel.fromMap(Map<String, dynamic> map) {
    return AnswerModel(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
      explanation: map['explanation'],
    );
  }

  // Conversion vers Map (Firestore)
  Map<String, dynamic> toMap() {
    return {'text': text, 'isCorrect': isCorrect, 'explanation': explanation};
  }

  @override
  String toString() {
    return 'AnswerModel(text: $text, isCorrect: $isCorrect)';
  }
}
