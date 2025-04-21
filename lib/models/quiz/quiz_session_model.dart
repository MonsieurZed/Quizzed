/// Modèle de session de quiz
///
/// Représente une session active d'un quiz en cours
/// Gère l'état actuel, les réponses données et le chronomètre
library;

import 'package:quizzzed/models/quiz/question_model.dart';
import 'package:quizzzed/models/quiz/quiz_model.dart';

class QuizSessionModel {
  final QuizModel quiz;
  final List<QuestionModel> questions;
  final int currentQuestionIndex;
  final Map<String, List<int>>
  userAnswers; // questionId -> liste des index de réponses
  final DateTime startTime;
  final DateTime? endTime;
  final int elapsedSeconds;
  final bool isCompleted;

  QuizSessionModel({
    required this.quiz,
    required this.questions,
    this.currentQuestionIndex = 0,
    Map<String, List<int>>? userAnswers,
    required this.startTime,
    this.endTime,
    this.elapsedSeconds = 0,
    this.isCompleted = false,
  }) : userAnswers = userAnswers ?? {};

  // Constructeur de copie avec modification
  QuizSessionModel copyWith({
    QuizModel? quiz,
    List<QuestionModel>? questions,
    int? currentQuestionIndex,
    Map<String, List<int>>? userAnswers,
    DateTime? startTime,
    DateTime? endTime,
    int? elapsedSeconds,
    bool? isCompleted,
  }) {
    return QuizSessionModel(
      quiz: quiz ?? this.quiz,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? Map.from(this.userAnswers),
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Getters utiles
  bool get isFirstQuestion => currentQuestionIndex == 0;
  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;
  QuestionModel get currentQuestion => questions[currentQuestionIndex];

  // Vérifier si une question a déjà été répondue
  bool isQuestionAnswered(String questionId) {
    return userAnswers.containsKey(questionId) &&
        userAnswers[questionId]!.isNotEmpty;
  }

  // Vérifier si la question actuelle a été répondue
  bool get isCurrentQuestionAnswered {
    return isQuestionAnswered(currentQuestion.id);
  }

  // Enregistrer une réponse utilisateur (pour QCM à réponse unique)
  QuizSessionModel answerCurrentQuestion(int answerIndex) {
    Map<String, List<int>> newAnswers = Map.from(userAnswers);
    newAnswers[currentQuestion.id] = [answerIndex];

    return copyWith(userAnswers: newAnswers);
  }

  // Enregistrer plusieurs réponses utilisateur (pour QCM à réponses multiples)
  QuizSessionModel answerCurrentQuestionMultiple(List<int> answerIndexes) {
    Map<String, List<int>> newAnswers = Map.from(userAnswers);
    newAnswers[currentQuestion.id] = answerIndexes;

    return copyWith(userAnswers: newAnswers);
  }

  // Naviguer vers la question suivante
  QuizSessionModel goToNextQuestion() {
    if (isLastQuestion) return this;
    return copyWith(currentQuestionIndex: currentQuestionIndex + 1);
  }

  // Naviguer vers la question précédente
  QuizSessionModel goToPreviousQuestion() {
    if (isFirstQuestion) return this;
    return copyWith(currentQuestionIndex: currentQuestionIndex - 1);
  }

  // Naviguer vers une question spécifique
  QuizSessionModel goToQuestion(int index) {
    if (index < 0 || index >= questions.length) return this;
    return copyWith(currentQuestionIndex: index);
  }

  // Mettre à jour le temps écoulé
  QuizSessionModel updateElapsedTime(int seconds) {
    return copyWith(elapsedSeconds: seconds);
  }

  // Terminer le quiz
  QuizSessionModel completeQuiz() {
    return copyWith(endTime: DateTime.now(), isCompleted: true);
  }

  // Calculer le score actuel
  int calculateScore() {
    int totalScore = 0;

    for (var question in questions) {
      if (isQuestionAnswered(question.id)) {
        List<int> selectedIndexes = userAnswers[question.id] ?? [];

        switch (question.type) {
          case QuestionType.multipleChoice:
          case QuestionType.trueFalse:
            // Une seule bonne réponse attendue
            if (selectedIndexes.length == 1) {
              int index = selectedIndexes.first;
              if (index < question.answers.length &&
                  question.answers[index].isCorrect) {
                totalScore += question.points;
              }
            }
            break;

          case QuestionType.multipleAnswer:
            // Toutes les bonnes réponses doivent être sélectionnées
            List<int> correctIndexes = [];

            for (int i = 0; i < question.answers.length; i++) {
              if (question.answers[i].isCorrect) {
                correctIndexes.add(i);
              }
            }

            if (selectedIndexes.length == correctIndexes.length &&
                selectedIndexes.every(
                  (index) => correctIndexes.contains(index),
                )) {
              totalScore += question.points;
            }
            break;

          case QuestionType.shortAnswer:
            // Comparaison de texte - non implémenté pour l'instant
            break;
        }
      }
    }

    return totalScore;
  }

  // Calculer le nombre de réponses correctes
  int calculateCorrectAnswersCount() {
    int count = 0;

    for (var question in questions) {
      if (isQuestionAnswered(question.id)) {
        List<int> selectedIndexes = userAnswers[question.id] ?? [];
        bool isCorrect = false;

        switch (question.type) {
          case QuestionType.multipleChoice:
          case QuestionType.trueFalse:
            if (selectedIndexes.length == 1) {
              int index = selectedIndexes.first;
              if (index < question.answers.length &&
                  question.answers[index].isCorrect) {
                isCorrect = true;
              }
            }
            break;

          case QuestionType.multipleAnswer:
            List<int> correctIndexes = [];

            for (int i = 0; i < question.answers.length; i++) {
              if (question.answers[i].isCorrect) {
                correctIndexes.add(i);
              }
            }

            if (selectedIndexes.length == correctIndexes.length &&
                selectedIndexes.every(
                  (index) => correctIndexes.contains(index),
                )) {
              isCorrect = true;
            }
            break;

          case QuestionType.shortAnswer:
            // Comparaison de texte - non implémenté pour l'instant
            break;
        }

        if (isCorrect) {
          count++;
        }
      }
    }

    return count;
  }

  // Calculer le score maximum possible
  int calculateMaxScore() {
    return questions.fold(0, (sum, question) => sum + question.points);
  }

  // Pourcentage de progression dans le quiz
  double get progressPercentage {
    if (questions.isEmpty) return 0.0;
    return (currentQuestionIndex + 1) / questions.length;
  }

  // Nombre de questions répondues
  int get answeredQuestionsCount {
    return userAnswers.keys.length;
  }

  // Pourcentage de questions répondues
  double get answeredQuestionsPercentage {
    if (questions.isEmpty) return 0.0;
    return answeredQuestionsCount / questions.length;
  }
}
