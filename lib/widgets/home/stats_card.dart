/// Widget d'affichage des statistiques utilisateur
///
/// Carte affichant les statistiques principales de l'utilisateur
/// comme son score et le nombre de quiz complétés

import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final int score;
  final int quizCompleted;

  const StatsCard({
    super.key,
    required this.score,
    required this.quizCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Score
            Expanded(
              child: _buildStatItem(
                context,
                Icons.stars_rounded,
                score.toString(),
                'Points',
                Colors.amber,
              ),
            ),

            // Séparateur vertical
            Container(
              height: 40,
              width: 1,
              color: theme.colorScheme.outline.withAlpha((255 * 0.3).toInt()),
            ),

            // Quiz complétés
            Expanded(
              child: _buildStatItem(
                context,
                Icons.check_circle_outline,
                quizCompleted.toString(),
                'Quiz complétés',
                theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withAlpha((255 * 0.7).toInt()),
          ),
        ),
      ],
    );
  }
}
