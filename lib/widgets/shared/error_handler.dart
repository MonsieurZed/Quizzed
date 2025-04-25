/// Helper d'affichage des erreurs pour les vues
///
/// Ce fichier contient des extensions et des méthodes facilitant l'affichage
/// des erreurs dans les widgets. Il utilise le ErrorMessageService pour
/// convertir les codes d'erreur en messages conviviaux pour l'utilisateur.
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/controllers/lobby/lobby_controller.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/services/error_message_service.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:provider/provider.dart';

/// Extension sur BuildContext pour faciliter l'affichage des erreurs
extension ErrorHandlerExtension on BuildContext {
  /// Afficher un message d'erreur sous forme de SnackBar
  void showErrorMessage(String message, [ErrorCode? errorCode]) {
    final errorService = ErrorMessageService();
    errorService.showErrorSnackBar(this, errorCode, message);
  }

  /// Afficher un message d'erreur sous forme de dialogue
  void showErrorDialog(
    String message, [
    ErrorCode? errorCode,
    VoidCallback? onDismiss,
  ]) {
    final errorService = ErrorMessageService();
    errorService.showErrorDialog(this, errorCode, message, onDismiss);
  }

  /// Obtenir une instance du service d'erreurs
  ErrorMessageService get errorService => ErrorMessageService();

  /// Logger et afficher une erreur avec le service centralisé
  void logAndShowError({
    required String operation,
    required String tag,
    dynamic error,
    ErrorCode? errorCode,
    String? customMessage,
    bool showAsSnackBar = true,
    VoidCallback? onDismiss,
  }) {
    final errorService = ErrorMessageService();
    final message = errorService.handleError(
      operation: operation,
      tag: tag,
      error: error,
      errorCode: errorCode,
      customMessage: customMessage,
    );

    if (showAsSnackBar) {
      errorService.showErrorSnackBar(this, errorCode, customMessage ?? message);
    } else {
      errorService.showErrorDialog(
        this,
        errorCode,
        customMessage ?? message,
        onDismiss,
      );
    }
  }

  /// Afficher une erreur du lobby controller
  void showLobbyError({bool asDialog = false}) {
    final lobbyController = Provider.of<LobbyController>(this, listen: false);

    if (lobbyController.hasError) {
      final errorService = ErrorMessageService();
      if (asDialog) {
        errorService.showErrorDialog(
          this,
          lobbyController.errorCode,
          lobbyController.errorMessage,
          () => lobbyController.clearErrors(),
        );
      } else {
        errorService.showErrorSnackBar(
          this,
          lobbyController.errorCode,
          lobbyController.errorMessage,
        );
        // Effacer l'erreur après affichage en SnackBar
        lobbyController.clearErrors();
      }
    }
  }
}

/// Widget qui observe les erreurs d'un contrôleur et les affiche automatiquement
class ErrorObserver extends StatelessWidget {
  /// Le widget enfant à afficher
  final Widget child;

  /// Indique si les erreurs doivent être affichées dans une boîte de dialogue
  final bool useDialog;

  /// Tag utilisé pour le logging
  final String logTag;

  /// Constructeur du widget
  const ErrorObserver({
    Key? key,
    required this.child,
    this.useDialog = false,
    this.logTag = 'ErrorObserver',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LobbyController>(
      builder: (context, controller, _) {
        // Si le contrôleur a une erreur, l'afficher
        if (controller.hasError) {
          // Utilisation de Future.microtask pour éviter de construire pendant le build
          Future.microtask(() {
            final errorService = ErrorMessageService();
            final logger = LoggerService();

            // Log l'erreur
            logger.debug(
              'ErrorObserver: Affichage de l\'erreur - ${controller.errorMessage}',
              tag: logTag,
            );

            if (useDialog) {
              errorService.showErrorDialog(
                context,
                controller.errorCode,
                controller.errorMessage,
                () {
                  // Effacer l'erreur après fermeture
                  controller.clearErrors();
                },
              );
            } else {
              errorService.showErrorSnackBar(
                context,
                controller.errorCode,
                controller.errorMessage,
              );
              // Effacer l'erreur après affichage
              controller.clearErrors();
            }
          });
        }

        // Toujours retourner l'enfant
        return child;
      },
    );
  }
}
