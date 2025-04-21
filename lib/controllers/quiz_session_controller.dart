/// Quiz Session Controller
///
/// Contrôleur responsable de la gestion des sessions de quiz en cours
/// Gestion des états de la partie, des questions, des réponses et des scores

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizzzed/models/quiz/lobby_model.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/firebase_service.dart';
import 'package:quizzzed/services/logger_service.dart';

class QuizSessionController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final AuthService _authService;
  final LoggerService _logger = LoggerService();
  final String _logTag = 'QuizSessionController';

  // État du contrôleur
  bool _isLoading = false;
  String? _error;

  // Session en cours
  String? _currentSessionId;
  Map<String, dynamic>? _sessionData;
  List<LobbyPlayerModel> _players = [];
  bool _isHost = false;

  // Getters pour l'état
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentSessionId => _currentSessionId;
  Map<String, dynamic>? get sessionData => _sessionData;
  List<LobbyPlayerModel> get players => _players;
  bool get isHost => _isHost;

  // Référence à la collection de sessions dans Firestore
  CollectionReference get _sessionsRef =>
      _firebaseService.firestore.collection('quiz_sessions');

  // Construction du contrôleur avec injection des dépendances
  QuizSessionController({
    required FirebaseService firebaseService,
    required AuthService authService,
  }) : _firebaseService = firebaseService,
       _authService = authService {
    _logger.info('QuizSessionController initialized', tag: _logTag);
  }

  // Rejoindre une session existante
  Future<bool> joinSession(String sessionId) async {
    _setLoading(true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _handleError('Utilisateur non connecté', null);
        return false;
      }

      _logger.info(
        'User ${user.uid} joining session: $sessionId',
        tag: _logTag,
      );

      // Configurer un écouteur pour les mises à jour en temps réel
      _sessionsRef
          .doc(sessionId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                final data = snapshot.data() as Map<String, dynamic>;
                _sessionData = data;
                _currentSessionId = sessionId;

                // Extraire les joueurs
                final List<dynamic> playersData = data['players'] ?? [];
                _players =
                    playersData
                        .map((p) => LobbyPlayerModel.fromMap(p))
                        .toList();

                // Vérifier si l'utilisateur est l'hôte
                _isHost = data['hostId'] == user.uid;

                _logger.debug(
                  'Session updated: $_currentSessionId, players: ${_players.length}',
                  tag: _logTag,
                );
                notifyListeners();
              } else {
                _sessionData = null;
                _currentSessionId = null;
                _players = [];
                _logger.warning('Session not found: $sessionId', tag: _logTag);
                notifyListeners();
              }
            },
            onError: (e) {
              _handleError(
                'Erreur lors de l\'écoute des mises à jour de la session',
                e,
              );
            },
          );

      // Mettre à jour la dernière activité du joueur
      await _sessionsRef.doc(sessionId).update({
        'playerActivities': {user.uid: FieldValue.serverTimestamp()},
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _handleError('Erreur lors de la tentative de rejoindre la session', e);
      return false;
    }
  }

  // Quitter une session
  Future<bool> leaveSession() async {
    if (_currentSessionId == null) return true;

    try {
      final user = _authService.currentUser;
      if (user == null) {
        return false;
      }

      _logger.info(
        'User ${user.uid} leaving session: $_currentSessionId',
        tag: _logTag,
      );

      // Si l'utilisateur est l'hôte, terminer la session pour tous
      if (_isHost) {
        await _sessionsRef.doc(_currentSessionId).update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        });
        _logger.info('Host ended the session', tag: _logTag);
      }

      // Nettoyer l'état local
      _currentSessionId = null;
      _sessionData = null;
      _players = [];
      _isHost = false;
      notifyListeners();

      return true;
    } catch (e) {
      _handleError('Erreur lors de la tentative de quitter la session', e);
      return false;
    }
  }

  // Mettre à jour l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Gérer les erreurs
  void _handleError(String message, dynamic error) {
    _error = message;
    _isLoading = false;
    _logger.error('$message: $error', tag: _logTag);
    notifyListeners();
  }
}
