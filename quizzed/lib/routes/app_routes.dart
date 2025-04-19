import 'package:flutter/material.dart';
import 'package:quizzed/screens/admin/admin_login_screen.dart';
import 'package:quizzed/screens/home_screen.dart';
import 'package:quizzed/screens/player/player_login_screen.dart';
import 'package:quizzed/screens/admin/admin_dashboard_screen.dart';
import 'package:quizzed/screens/admin/quiz_creation_screen.dart';
import 'package:quizzed/screens/admin/quiz_session_management_screen.dart';
import 'package:quizzed/screens/player/quiz_lobby_screen.dart';
import 'package:quizzed/screens/player/quiz_session_screen.dart';
import 'package:quizzed/screens/player/results_screen.dart';
import 'package:quizzed/main.dart'; // Import for HomePage

class AppRoutes {
  static const String home = '/';
  static const String adminLogin = '/admin-login';
  static const String adminDashboard = '/admin-dashboard';
  static const String quizCreation = '/quiz-creation';
  static const String quizSessionManagement = '/quiz-session-management';
  static const String playerLogin = '/player-login';
  static const String quizLobby = '/quiz-lobby';
  static const String quizSession = '/quiz-session';
  static const String results = '/results';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomePage(),
    adminLogin: (context) => const AdminLoginScreen(),
    playerLogin: (context) => const PlayerLoginScreen(),
    adminDashboard: (context) => const AdminDashboardScreen(),
    quizCreation: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return QuizCreationScreen(sessionId: args?['sessionId']);
    },
    quizSessionManagement: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final sessionId = args?['sessionId'] as String;
      return QuizSessionManagementScreen(sessionId: sessionId);
    },
    quizLobby: (context) => const QuizLobbyScreen(),
    quizSession: (context) => const QuizSessionScreen(),
    results: (context) => const ResultsScreen(),
  };
}
