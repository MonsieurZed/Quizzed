import 'package:flutter/material.dart';
import 'package:quizzed/config/firebase_config.dart';
import 'package:quizzed/routes/app_routes.dart';
import 'package:quizzed/services/logging_service.dart';
import 'package:quizzed/services/theme_service.dart';
import 'dart:async';

final LoggingService _logger = LoggingService();

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      _logger.logInfo('Application starting', 'main');

      try {
        await FirebaseConfig.initializeFirebase();
        runApp(const MyApp());
      } catch (e, stackTrace) {
        _logger.logError('Failed to initialize app', e, stackTrace, 'main');
      }
    },
    (error, stack) {
      _logger.logError(
        'Uncaught exception',
        error,
        stack,
        'main.runZonedGuarded',
      );
    },
  );

  // Register error handlers for Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    _logger.logError(
      'Flutter framework error',
      details.exception,
      details.stack,
      'FlutterError.onError',
    );

    // Forward to framework
    FlutterError.presentError(details);
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Quizzed - Quiz LAN',
          debugShowCheckedModeBanner: false,
          theme: ThemeService.getLightTheme(),
          darkTheme: ThemeService.getDarkTheme(),
          themeMode: mode,
          initialRoute: AppRoutes.home,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
