/// App Config
///
/// Configuration globale de l'application
/// Constantes, paramètres et valeurs par défaut
library;

import 'package:flutter/material.dart';

/// Classe représentant une couleur de profil pour les avatars
class ProfileColor {
  final String name;
  final Color color;
  final Color textColor;

  const ProfileColor({
    required this.name,
    required this.color,
    this.textColor = Colors.white,
  });
}

class AppConfig {
  // Version de l'application
  static const String appVersion = '1.0.0';
  static const String appName = 'Quizzzed';

  // Constantes de configuration
  static const int defaultQuizTimeInSeconds = 30;
  static const int defaultCacheTimeInMinutes = 10;
  static const int lobbyInactiveTimeoutInMinutes = 60;

  // Opacité des couleurs (50%)
  static const double colorOpacity = 0.5;

  // Paramètres de validation formulaires
  static const int minPasswordLength = 6;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;

  // Paramètres Firebase
  static const String usersCollection = 'users';
  static const String quizzesCollection = 'quizzes';
  static const String lobbiesCollection = 'lobbies';
  static const String questionsCollection = 'questions';
  static const String answersCollection = 'answers';
  static const String scoresCollection = 'scores';

  // URLs des assets statiques
  static const String defaultUserAvatar =
      'logo'; // Utilisation d'un fichier existant

  // Couleur par défaut pour les utilisateurs
  static final Color defaultUserColor = const Color(
    0xFF2196F3,
  ); // Bleu standard

  // Constantes d'animation
  static const int defaultAnimationDurationMs = 300;
  static const int longAnimationDurationMs = 500;

  // Paramètres de jeu
  static const int minPlayersToStart = 2;
  static const int maxPlayersPerLobby = 30;
  static const int maxQuestionsPerQuiz = 30;

  // Liste des couleurs de profil disponibles
  static final List<ProfileColor> availableProfileColors = [
    // 🔴 ROUGE
    ProfileColor(
      name: 'Rouge clair',
      color: Colors.red[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Rouge', color: Colors.red),
    ProfileColor(name: 'Rouge foncé', color: Colors.red[900]!),

    // 🟠 ORANGE
    ProfileColor(
      name: 'Orangé clair',
      color: Colors.deepOrange[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Orangé', color: Colors.deepOrange),
    ProfileColor(name: 'Orangé foncé', color: Colors.deepOrange[900]!),

    ProfileColor(
      name: 'Orange clair',
      color: Colors.orange[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Orange', color: Colors.orange),
    ProfileColor(name: 'Orange foncé', color: Colors.orange[900]!),

    // 🟡 JAUNE / AMBRE / LIME
    ProfileColor(
      name: 'Jaune clair',
      color: Colors.yellow[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Jaune', color: Colors.yellow, textColor: Colors.black),
    ProfileColor(
      name: 'Jaune foncé',
      color: Colors.yellow[800]!,
      textColor: Colors.black,
    ),

    ProfileColor(
      name: 'Ambre clair',
      color: Colors.amber[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Ambre', color: Colors.amber, textColor: Colors.black),
    ProfileColor(name: 'Ambre foncé', color: Colors.amber[900]!),

    ProfileColor(
      name: 'Lime clair',
      color: Colors.lime[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Lime', color: Colors.lime, textColor: Colors.black),
    ProfileColor(name: 'Lime foncé', color: Colors.lime[900]!),

    // 🟢 VERT
    ProfileColor(
      name: 'Vert clair',
      color: Colors.green[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Vert', color: Colors.green),
    ProfileColor(name: 'Vert foncé', color: Colors.green[900]!),

    // 🟦 TURQUOISE / CYAN
    ProfileColor(
      name: 'Turquoise clair',
      color: Colors.teal[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Turquoise', color: Colors.teal),
    ProfileColor(name: 'Turquoise foncé', color: Colors.teal[900]!),

    ProfileColor(
      name: 'Cyan clair',
      color: Colors.cyan[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Cyan', color: Colors.cyan),
    ProfileColor(name: 'Cyan foncé', color: Colors.cyan[900]!),

    // 🔵 BLEU / INDIGO
    ProfileColor(
      name: 'Bleu clair',
      color: Colors.blue[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Bleu', color: Colors.blue),
    ProfileColor(name: 'Bleu foncé', color: Colors.blue[900]!),

    ProfileColor(
      name: 'Indigo clair',
      color: Colors.indigo[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Indigo', color: Colors.indigo),
    ProfileColor(name: 'Indigo foncé', color: Colors.indigo[900]!),

    // 🟣 VIOLET / ROSE
    ProfileColor(
      name: 'Violet clair',
      color: Colors.purple[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Violet', color: Colors.purple),
    ProfileColor(name: 'Violet foncé', color: Colors.purple[900]!),

    ProfileColor(
      name: 'Rose clair',
      color: Colors.pink[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Rose', color: Colors.pink),
    ProfileColor(name: 'Rose foncé', color: Colors.pink[900]!),

    // 🟤 MARRON
    ProfileColor(
      name: 'Marron clair',
      color: Colors.brown[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Marron', color: Colors.brown),
    ProfileColor(name: 'Marron foncé', color: Colors.brown[900]!),

    // ⚫ GRIS / BLEU-GRIS
    ProfileColor(
      name: 'Gris clair',
      color: Colors.grey[200]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Gris', color: Colors.grey),
    ProfileColor(name: 'Gris foncé', color: Colors.grey[900]!),

    ProfileColor(
      name: 'Bleu-gris clair',
      color: Colors.blueGrey[100]!,
      textColor: Colors.black,
    ),
    ProfileColor(name: 'Bleu-gris', color: Colors.blueGrey),
    ProfileColor(name: 'Bleu-gris foncé', color: Colors.blueGrey[900]!),
  ];
}

class AppEnvironment {
  static const bool isProduction = false;
  static const bool enableLogging = true;
  static const bool enableFirebaseEmulator = false;
}
