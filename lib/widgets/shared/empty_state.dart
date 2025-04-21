// filepath: d:\GIT\quizzzed\lib\widgets\shared\empty_state.dart
/// Empty State
///
/// Widget pour afficher un état vide avec un message et une action optionnelle
/// Utilisé lorsqu'une liste ne contient aucun élément ou qu'une recherche ne donne pas de résultat

import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.sentiment_dissatisfied,
    this.actionText,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.secondary.withAlpha((255 * 0.7).toInt()),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(
                  (255 * 0.7).toInt(),
                ),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
