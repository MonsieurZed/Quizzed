/// Widget de dialogue d'erreur
///
/// Affiche un message d'erreur dans une boîte de dialogue conviviale
/// avec un titre, un message et un bouton pour fermer la boîte de dialogue.
library;

import 'package:flutter/material.dart';

/// Widget de dialogue d'erreur personnalisé
class ErrorDialog extends StatelessWidget {
  /// Titre du dialogue
  final String title;

  /// Message d'erreur à afficher
  final String message;

  /// Action à exécuter lorsque le dialogue est fermé
  final VoidCallback? onDismiss;

  /// Action à exécuter lorsque l'utilisateur veut revenir en arrière
  final VoidCallback? onBack;

  /// Action à exécuter lorsque l'utilisateur veut réessayer
  final VoidCallback? onRetry;

  /// Icône à afficher dans le dialogue
  final IconData icon;

  /// Constructeur du widget
  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onDismiss,
    this.onBack,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: Colors.red.shade700, size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
      ),
      actions: [
        if (onBack != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onBack!();
            },
            child: const Text('Retour'),
          ),
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('Réessayer'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onDismiss != null) {
              onDismiss!();
            }
          },
          child: const Text('OK'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      backgroundColor: theme.cardColor,
    );
  }
}
