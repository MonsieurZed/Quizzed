/// Widget de bouton d'accès au mode débogage
///
/// Bouton flottant discret qui permet d'accéder rapidement à la console de débogage
/// Visible uniquement en mode debug pour les développeurs

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzzed/routes/app_routes.dart';

class DebugAccessButton extends StatelessWidget {
  const DebugAccessButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // N'afficher le bouton que si l'application est en mode debug
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Positioned(
      bottom: 20,
      right: 20,
      child: Opacity(
        opacity: 0.6, // Semi-transparent pour être discret
        child: GestureDetector(
          onTap: () {
            context.pushNamed(AppRoutes.debug);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.2).toInt()),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.bug_report,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
