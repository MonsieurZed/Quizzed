import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quizzed/services/logging_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LoggingService _logger = LoggingService();

  // État du stream d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Vérifier si l'utilisateur est connecté
  bool get isLoggedIn => _auth.currentUser != null;

  // Connexion avec email et mot de passe (uniquement pour l'admin)
  Future<User?> signInAdmin(String email, String password) async {
    try {
      _logger.logInfo(
        'Admin login attempt for $email',
        'AuthService.signInAdmin',
      );
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.logInfo(
        'Admin login successful for $email',
        'AuthService.signInAdmin',
      );
      return result.user;
    } catch (e, stackTrace) {
      _logger.logError(
        'Admin login failed',
        e,
        stackTrace,
        'AuthService.signInAdmin',
      );
      debugPrint('Erreur de connexion: $e');
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      _logger.logInfo(
        'User signing out: ${currentUser?.email ?? "Unknown user"}',
        'AuthService.signOut',
      );
      await _auth.signOut();
      _logger.logInfo('User signed out successfully', 'AuthService.signOut');
    } catch (e, stackTrace) {
      _logger.logError('Sign out failed', e, stackTrace, 'AuthService.signOut');
      debugPrint('Erreur de déconnexion: $e');
      return;
    }
  }
}
