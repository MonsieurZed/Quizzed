/// Widget de carte d'activité récente/populaire
///
/// Affiche les informations d'un quiz populaire ou récent
/// avec son titre, sa catégorie, sa difficulté et le nombre de participants

import 'package:flutter/material.dart';

class RecentActivityCard extends StatelessWidget {
  final String title;
  final String category;
  final int participants;
  final int difficulty; // 1-5, 5 étant le plus difficile
  final VoidCallback? onTap;

  const RecentActivityCard({
    super.key,
    required this.title,
    required this.category,
    required this.participants,
    required this.difficulty,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image ou icône de la catégorie
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                    category,
                  ).withAlpha((255 * 0.2).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Informations du quiz
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre du quiz
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Catégorie
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 14,
                          color: theme.colorScheme.onSurface.withAlpha(
                            (255 * 0.7).toInt(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(
                              (255 * 0.7).toInt(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Rang de difficulté et participants
                    Row(
                      children: [
                        // Niveau de difficulté
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < difficulty
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color:
                                  index < difficulty
                                      ? Colors.amber
                                      : theme.colorScheme.onSurface.withOpacity(
                                        0.4,
                                      ),
                            );
                          }),
                        ),
                        const Spacer(),

                        // Nombre de participants
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: theme.colorScheme.onSurface.withAlpha(
                            (255 * 0.7).toInt(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatParticipants(participants),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(
                              (255 * 0.7).toInt(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Formater le nombre de participants (ex: 1,245 ou 2.4k)
  String _formatParticipants(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 10000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else {
      return '${(count / 1000).toStringAsFixed(0)}k';
    }
  }

  // Obtenir l'icône correspondante à la catégorie
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'histoire':
        return Icons.history_edu;
      case 'sciences':
        return Icons.science;
      case 'géographie':
        return Icons.public;
      case 'culture':
        return Icons.theater_comedy;
      case 'sport':
        return Icons.sports_soccer;
      case 'musique':
        return Icons.music_note;
      case 'cinéma':
        return Icons.movie;
      case 'littérature':
        return Icons.book;
      default:
        return Icons.quiz;
    }
  }

  // Obtenir la couleur correspondante à la catégorie
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'histoire':
        return const Color(0xFFFF6B6B);
      case 'sciences':
        return const Color(0xFF4ECDC4);
      case 'géographie':
        return const Color(0xFFFFD166);
      case 'culture':
        return const Color(0xFF6A0572);
      case 'sport':
        return const Color(0xFF118AB2);
      case 'musique':
        return const Color(0xFF7209B7);
      case 'cinéma':
        return const Color(0xFF99582A);
      case 'littérature':
        return const Color(0xFF457B9D);
      default:
        return Colors.blueGrey;
    }
  }
}
