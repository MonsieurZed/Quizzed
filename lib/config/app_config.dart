/// App Config
///
/// Configuration globale de l'application
/// Constantes, paramètres et valeurs par défaut
library;

class AppConfig {
  // Version de l'application
  static const String appVersion = '1.0.0';
  static const String appName = 'Quizzzed';

  // Constantes de configuration
  static const int defaultQuizTimeInSeconds = 30;
  static const int defaultCacheTimeInMinutes = 10;
  static const int lobbyInactiveTimeoutInMinutes = 60;

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
  static const String defaultAvatarUrl =
      'assets/images/avatars/logo.png'; // Utilisation d'un fichier existant

  // Constantes d'animation
  static const int defaultAnimationDurationMs = 300;
  static const int longAnimationDurationMs = 500;

  // Paramètres de jeu
  static const int minPlayersToStart = 2;
  static const int maxPlayersPerLobby = 30;
  static const int maxQuestionsPerQuiz = 30;
}

class AppEnvironment {
  static const bool isProduction = false;
  static const bool enableLogging = true;
  static const bool enableFirebaseEmulator = false;
}
