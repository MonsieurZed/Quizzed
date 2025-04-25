/// Lobby Base Controller
///
/// Contrôleur de base pour les fonctionnalités liées aux lobbies
/// Fournit des fonctionnalités partagées entre les différents contrôleurs de lobby
/// Implémente l'interface ILobbyController pour garantir la cohérence
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizzzed/controllers/helpers/lobby_operation_helper.dart';
import 'package:quizzzed/controllers/interfaces/i_lobby_controller.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/error_message_service.dart';
import 'package:quizzzed/services/firebase_service.dart';
import 'package:quizzzed/services/logger_service.dart';

/// Classe de base abstraite pour les contrôleurs de lobby
abstract class LobbyBaseController extends ChangeNotifier
    implements ILobbyController {
  final FirebaseService firebaseService;
  final AuthService authService;
  final LoggerService logger = LoggerService();
  final String logTag;

  // Service centralisé de gestion des erreurs
  final ErrorMessageService _errorMessageService = ErrorMessageService();

  /// Aide pour les opérations communes sur les lobbies
  late final LobbyOperationHelper _lobbyHelper;

  // État du contrôleur
  bool _isLoading = false;
  String? _error;
  String _errorMessage = '';
  ErrorCode? _errorCode;

  // Référence à la collection de lobbies dans Firestore
  CollectionReference get lobbiesRef =>
      firebaseService.firestore.collection('lobbies');

  /// Accès à l'aide pour les opérations sur les lobbies
  LobbyOperationHelper get lobbyHelper => _lobbyHelper;

  // Getters pour l'état
  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  bool get hasError => _error != null;

  @override
  String get errorMessage => _errorMessage;

  @override
  ErrorCode? get errorCode => _errorCode;

  @override
  LobbyModel? get currentLobby => null; // À surcharger dans les sous-classes

  // Construction du contrôleur de base avec injection des dépendances
  LobbyBaseController({
    required this.firebaseService,
    required this.authService,
    required this.logTag,
  }) {
    logger.info('$logTag initialized', tag: logTag);

    // Initialiser l'aide pour les opérations de lobby
    _lobbyHelper = LobbyOperationHelper(
      lobbiesRef: lobbiesRef,
      logger: logger,
      logTag: '$logTag:Helper',
    );
  }

  // Mise à jour sécurisée de l'état de chargement
  @override
  void setLoading(bool loading) {
    if (_isLoading == loading) return; // Éviter les notifications inutiles

    _isLoading = loading;
    // Utiliser microtask pour éviter les problèmes pendant la construction
    Future.microtask(() => notifyListeners());
  }

  // Méthode sécurisée pour gérer les erreurs avec le nouveau ErrorMessageService
  @override
  void handleError(String message, dynamic error, [ErrorCode? code]) {
    // Déterminer le code d'erreur si non fourni
    ErrorCode errorCode =
        code ?? _errorMessageService.getErrorCodeFromException(error);

    // Utiliser le service centralisé pour gérer l'erreur
    final detailedMessage = _errorMessageService.handleError(
      operation: message,
      tag: logTag,
      error: error,
      errorCode: errorCode,
      stackTrace: error is Error ? error.stackTrace : null,
    );

    // Mettre à jour l'état du contrôleur
    _error = error?.toString();
    _errorMessage = detailedMessage;
    _errorCode = errorCode;
    _isLoading = false;

    // Utiliser microtask pour éviter les problèmes pendant la construction
    Future.microtask(() => notifyListeners());
  }

  /// Effacer les erreurs et réinitialiser l'état d'erreur
  @override
  void clearErrors() {
    if (_error != null || _errorMessage.isNotEmpty || _errorCode != null) {
      _error = null;
      _errorMessage = '';
      _errorCode = null;
      logger.debug('Erreurs effacées', tag: logTag);
      // Utiliser microtask pour éviter les problèmes pendant la construction
      Future.microtask(() => notifyListeners());
    }
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> verifyUserAuthenticated() async {
    final user = authService.currentFirebaseUser;
    if (user == null) {
      handleError('Utilisateur non connecté', null, ErrorCode.notAuthenticated);
      return false;
    }
    return true;
  }

  // Générer un code d'accès aléatoire pour les lobbies privés
  String generateAccessCode() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sans I, O, 0, 1 pour éviter confusion
    return String.fromCharCodes(
      Iterable.generate(
        6, // Longueur du code
        (_) => chars.codeUnitAt(
          DateTime.now().millisecondsSinceEpoch % chars.length,
        ),
      ),
    );
  }

  // Méthodes abstraites de l'interface à implémenter dans les sous-classes
  @override
  void setCurrentLobby(LobbyModel? lobby) {
    // Implémentation par défaut qui ne fait rien
    // Les sous-classes doivent fournir leur propre implémentation
  }

  @override
  Future<void> loadLobby(String lobbyId) async {
    // Implémentation par défaut qui ne fait rien
    // Les sous-classes doivent fournir leur propre implémentation
  }

  @override
  Future<void> joinLobbyStream(String lobbyId) async {
    // Implémentation par défaut qui ne fait rien
    // Les sous-classes doivent fournir leur propre implémentation
  }

  @override
  void leaveLobbyStream() {
    // Implémentation par défaut qui ne fait rien
    // Les sous-classes doivent fournir leur propre implémentation
  }

  /// Récupère un lobby par son ID de manière sécurisée
  /// Utilise lobbyHelper pour factoriser le code
  Future<LobbyModel?> fetchLobbyById(String lobbyId) async {
    try {
      setLoading(true);
      final (lobby, errorCode) = await _lobbyHelper.fetchLobbyById(lobbyId);

      if (errorCode != null) {
        handleError(
          'Erreur lors de la récupération du lobby',
          'Lobby non trouvé: $lobbyId',
          errorCode,
        );
        return null;
      }

      setLoading(false);
      return lobby;
    } catch (e) {
      handleError(
        'Erreur lors de la récupération du lobby',
        e,
        ErrorCode.firebaseError,
      );
      return null;
    }
  }

  /// Vérifie si l'utilisateur est l'hôte du lobby
  /// Utilise lobbyHelper pour factoriser le code
  Future<(bool, LobbyModel?)> verifyUserIsHost(String lobbyId) async {
    if (!await verifyUserAuthenticated()) {
      return (false, null);
    }

    try {
      final userId = authService.currentFirebaseUser!.uid;
      final (isHost, lobby, errorCode) = await _lobbyHelper.verifyUserIsHost(
        lobbyId,
        userId,
      );

      if (errorCode != null) {
        handleError(
          'Erreur de vérification des droits',
          'Vérification impossible',
          errorCode,
        );
        return (false, null);
      }

      if (!isHost) {
        handleError(
          'Action non autorisée',
          'Seul l\'hôte peut effectuer cette action',
          ErrorCode.notAuthorized,
        );
        return (false, lobby);
      }

      return (true, lobby);
    } catch (e) {
      handleError(
        'Erreur lors de la vérification des droits d\'hôte',
        e,
        ErrorCode.firebaseError,
      );
      return (false, null);
    }
  }

  /// Vérifie si l'utilisateur est dans le lobby
  /// Utilise lobbyHelper pour factoriser le code
  Future<(bool, LobbyModel?)> verifyUserInLobby(String lobbyId) async {
    if (!await verifyUserAuthenticated()) {
      return (false, null);
    }

    try {
      final userId = authService.currentFirebaseUser!.uid;
      final (isInLobby, lobby, errorCode) = await _lobbyHelper
          .verifyPlayerInLobby(lobbyId, userId);

      if (errorCode != null) {
        handleError(
          'Erreur de vérification',
          'Vérification impossible',
          errorCode,
        );
        return (false, null);
      }

      if (!isInLobby) {
        handleError(
          'Non membre du lobby',
          'Vous n\'êtes pas membre de ce lobby',
          ErrorCode.playerNotInLobby,
        );
        return (false, lobby);
      }

      return (true, lobby);
    } catch (e) {
      handleError(
        'Erreur lors de la vérification de présence dans le lobby',
        e,
        ErrorCode.firebaseError,
      );
      return (false, null);
    }
  }

  // Méthode pour forcer l'arrêt du chargement et rafraîchir l'UI
  void forceLoadingReset() {
    _isLoading = false;
    logger.debug('État de chargement forcé à FALSE', tag: logTag);
    // Notification immédiate pour éviter les délais
    notifyListeners();
  }
}
