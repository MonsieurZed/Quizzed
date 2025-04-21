// filepath: d:\GIT\quizzzed\lib\widgets\shared\loading_display.dart
/// Loading Display
///
/// Widget pour afficher une animation de chargement avec un message optionnel
library;

import 'package:flutter/material.dart';

class LoadingDisplay extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingDisplay({super.key, this.message, this.size = 40.0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size / 10,
              color: theme.colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(
                  (255 * 0.7).toInt(),
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
