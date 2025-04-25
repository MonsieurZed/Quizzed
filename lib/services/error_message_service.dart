/// Service de gestion des messages d'erreur
///
/// Convertit les codes d'erreur techniques en messages conviviaux pour l'utilisateur,
/// centralise le logging des erreurs, et fournit des méthodes pour afficher ces messages
/// de manière cohérente à travers l'application.
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:quizzzed/widgets/shared/error_dialog.dart';

/// Service qui traduit les codes d'erreur en messages utilisateur,
/// centralise le logging des erreurs, et fournit des méthodes pour
/// afficher ces messages
class ErrorMessageService {
  final LoggerService _logger = LoggerService();
  final String _logTag = 'ErrorMessageService';

  /// Singleton instance
  static final ErrorMessageService _instance = ErrorMessageService._internal();

  /// Factory constructor qui renvoie l'instance singleton
  factory ErrorMessageService() {
    return _instance;
  }

  /// Constructeur privé pour le singleton
  ErrorMessageService._internal() {
    _logger.debug('ErrorMessageService initialized', tag: _logTag);
  }

  /// Obtenir un message utilisateur à partir d'un code d'erreur
  String getUserMessage(ErrorCode? code, [String? customMessage]) {
    // Si un message personnalisé est fourni, l'utiliser
    if (customMessage != null && customMessage.isNotEmpty) {
      return customMessage;
    }

    // Si aucun code n'est fourni, utiliser un message générique
    if (code == null) {
      return 'Une erreur s\'est produite. Veuillez réessayer.';
    }

    // Traduire le code en message utilisateur
    switch (code) {
      // Messages d'authentification
      case ErrorCode.notAuthenticated:
        return 'Vous devez être connecté pour effectuer cette action. Veuillez vous connecter.';
      case ErrorCode.authenticationFailed:
        return 'Échec de la connexion. Vérifiez vos identifiants et réessayez.';
      case ErrorCode.notAuthorized:
        return 'Vous n\'avez pas les droits nécessaires pour effectuer cette action.';

      // Messages relatifs aux lobbies
      case ErrorCode.lobbyNotFound:
        return 'Le lobby demandé n\'existe pas ou a été supprimé.';
      case ErrorCode.lobbyFull:
        return 'Ce lobby est complet. Veuillez en rejoindre un autre ou créer le vôtre.';
      case ErrorCode.lobbyNameRequired:
        return 'Le nom du lobby ne peut pas être vide.';
      case ErrorCode.lobbyInProgress:
        return 'Une partie est en cours dans ce lobby. Impossible de le modifier pour le moment.';
      case ErrorCode.lobbyClosed:
        return 'Ce lobby est fermé et n\'accepte plus de joueurs.';
      case ErrorCode.invalidAccessCode:
        return 'Le code d\'accès saisi est incorrect.';

      // Messages relatifs aux joueurs
      case ErrorCode.playerNotFound:
        return 'Le joueur demandé n\'existe pas ou a quitté la partie.';
      case ErrorCode.playerAlreadyInLobby:
        return 'Vous êtes déjà dans un lobby. Veuillez le quitter avant d\'en rejoindre un autre.';
      case ErrorCode.playerNotInLobby:
        return 'Vous n\'êtes pas membre de ce lobby.';
      case ErrorCode.kickSelfNotAllowed:
        return 'Vous ne pouvez pas vous expulser vous-même du lobby.';

      // Messages relatifs aux quiz
      case ErrorCode.quizNotFound:
        return 'Le quiz demandé n\'existe pas ou a été supprimé.';
      case ErrorCode.noQuestionsInQuiz:
        return 'Ce quiz ne contient aucune question. Impossible de démarrer la partie.';
      case ErrorCode.questionNotFound:
        return 'La question demandée n\'existe pas.';
      case ErrorCode.answerNotFound:
        return 'La réponse sélectionnée n\'existe pas.';

      // Messages relatifs au jeu
      case ErrorCode.gameNotStarted:
        return 'La partie n\'a pas encore commencé.';
      case ErrorCode.gameAlreadyStarted:
        return 'La partie a déjà commencé. Impossible de modifier les paramètres.';
      case ErrorCode.notEnoughPlayers:
        return 'Il n\'y a pas assez de joueurs pour démarrer la partie.';

      // Messages relatifs au réseau
      case ErrorCode.networkError:
        return 'Problème de connexion réseau. Vérifiez votre connexion et réessayez.';
      case ErrorCode.timeoutError:
        return 'La requête a pris trop de temps. Veuillez réessayer.';
      case ErrorCode.serverError:
        return 'Erreur serveur. Nos équipes ont été notifiées du problème.';

      // Messages Firebase
      case ErrorCode.firebaseError:
        return 'Erreur de communication avec notre base de données. Veuillez réessayer.';
      case ErrorCode.firebasePermissionDenied:
        return 'Accès refusé. Vous n\'avez pas les permissions nécessaires.';

      // Messages génériques
      case ErrorCode.unknown:
        return 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
      case ErrorCode.invalidParameter:
        return 'Les informations saisies ne sont pas valides. Veuillez les vérifier.';
      case ErrorCode.operationFailed:
        return 'L\'opération a échoué. Veuillez réessayer plus tard.';
      case ErrorCode.notImplemented:
        return 'Cette fonctionnalité n\'est pas encore disponible.';

      default:
        return code.defaultMessage;
    }
  }

  /// Obtenir un titre d'erreur basé sur la catégorie du code d'erreur
  String getErrorTitle(ErrorCode? code) {
    if (code == null) return 'Erreur';

    // Déterminer le titre en fonction du code d'erreur
    String codeStr = code.toString();
    if (codeStr.startsWith('AUTH_')) {
      return 'Erreur d\'authentification';
    } else if (codeStr.startsWith('LOBBY_')) {
      return 'Erreur de lobby';
    } else if (codeStr.startsWith('PLAYER_')) {
      return 'Erreur de joueur';
    } else if (codeStr.startsWith('QUIZ_')) {
      return 'Erreur de quiz';
    } else if (codeStr.startsWith('GAME_')) {
      return 'Erreur de partie';
    } else if (codeStr.startsWith('NET_')) {
      return 'Erreur réseau';
    } else if (codeStr.startsWith('FB_')) {
      return 'Erreur de base de données';
    }

    return 'Erreur';
  }

  /// Méthode centrale pour gérer et logger les erreurs
  ///
  /// Cette méthode est le point d'entrée principal pour toute gestion d'erreur dans l'application.
  /// Elle combine logging, formatage du message utilisateur, et retourne le message d'erreur formaté.
  String handleError({
    required String operation,
    required String tag,
    dynamic error,
    ErrorCode? errorCode,
    String? customMessage,
    StackTrace? stackTrace,
    LogLevel logLevel = LogLevel.error,
  }) {
    // Déterminer le code d'erreur à utiliser
    final code = errorCode ?? ErrorCode.unknown;

    // Formater un message de log détaillé
    final detailedMessage = customMessage ?? getUserMessage(code);
    final logMessage = 'Erreur pendant $operation: $detailedMessage';

    // Logger l'erreur avec le niveau approprié
    switch (logLevel) {
      case LogLevel.debug:
        _logger.debug(logMessage, tag: tag, data: error);
        break;
      case LogLevel.info:
        _logger.info(logMessage, tag: tag, data: error);
        break;
      case LogLevel.warning:
        _logger.warning(logMessage, tag: tag, data: error);
        break;
      case LogLevel.error:
        _logger.error(logMessage, tag: tag, data: stackTrace ?? error);
        break;
    }

    // Retourner le message utilisateur
    return detailedMessage;
  }

  /// Traite une exception et retourne un code d'erreur approprié
  ErrorCode getErrorCodeFromException(dynamic exception) {
    // Firebase exceptions
    if (exception.toString().contains('firebase') ||
        exception.toString().contains('firestore')) {
      if (exception.toString().contains('permission-denied')) {
        return ErrorCode.firebasePermissionDenied;
      }
      return ErrorCode.firebaseError;
    }

    // Network exceptions
    if (exception.toString().contains('SocketException') ||
        exception.toString().contains('network')) {
      return ErrorCode.networkError;
    }

    if (exception.toString().contains('timeout')) {
      return ErrorCode.timeoutError;
    }

    // Default to unknown error
    return ErrorCode.unknown;
  }

  /// Afficher un dialogue d'erreur avec le message utilisateur
  void showErrorDialog(
    BuildContext context,
    ErrorCode? code, [
    String? customMessage,
    VoidCallback? onDismiss,
  ]) {
    final message = getUserMessage(code, customMessage);
    final title = getErrorTitle(code);

    // Log l'erreur pour débogage
    _logger.warning('Showing error dialog: $title - $message', tag: _logTag);

    showDialog(
      context: context,
      builder:
          (context) =>
              ErrorDialog(title: title, message: message, onDismiss: onDismiss),
    );
  }

  /// Afficher un message d'erreur dans un SnackBar
  void showErrorSnackBar(
    BuildContext context,
    ErrorCode? code, [
    String? customMessage,
  ]) {
    final message = getUserMessage(code, customMessage);

    // Log l'erreur pour débogage
    _logger.warning('Showing error snackbar: $message', tag: _logTag);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Obtenir une icône appropriée pour l'erreur
  IconData getErrorIcon(ErrorCode? code) {
    if (code == null) return Icons.error_outline;

    // Choisir une icône en fonction du type d'erreur
    String codeStr = code.toString();
    if (codeStr.startsWith('AUTH_')) {
      return Icons.lock_outline;
    } else if (codeStr.startsWith('LOBBY_')) {
      return Icons.meeting_room_outlined;
    } else if (codeStr.startsWith('PLAYER_')) {
      return Icons.person_outline;
    } else if (codeStr.startsWith('QUIZ_')) {
      return Icons.quiz_outlined;
    } else if (codeStr.startsWith('GAME_')) {
      return Icons.sports_esports_outlined;
    } else if (codeStr.startsWith('NET_')) {
      return Icons.wifi_off_outlined;
    } else if (codeStr.startsWith('FB_')) {
      return Icons.storage_outlined;
    }

    return Icons.error_outline;
  }
}

/// Niveaux de log pour les erreurs
enum LogLevel { debug, info, warning, error }
