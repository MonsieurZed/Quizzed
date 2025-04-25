/// Interface définissant le contrat pour les contrôleurs de gestion de l'activité dans les lobbies
///
/// Cette interface étend ILobbyController et définit les méthodes supplémentaires
/// spécifiques à la surveillance et à la gestion de l'activité des joueurs dans les lobbies.
library;

import 'package:quizzzed/controllers/interfaces/i_lobby_controller.dart';

/// Interface pour les contrôleurs de gestion de l'activité dans les lobbies
abstract class ILobbyActivityController extends ILobbyController {
  /// Démarrer le timer pour vérifier les joueurs inactifs
  void startInactivityTimer(String lobbyId);

  /// Arrêter le timer
  void stopInactivityTimer();

  /// Mise à jour de l'activité du joueur courant
  Future<void> updatePlayerActivity(String lobbyId);

  /// Vérifier les joueurs inactifs dans un lobby
  Future<void> checkInactivePlayers(String lobbyId);

  /// Vérifier et supprimer les lobbies inactifs
  Future<void> checkInactiveLobbies();
}
