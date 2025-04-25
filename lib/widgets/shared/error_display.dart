// filepath: d:\GIT\quizzzed\lib\widgets\shared\error_display.dart
/// Widget d'affichage d'erreur
///
/// Ce widget est utilisé pour afficher des messages d'erreur dans l'interface utilisateur
/// avec différentes options de présentation et de style selon le contexte.
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/services/error_message_service.dart';
import 'package:quizzzed/services/logger_service.dart' as logger;
import 'package:quizzzed/widgets/shared/error_dialog.dart';

/// Widget pour afficher un message d'erreur
class ErrorDisplay extends StatelessWidget {
  /// Message d'erreur à afficher
  final String message;

  /// Titre du message d'erreur
  final String? title;

  /// Fonction à appeler quand l'utilisateur ferme l'erreur
  final VoidCallback? onDismiss;

  /// Fonction à appeler pour réessayer l'opération
  final VoidCallback? onRetry;

  /// Fonction à appeler pour revenir en arrière
  final VoidCallback? onBack;

  /// Type d'affichage de l'erreur (dialogue, toast, inline)
  final ErrorDisplayType displayType;

  /// Si l'erreur doit être masquée automatiquement après un délai
  final bool autoHide;

  /// Si l'erreur doit être loggée
  final bool logError;

  /// Code d'erreur associé
  final ErrorCode? errorCode;

  /// Erreur technique originale (pour le logging)
  final dynamic error;

  /// Tag pour le logging
  final String tag;

  /// Service de gestion des messages d'erreur
  final ErrorMessageService _errorMessageService = ErrorMessageService();

  /// Service de journalisation
  final logger.LoggerService _loggerService = logger.LoggerService();

  /// Constructeur
  ErrorDisplay({
    super.key,
    required this.message,
    this.title,
    this.onDismiss,
    this.onRetry,
    this.onBack,
    this.displayType = ErrorDisplayType.inline,
    this.autoHide = false,
    this.logError = true,
    this.errorCode,
    this.error,
    this.tag = 'ErrorDisplay',
  }) {
    if (logError) {
      final logLevel = _getLogLevelForErrorCode(errorCode);
      switch (logLevel) {
        case logger.LogLevel.debug:
          _loggerService.debug(message, tag: tag, data: error);
          break;
        case logger.LogLevel.info:
          _loggerService.info(message, tag: tag, data: error);
          break;
        case logger.LogLevel.warning:
          _loggerService.warning(message, tag: tag, data: error);
          break;
        case logger.LogLevel.error:
        case logger.LogLevel.critical:
          _loggerService.error(message, tag: tag, data: error);
          break;
      }
    }
  }

  /// Détermine le niveau de log en fonction du code d'erreur
  logger.LogLevel _getLogLevelForErrorCode(ErrorCode? code) {
    if (code == null) return logger.LogLevel.warning;

    switch (code) {
      case ErrorCode.authenticationFailed:
      case ErrorCode.networkError:
      case ErrorCode.timeoutError:
      case ErrorCode.invalidInput:
      case ErrorCode.lobbyNotFound:
      case ErrorCode.lobbyFull:
      case ErrorCode.lobbyNameRequired:
        return logger.LogLevel.warning;
      case ErrorCode.serverError:
      case ErrorCode.firebaseError:
      case ErrorCode.dataParsingError:
        return logger.LogLevel.error;
      case ErrorCode.notAuthorized:
      case ErrorCode.notImplemented:
        return logger.LogLevel.warning;
      default:
        return logger.LogLevel.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (displayType) {
      case ErrorDisplayType.dialog:
        // Pour les dialogues, on les affiche via un builder après le build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder:
                (context) => ErrorDialog(
                  title: title ?? _getTitleForErrorCode(errorCode),
                  message: message,
                  onDismiss: onDismiss,
                  onBack: onBack,
                  onRetry: onRetry,
                ),
          );
        });
        // Retourne un widget vide car le dialogue est affiché séparément
        return const SizedBox.shrink();

      case ErrorDisplayType.snackbar:
        // Pour les snackbars, on les affiche via un builder après le build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 5),
              action:
                  onDismiss != null
                      ? SnackBarAction(label: 'Fermer', onPressed: onDismiss!)
                      : null,
              behavior: SnackBarBehavior.floating,
              backgroundColor: _getColorForErrorCode(errorCode, context),
            ),
          );
        });
        // Retourne un widget vide car le snackbar est affiché séparément
        return const SizedBox.shrink();

      case ErrorDisplayType.inline:
      default:
        // Pour l'affichage inline, on retourne directement le widget
        return Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: _getColorForErrorCode(errorCode, context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: _getColorForErrorCode(errorCode, context),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: _getColorForErrorCode(errorCode, context),
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        title!,
                        style: TextStyle(
                          color: _getColorForErrorCode(errorCode, context),
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    if (onDismiss != null)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onDismiss,
                        color: _getColorForErrorCode(errorCode, context),
                        iconSize: 20.0,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 8.0),
              ],
              if (title == null)
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: _getColorForErrorCode(errorCode, context),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: _getColorForErrorCode(errorCode, context),
                        ),
                      ),
                    ),
                    if (onDismiss != null)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onDismiss,
                        color: _getColorForErrorCode(errorCode, context),
                        iconSize: 20.0,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: 28.0),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: _getColorForErrorCode(errorCode, context),
                    ),
                  ),
                ),

              // Buttons for retry and back actions
              if (onRetry != null || onBack != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onBack != null)
                        TextButton.icon(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Retour'),
                          style: TextButton.styleFrom(
                            foregroundColor: _getColorForErrorCode(
                              errorCode,
                              context,
                            ),
                          ),
                        ),
                      if (onRetry != null) ...[
                        if (onBack != null) const SizedBox(width: 8.0),
                        TextButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: TextButton.styleFrom(
                            foregroundColor: _getColorForErrorCode(
                              errorCode,
                              context,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
    }
  }

  /// Obtient le titre approprié pour le dialogue d'erreur en fonction du code d'erreur
  String _getTitleForErrorCode(ErrorCode? errorCode) {
    if (errorCode == null) return 'Erreur';

    switch (errorCode) {
      case ErrorCode.networkError:
      case ErrorCode.timeoutError:
        return 'Problème de connexion';
      case ErrorCode.authenticationFailed:
      case ErrorCode.notAuthorized:
        return 'Erreur d\'authentification';
      case ErrorCode.invalidInput:
        return 'Données invalides';
      case ErrorCode.serverError:
      case ErrorCode.firebaseError:
        return 'Erreur serveur';
      default:
        return 'Erreur';
    }
  }

  /// Obtient la couleur appropriée pour l'erreur en fonction du code d'erreur
  Color _getColorForErrorCode(ErrorCode? errorCode, BuildContext context) {
    final theme = Theme.of(context);
    if (errorCode == null) return theme.colorScheme.error;

    switch (errorCode) {
      case ErrorCode.networkError:
      case ErrorCode.timeoutError:
        return const Color(0xFFE65100); // Orange foncé
      case ErrorCode.authenticationFailed:
      case ErrorCode.notAuthorized:
        return const Color(0xFFD32F2F); // Rouge
      case ErrorCode.invalidInput:
      case ErrorCode.lobbyNameRequired:
      case ErrorCode.lobbyNotFound:
      case ErrorCode.lobbyFull:
        return const Color(0xFFC2185B); // Rose foncé
      case ErrorCode.serverError:
      case ErrorCode.firebaseError:
      case ErrorCode.dataParsingError:
        return const Color(0xFF7B1FA2); // Violet
      case ErrorCode.notImplemented:
        return const Color(0xFF0288D1); // Bleu
      default:
        return theme.colorScheme.error;
    }
  }
}

/// Types d'affichage pour les erreurs
enum ErrorDisplayType {
  /// Affiche l'erreur dans un dialogue modal
  dialog,

  /// Affiche l'erreur dans un snackbar en bas de l'écran
  snackbar,

  /// Affiche l'erreur directement dans le flux du contenu
  inline,
}

/// Extension sur BuildContext pour afficher facilement des erreurs
extension ErrorDisplayExtension on BuildContext {
  /// Affiche une erreur dans l'UI
  void showError({
    required String message,
    VoidCallback? onDismiss,
    ErrorDisplayType displayType = ErrorDisplayType.snackbar,
    bool autoHide = true,
    ErrorCode? errorCode,
    dynamic error,
    String tag = 'ErrorDisplay',
  }) {
    switch (displayType) {
      case ErrorDisplayType.dialog:
        showDialog(
          context: this,
          builder:
              (context) => ErrorDialog(
                title: _getTitleForErrorCode(errorCode),
                message: message,
                onDismiss: onDismiss,
              ),
        );
        break;
      case ErrorDisplayType.snackbar:
        ScaffoldMessenger.of(this).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
            action:
                onDismiss != null
                    ? SnackBarAction(label: 'Fermer', onPressed: onDismiss)
                    : null,
            behavior: SnackBarBehavior.floating,
            backgroundColor: _getSnackbarColorForErrorCode(errorCode),
          ),
        );
        break;
      case ErrorDisplayType.inline:
        // Cette méthode ne peut pas afficher un widget inline directement
        // Elle est plutôt conçue pour les notifications flottantes
        // Utiliser plutôt le widget ErrorDisplay directement dans ce cas
        ScaffoldMessenger.of(this).showSnackBar(
          SnackBar(
            content: Text(
              'Note: Pour afficher une erreur en mode inline, utilisez le widget ErrorDisplay directement.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        break;
    }

    // Logger l'erreur si nécessaire
    final ErrorMessageService errorService = ErrorMessageService();
    errorService.handleError(
      operation: 'Affichage d\'erreur',
      tag: tag,
      error: error,
      errorCode: errorCode,
      customMessage: message,
    );
  }

  /// Méthode pour loguer et afficher une erreur avec l'ErrorMessageService
  /// Cette méthode offre une intégration plus profonde avec le système de gestion d'erreurs
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

    // Utiliser le service centralisé pour gérer l'erreur
    final message = errorService.handleError(
      operation: operation,
      tag: tag,
      error: error,
      errorCode: errorCode,
      customMessage: customMessage,
    );

    // Afficher l'erreur à l'utilisateur
    if (showAsSnackBar) {
      showError(
        message: message,
        onDismiss: onDismiss,
        displayType: ErrorDisplayType.snackbar,
        errorCode: errorCode,
        error: error,
        tag: tag,
      );
    } else {
      showError(
        message: message,
        onDismiss: onDismiss,
        displayType: ErrorDisplayType.dialog,
        errorCode: errorCode,
        error: error,
        tag: tag,
      );
    }
  }

  /// Obtient le titre approprié pour le dialogue d'erreur en fonction du code d'erreur
  String _getTitleForErrorCode(ErrorCode? errorCode) {
    if (errorCode == null) return 'Erreur';

    switch (errorCode) {
      case ErrorCode.networkError:
      case ErrorCode.timeoutError:
        return 'Problème de connexion';
      case ErrorCode.authenticationFailed:
      case ErrorCode.notAuthorized:
        return 'Erreur d\'authentification';
      case ErrorCode.invalidInput:
        return 'Données invalides';
      case ErrorCode.serverError:
      case ErrorCode.firebaseError:
      case ErrorCode.databaseError:
      case ErrorCode.storageError:
        return 'Erreur serveur';
      default:
        return 'Erreur';
    }
  }

  // Duplicate method removed

  /// Obtient la couleur appropriée pour le snackbar en fonction du code d'erreur
  Color _getSnackbarColorForErrorCode(ErrorCode? errorCode) {
    if (errorCode == null) return Colors.red.shade700;

    switch (errorCode) {
      case ErrorCode.networkError:
      case ErrorCode.timeoutError:
        return Colors.orange.shade800;
      case ErrorCode.authenticationFailed:
      case ErrorCode.notAuthorized:
        return Colors.red.shade700;
      case ErrorCode.invalidInput:
      case ErrorCode.lobbyNameRequired:
      case ErrorCode.lobbyNotFound:
      case ErrorCode.lobbyFull:
        return Colors.pink.shade700;
      case ErrorCode.serverError:
      case ErrorCode.firebaseError:
      case ErrorCode.databaseError:
      case ErrorCode.storageError:
      case ErrorCode.unknown:
      case ErrorCode.dataParsingError:
        return Colors.purple.shade700;
      case ErrorCode.userCancelled:
      case ErrorCode.notImplemented:
        return Colors.blue.shade700;
      default:
        return Colors.red.shade700;
    }
  }
}
