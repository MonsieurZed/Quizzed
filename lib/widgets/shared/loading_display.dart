// filepath: d:\GIT\quizzzed\lib\widgets\shared\loading_display.dart
/// Widget d'affichage de chargement
///
/// Affiche un indicateur de chargement avec un message facultatif
library;

import 'package:flutter/material.dart';

/// Widget pour afficher un indicateur de chargement avec un message
class LoadingDisplay extends StatelessWidget {
  /// Message à afficher avec l'indicateur de chargement
  final String? message;

  /// Constructeur
  const LoadingDisplay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
