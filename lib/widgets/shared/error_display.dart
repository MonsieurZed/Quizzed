// filepath: d:\GIT\quizzzed\lib\widgets\shared\error_display.dart
/// Error Display
///
/// Widget pour afficher un message d'erreur avec des options pour réessayer
/// ou revenir en arrière
library;

import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const ErrorDisplay({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onBack,
  });

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
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error.withAlpha((255 * 0.8).toInt()),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onBack != null)
                  OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Retour'),
                  ),
                if (onBack != null && onRetry != null)
                  const SizedBox(width: 16),
                if (onRetry != null)
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    child: const Text('Réessayer'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
