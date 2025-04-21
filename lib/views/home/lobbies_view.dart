/// Lobbies View
///
/// Vue principale pour l'accès aux lobbies
/// Contient la liste des lobbies publics et les options pour créer ou rejoindre des lobbies
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/controllers/lobby_controller.dart';
import 'package:quizzzed/views/home/lobby_list_view.dart';

class LobbiesView extends StatelessWidget {
  const LobbiesView({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupérer le LobbyController déjà enregistré dans main.dart
    final lobbyController = Provider.of<LobbyController>(
      context,
      listen: false,
    );

    // Initialiser le chargement des lobbies publics si ce n'est pas déjà fait
    WidgetsBinding.instance.addPostFrameCallback((_) {
      lobbyController.loadPublicLobbies();
    });

    return const LobbyListView();
  }
}
