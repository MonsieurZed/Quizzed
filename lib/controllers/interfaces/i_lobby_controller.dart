/// Interface définissant le contrat commun pour les contrôleurs de lobby
///
/// Cette interface établit un ensemble standardisé de méthodes que tous les
/// contrôleurs liés aux lobbies doivent implémenter, assurant ainsi la cohérence
/// et l'interopérabilité entre les différentes implémentations.
library;

import 'package:flutter/foundation.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';

/// Interface pour les contrôleurs de lobby
abstract class ILobbyController extends ChangeNotifier {
  /// État de chargement du contrôleur
  bool get isLoading;

  /// Message d'erreur en cas d'échec d'une opération
  String? get error;

  /// Indique si une erreur s'est produite
  bool get hasError;

  /// Message d'erreur détaillé
  String get errorMessage;

  /// Code d'erreur spécifique, null si pas d'erreur
  ErrorCode? get errorCode;

  /// Lobby actuellement actif
  LobbyModel? get currentLobby;

  /// Définir le lobby courant
  void setCurrentLobby(LobbyModel? lobby);

  /// Mettre à jour l'état de chargement du contrôleur
  void setLoading(bool loading);

  /// Charger un lobby spécifique par son ID
  Future<void> loadLobby(String lobbyId);

  /// Rejoindre un stream de lobby pour recevoir les mises à jour en temps réel
  Future<void> joinLobbyStream(String lobbyId);

  /// Se désabonner du stream du lobby
  void leaveLobbyStream();

  /// Mise en place d'un mécanisme de gestion des erreurs
  void handleError(String message, dynamic errorDetails, [ErrorCode? code]);

  /// Effacer les erreurs et réinitialiser l'état d'erreur
  void clearErrors();
}
