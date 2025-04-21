// filepath: d:\GIT\quizzzed\lib\widgets\home\quiz_card.dart
/// Widget de carte de quiz
///
/// Affiche un quiz avec son titre, sa description, sa catégorie et sa difficulté
/// Utilisé dans la liste des quiz par catégorie
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/models/quiz/quiz_model.dart';

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback onTap;

  const QuizCard({super.key, required this.quiz, required this.onTap});

  Color _getDifficultyColor(BuildContext context, String difficulty) {
    final theme = Theme.of(context);

    switch (difficulty.toLowerCase()) {
      case 'facile':
        return Colors.green;
      case 'intermédiaire':
        return Colors.orange;
      case 'difficile':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'science':
        return Icons.science;
      case 'histoire':
        return Icons.history_edu;
      case 'géographie':
        return Icons.public;
      case 'sport':
        return Icons.sports;
      case 'art':
        return Icons.palette;
      case 'cinéma':
        return Icons.movie;
      case 'musique':
        return Icons.music_note;
      case 'littérature':
        return Icons.book;
      case 'technologie':
        return Icons.computer;
      default:
        return Icons.lightbulb;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficultyColor = _getDifficultyColor(context, quiz.difficulty);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image ou container coloré en haut de la carte
            quiz.imageUrl != null
                ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    quiz.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _getCategoryIcon(quiz.category),
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                  ),
                )
                : Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(quiz.category),
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),

            // Contenu de la carte
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre du quiz
                  Text(
                    quiz.title,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Description du quiz
                  Text(
                    quiz.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Ligne d'informations en bas
                  Row(
                    children: [
                      // Catégorie
                      Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        avatar: Icon(
                          _getCategoryIcon(quiz.category),
                          size: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                        label: Text(
                          quiz.category,
                          style: theme.textTheme.bodySmall,
                        ),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      const SizedBox(width: 8),

                      // Difficulté
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: difficultyColor.withAlpha((255 * 0.1).toInt()),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: difficultyColor, width: 1),
                        ),
                        child: Text(
                          quiz.difficulty,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: difficultyColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Temps limite
                      if (quiz.timeLimit > 0) ...[
                        const Icon(Icons.timer, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "${quiz.timeLimit} min",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
