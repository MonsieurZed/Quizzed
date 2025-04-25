/// Interface définissant le contrat pour les contrôleurs de gestion des joueurs dans les lobbies
///
/// Cette interface étend ILobbyController et définit les méthodes supplémentaires
/// spécifiques à la gestion des joueurs dans les lobbies.
library;

import 'package:quizzzed/controllers/interfaces/i_lobby_controller.dart';

/// Interface pour les contrôleurs de gestion des joueurs dans les lobbies
abstract class ILobbyPlayerController extends ILobbyController {
  /// Rejoindre un lobby existant
  Future<bool> joinLobby(String lobbyId);

  /// Rejoindre un lobby privé avec un code
  Future<bool> joinPrivateLobby(String lobbyId, String code);

  /// Rejoindre un lobby en utilisant uniquement son code
  Future<String?> joinLobbyByCode(String code);

  /// Quitter un lobby
  Future<bool> leaveLobby(String lobbyId);

  /// Mise à jour du profil et de l'activité d'un joueur
  Future<void> updatePlayerActivity(String lobbyId);

  /// Basculer le statut "prêt" d'un joueur
  Future<bool> togglePlayerStatus(String lobbyId);

  /// Transférer la propriété du lobby à un autre joueur (hôte uniquement)
  Future<bool> transferOwnership(String lobbyId, String newOwnerId);

  /// Expulser un joueur du lobby (action de l'hôte)
  Future<bool> kickPlayer(String lobbyId, String playerUserId);
}
