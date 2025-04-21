/// App Routes
///
/// Configuration des routes de l'application avec go_router
/// Gestion du routage et des redirections

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/views/auth/forgot_password_view.dart';
import 'package:quizzzed/views/auth/login_view.dart';
import 'package:quizzzed/views/auth/register_view.dart';
import 'package:quizzzed/views/debug/debug_view.dart';
import 'package:quizzzed/views/home/create_lobby_view.dart';
import 'package:quizzzed/views/home/home_view.dart';
import 'package:quizzzed/views/home/lobbies_view.dart';
import 'package:quizzzed/views/home/lobby_detail_view.dart';

class AppRoutes {
  // Noms des routes pour faciliter la navigation
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String home = 'home';
  static const String profile = 'profile';
  static const String editProfile = 'edit-profile';
  static const String quizCategories = 'quiz-categories';
  static const String quizCategoryDetail = 'quiz-category-detail';
  static const String debug = 'debug';

  // Nouvelles routes pour les lobbys
  static const String lobbies = 'lobbies';
  static const String createLobby = 'create-lobby';
  static const String lobbyDetail = 'lobby-detail';

  // Nouvelles routes pour les quiz sessions
  static const String quizSession = 'quiz-session';

  static final AuthService _authService = AuthService();

  // Configuration du routeur go_router
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true, // Debug logging (à supprimer en production)
    redirect: _handleRedirect,
    routes: [
      // Page d'accueil non authentifiée / splash screen
      GoRoute(
        path: '/',
        name: splash,
        builder:
            (context, state) => const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                      image: AssetImage('assets/images/logo.png'),
                      height: 150,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Bienvenue sur Quizzzed!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Le jeu de quiz qui vous rend plus intelligent',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
      ),

      // Routes d'authentification
      GoRoute(
        path: '/login',
        name: login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        name: register,
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: forgotPassword,
        builder: (context, state) => const ForgotPasswordView(),
      ),

      // Routes protégées (nécessitent authentification)
      GoRoute(
        path: '/home',
        name: home,
        builder: (context, state) => const HomeView(),
      ),

      // Routes des lobbys
      GoRoute(
        path: '/lobbies',
        name: lobbies,
        builder: (context, state) => const LobbiesView(),
      ),
      GoRoute(
        path: '/lobbies/create',
        name: createLobby,
        builder: (context, state) => const CreateLobbyView(),
      ),
      GoRoute(
        path: '/lobbies/:id',
        name: lobbyDetail,
        builder:
            (context, state) =>
                LobbyDetailView(lobbyId: state.pathParameters['id'] ?? ''),
      ),

      // Route de débogage (accessible uniquement en mode debug)
      GoRoute(
        path: '/debug',
        name: debug,
        builder: (context, state) => const DebugView(),
      ),
    ],
  );

  // Gestion des redirections basées sur l'état d'authentification
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    // Skip redirection during app initialization
    if (state.fullPath == '/') {
      // On laisse l'utilisateur voir la page de bienvenue pendant 2 secondes
      Future.delayed(const Duration(seconds: 2), () {
        if (_authService.isLoggedIn) {
          router.replace('/home');
        } else {
          router.replace('/login');
        }
      });
      return null;
    }

    // Permettre l'accès à la page de débogage sans authentification
    if (state.fullPath == '/debug') {
      return null;
    }

    final bool isLoggedIn = _authService.isLoggedIn;
    final bool isGoingToLogin =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/forgot-password';

    // Si l'utilisateur est connecté et essaie d'accéder à une page d'authentification,
    // rediriger vers la page d'accueil
    if (isLoggedIn && isGoingToLogin) {
      return '/home';
    }

    // Si l'utilisateur n'est pas connecté et essaie d'accéder à une page protégée,
    // rediriger vers la page de connexion
    if (!isLoggedIn && !isGoingToLogin && state.matchedLocation != '/') {
      return '/login';
    }

    // Aucune redirection nécessaire
    return null;
  }
}
