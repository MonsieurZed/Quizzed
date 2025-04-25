/// Interface définissant le contrat pour les contrôleurs de gestion des lobbies
///
/// Cette interface étend ILobbyController et définit les méthodes supplémentaires
/// spécifiques à la gestion des lobbies (création, modification, suppression).
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/controllers/interfaces/i_lobby_controller.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';

/// Interface pour les contrôleurs de gestion des lobbies
abstract class ILobbyManagementController extends ILobbyController {
  /// Liste des lobbies publics disponibles
  List<LobbyModel> get publicLobbies;

  /// Charger la liste des lobbies publics disponibles
  Future<void> loadPublicLobbies({bool refresh = false});

  /// Récupère un lobby par son ID
  Future<LobbyModel?> fetchLobbyById(String lobbyId);

  /// Récupère les lobbies publics
  Future<List<LobbyModel>> fetchPublicLobbies({int limit = 20});

  /// Récupère les lobbies créés par l'utilisateur actuel
  Future<List<LobbyModel>> fetchUserLobbies();

  /// Créer un nouveau lobby
  Future<String?> createLobby({
    required String name,
    required String description,
    required int maxPlayers,
    required LobbyVisibility visibility,
    required LobbyJoinPolicy joinPolicy,
    String? quizId,
    String? accessCode,
    Color? userColor,
  });

  /// Modifier les paramètres d'un lobby existant (hôte uniquement)
  Future<bool> updateLobby({
    required String lobbyId,
    String? name,
    String? description,
    int? maxPlayers,
    LobbyVisibility? visibility,
    LobbyJoinPolicy? joinPolicy,
    String? quizId,
    String? accessCode,
    Color? backgroundColor,
  });

  /// Méthode dépréciée - à conserver pour rétrocompatibilité
  @Deprecated('Utilisez updateLobby à la place')
  Future<bool> updateLobbySettings(
    String lobbyId, {
    String? name,
    String? category,
    LobbyVisibility? visibility,
    int? maxPlayers,
    int? minPlayers,
  });

  /// Vérifier si l'utilisateur actuel a déjà un lobby
  Future<bool> userHasExistingLobby();

  /// Supprimer un lobby (accessible uniquement pour l'hôte)
  Future<bool> deleteLobby(String lobbyId);

  /// Rejoindre un stream de lobby pour recevoir les mises à jour en temps réel
  Future<void> joinLobbyStream(String lobbyId);

  /// Se désabonner du stream du lobby
  void leaveLobbyStream();
}
