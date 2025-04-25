/// Main Entry Point
///
/// Point d'entrée principal de l'application Quizzzed
/// Configure Firebase, les providers et lance l'application
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/controllers/lobby/lobby_controller.dart';
import 'package:quizzzed/routes/app_routes.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/chat_service.dart';
import 'package:quizzzed/services/firebase_service.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:quizzzed/services/quiz/game_service.dart'; // Ajout de l'import du QuizService
import 'package:quizzzed/theme/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation du service de journalisation
  final logTag = 'main';
  final logger = LoggerService();
  logger.debug('Démarrage de l\'application', tag: 'INIT');

  // Initialisation de Firebase
  final FirebaseService firebaseService = FirebaseService();
  try {
    await firebaseService.initialize();
    logger.info('Firebase initialisé avec succès', tag: 'FIREBASE');
  } catch (e, stackTrace) {
    logger.error(
      'Erreur lors de l\'initialisation de Firebase',
      tag: 'FIREBASE',
      data: e,
    );
    logger.error(
      'Erreur lors de l\'initialisation de Firebase: $e',
      tag: logTag,
      data: stackTrace,
    );
    // Continue sans Firebase en mode développement
  }

  // Créer ThemeService en avance pour éviter les conflits
  final themeService = ThemeService();

  runApp(
    MultiProvider(
      providers: [
        // Services d'infrastructure
        Provider<FirebaseService>.value(value: firebaseService),

        // Gestion des thèmes - utilisez ChangeNotifierProvider.value pour éviter de recréer le service
        ChangeNotifierProvider<ThemeService>.value(value: themeService),

        // Gestion de l'authentification
        ChangeNotifierProvider(
          create: (context) {
            final authService = AuthService();
            // Connecter ThemeService à AuthService directement
            themeService.setAuthService(authService);
            return authService;
          },
        ),

        // Service de chat
        Provider<ChatService>(create: (_) => ChatService()),

        // Service de quiz
        ChangeNotifierProvider<GameService>(create: (context) => GameService()),

        // Controllers pour les fonctionnalités de lobby et session
        ChangeNotifierProxyProvider<FirebaseService, LobbyController>(
          create:
              (context) => LobbyController(
                firebaseService: context.read<FirebaseService>(),
                authService: context.read<AuthService>(),
                chatService: context.read<ChatService>(),
              ),
          update: (context, firebaseService, previous) => previous!,
        ),
      ],
      child: const QuizzzedApp(),
    ),
  );
}

class QuizzzedApp extends StatelessWidget {
  const QuizzzedApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final logger = LoggerService();
    logger.debug('Construction de l\'interface principale', tag: 'UI');

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: !AppEnvironment.isProduction,
      theme: themeService.lightTheme,
      darkTheme: themeService.darkTheme,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Configuration du routeur
      routerConfig: AppRoutes.router,

      // Builder modifié pour éviter les problèmes de cycle de vie
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        return Overlay(
          initialEntries: [OverlayEntry(builder: (context) => child)],
        );
      },
    );
  }
}
