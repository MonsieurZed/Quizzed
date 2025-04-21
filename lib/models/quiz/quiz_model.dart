/// Modèle de quiz
///
/// Représente les informations de base d'un quiz
library;

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String? imageUrl;
  final String category;
  final String difficulty;
  final int questionCount; // Nombre de questions à poser (0 = toutes)
  final bool isPublic;
  final int timeLimit; // Temps limite en minutes (0 = pas de limite)
  final bool randomizeQuestions;
  final bool randomizeAnswers;
  final DateTime createdAt;
  final DateTime? updatedAt;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    this.imageUrl,
    required this.category,
    required this.difficulty,
    this.questionCount = 0,
    this.isPublic = true,
    this.timeLimit = 0,
    this.randomizeQuestions = false,
    this.randomizeAnswers = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory QuizModel.fromMap(Map<String, dynamic> map, String id) {
    return QuizModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      creatorId: map['creatorId'] ?? '',
      imageUrl: map['imageUrl'],
      category: map['category'] ?? 'Général',
      difficulty: map['difficulty'] ?? 'Intermédiaire',
      questionCount: map['questionCount'] ?? 0,
      isPublic: map['isPublic'] ?? true,
      timeLimit: map['timeLimit'] ?? 0,
      randomizeQuestions: map['randomizeQuestions'] ?? false,
      randomizeAnswers: map['randomizeAnswers'] ?? false,
      createdAt:
          map['createdAt'] != null
              ? (map['createdAt'] as dynamic).toDate()
              : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null
              ? (map['updatedAt'] as dynamic).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'imageUrl': imageUrl,
      'category': category,
      'difficulty': difficulty,
      'questionCount': questionCount,
      'isPublic': isPublic,
      'timeLimit': timeLimit,
      'randomizeQuestions': randomizeQuestions,
      'randomizeAnswers': randomizeAnswers,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    String? creatorId,
    String? imageUrl,
    String? category,
    String? difficulty,
    int? questionCount,
    bool? isPublic,
    int? timeLimit,
    bool? randomizeQuestions,
    bool? randomizeAnswers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      questionCount: questionCount ?? this.questionCount,
      isPublic: isPublic ?? this.isPublic,
      timeLimit: timeLimit ?? this.timeLimit,
      randomizeQuestions: randomizeQuestions ?? this.randomizeQuestions,
      randomizeAnswers: randomizeAnswers ?? this.randomizeAnswers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
