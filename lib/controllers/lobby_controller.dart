/// Lobby Controller
///
/// Contrôleur responsable de la gestion des lobbys de quiz
/// Interaction avec Firestore et gestion des états des lobbys

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizzzed/models/quiz/lobby_model.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/firebase_service.dart';
import 'package:quizzzed/services/logger_service.dart';

class LobbyController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final AuthService _authService;
  final LoggerService _logger = LoggerService();
  final String _logTag = 'LobbyController';

  // État du contrôleur
  bool _isLoading = false;
  String? _error;

  // Données des lobbys
  List<LobbyModel> _publicLobbies = [];
  LobbyModel? _currentLobby;

  // Getters pour l'état
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<LobbyModel> get publicLobbies => _publicLobbies;
  LobbyModel? get currentLobby => _currentLobby;

  // Référence à la collection de lobbys dans Firestore
  CollectionReference get _lobbiesRef =>
      _firebaseService.firestore.collection('lobbies');

  // Construction du contrôleur avec injection des dépendances
  LobbyController({
    required FirebaseService firebaseService,
    required AuthService authService,
  }) : _firebaseService = firebaseService,
       _authService = authService {
    _logger.info('LobbyController initialized', tag: _logTag);
  }

  // Charger la liste des lobbys publics disponibles
  Future<void> loadPublicLobbies() async {
    _setLoading(true);

    try {
      _logger.debug('Loading public lobbies', tag: _logTag);

      // Récupérer les lobbys publics qui ne sont pas en cours et pas complets
      final snapshot =
          await _lobbiesRef
              .where('visibility', isEqualTo: 'public')
              .where('isInProgress', isEqualTo: false)
              .orderBy('createdAt', descending: true)
              .get();

      // Convertir les documents en modèles
      _publicLobbies =
          snapshot.docs
              .map(
                (doc) => LobbyModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .where((lobby) => lobby.players.length < lobby.maxPlayers)
              .toList();

      _logger.debug(
        'Loaded ${_publicLobbies.length} public lobbies',
        tag: _logTag,
      );
      _setLoading(false);
    } catch (e) {
      _handleError('Erreur lors du chargement des lobbys', e);
    }
  }

  // Charger un lobby spécifique par son ID
  Future<void> loadLobby(String lobbyId) async {
    _setLoading(true);

    try {
      _logger.debug('Loading lobby with ID: $lobbyId', tag: _logTag);

      // Configurer un écouteur pour les mises à jour en temps réel
      _lobbiesRef
          .doc(lobbyId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                _currentLobby = LobbyModel.fromMap(
                  snapshot.data() as Map<String, dynamic>,
                  snapshot.id,
                );
                notifyListeners();
                _logger.debug(
                  'Lobby updated: ${_currentLobby?.name}',
                  tag: _logTag,
                );
              } else {
                _currentLobby = null;
                notifyListeners();
                _logger.warning('Lobby not found: $lobbyId', tag: _logTag);
              }
            },
            onError: (e) {
              _handleError(
                'Erreur lors de l\'écoute des mises à jour du lobby',
                e,
              );
            },
          );

      _setLoading(false);
    } catch (e) {
      _handleError('Erreur lors du chargement du lobby', e);
    }
  }

  // Créer un nouveau lobby
  Future<String?> createLobby({
    required String name,
    required LobbyVisibility visibility,
    required int maxPlayers,
    required int minPlayers,
    required String category,
  }) async {
    _setLoading(true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _handleError('Utilisateur non connecté', null);
        return null;
      }

      _logger.info(
        'Creating new lobby: $name, visibility: $visibility, ' +
            'max players: $maxPlayers',
        tag: _logTag,
      );

      // Générer un code d'accès pour les lobbys privés
      String? accessCode;
      if (visibility == LobbyVisibility.private) {
        accessCode = GenerateAccessCode();
        _logger.debug('Generated access code: $accessCode', tag: _logTag);
      }

      // Créer le joueur hôte
      final hostPlayer = LobbyPlayerModel(
        userId: user.uid,
        displayName: user.displayName ?? 'Utilisateur',
        avatarUrl: user.photoURL ?? '',
        isHost: true,
        isReady: true,
        joinedAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      // Créer le lobby dans Firestore
      final docRef = await _lobbiesRef.add({
        'name': name,
        'hostId': user.uid,
        'category': category,
        'visibility':
            visibility == LobbyVisibility.private ? 'private' : 'public',
        'accessCode': accessCode,
        'maxPlayers': maxPlayers,
        'minPlayers': minPlayers,
        'isInProgress': false,
        'createdAt': FieldValue.serverTimestamp(),
        'players': [hostPlayer.toMap()],
      });

      _logger.info('Lobby created with ID: ${docRef.id}', tag: _logTag);
      _setLoading(false);
      return docRef.id;
    } catch (e) {
      _handleError('Erreur lors de la création du lobby', e);
      return null;
    }
  }

  // Rejoindre un lobby existant
  Future<bool> joinLobby(String lobbyId) async {
    _setLoading(true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _handleError('Utilisateur non connecté', null);
        return false;
      }

      _logger.info('User ${user.uid} joining lobby: $lobbyId', tag: _logTag);

      // Vérifier si le lobby existe et est rejoignable
      final lobbyDoc = await _lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        _handleError('Le lobby n\'existe pas', null);
        return false;
      }

      final lobbyData = lobbyDoc.data() as Map<String, dynamic>;
      final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

      // Vérifier si le lobby est plein
      if (lobby.players.length >= lobby.maxPlayers) {
        _handleError('Le lobby est complet', null);
        return false;
      }

      // Vérifier si le lobby est en cours
      if (lobby.isInProgress) {
        _handleError('Le lobby est déjà en cours de jeu', null);
        return false;
      }

      // Vérifier si l'utilisateur est déjà dans le lobby
      if (lobby.players.any((player) => player.userId == user.uid)) {
        _logger.info('User is already in the lobby', tag: _logTag);
        _setLoading(false);
        return true;
      }

      // Créer le joueur
      final newPlayer = LobbyPlayerModel(
        userId: user.uid,
        displayName: user.displayName ?? 'Utilisateur',
        avatarUrl: user.photoURL ?? '',
        isHost: false,
        isReady: false,
        joinedAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      // Ajouter le joueur au lobby
      await _lobbiesRef.doc(lobbyId).update({
        'players': FieldValue.arrayUnion([newPlayer.toMap()]),
      });

      _logger.info('User joined lobby successfully', tag: _logTag);
      _setLoading(false);
      return true;
    } catch (e) {
      _handleError('Erreur lors de la tentative de rejoindre le lobby', e);
      return false;
    }
  }

  // Rejoindre un lobby privé avec un code
  Future<bool> joinPrivateLobby(String lobbyId, String code) async {
    _setLoading(true);

    try {
      final lobbyDoc = await _lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        _handleError('Le lobby n\'existe pas', null);
        return false;
      }

      final lobbyData = lobbyDoc.data() as Map<String, dynamic>;

      // Vérifier si le code est correct
      if (lobbyData['accessCode'] != code) {
        _handleError('Code d\'accès incorrect', null);
        return false;
      }

      // Rejoindre le lobby
      return await joinLobby(lobbyId);
    } catch (e) {
      _handleError(
        'Erreur lors de la tentative de rejoindre le lobby privé',
        e,
      );
      return false;
    }
  }

  // Rejoindre un lobby en utilisant uniquement son code
  Future<String?> joinLobbyByCode(String code) async {
    _setLoading(true);

    try {
      _logger.debug('Searching for lobby with code: $code', tag: _logTag);

      // Chercher le lobby avec le code spécifié
      final snapshot =
          await _lobbiesRef.where('accessCode', isEqualTo: code).limit(1).get();

      if (snapshot.docs.isEmpty) {
        _handleError('Aucun lobby trouvé avec ce code', null);
        return null;
      }

      final lobbyId = snapshot.docs[0].id;
      final success = await joinLobby(lobbyId);

      _setLoading(false);
      return success ? lobbyId : null;
    } catch (e) {
      _handleError('Erreur lors de la recherche du lobby', e);
      return null;
    }
  }

  // Quitter un lobby
  Future<bool> leaveLobby(String lobbyId) async {
    _setLoading(true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _handleError('Utilisateur non connecté', null);
        return false;
      }

      _logger.info('User ${user.uid} leaving lobby: $lobbyId', tag: _logTag);

      // Récupérer les données du lobby
      final lobbyDoc = await _lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        _setLoading(false);
        return true; // Le lobby n'existe pas, on considère que l'utilisateur l'a quitté
      }

      final lobbyData = lobbyDoc.data() as Map<String, dynamic>;
      final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

      // Vérifier si l'utilisateur est l'hôte
      if (lobby.hostId == user.uid) {
        // Si l'utilisateur est l'hôte, supprimer le lobby
        await _lobbiesRef.doc(lobbyId).delete();
        _logger.info('Host left, lobby deleted: $lobbyId', tag: _logTag);
      } else {
        // Sinon, retirer l'utilisateur de la liste des joueurs
        final updatedPlayers =
            lobby.players
                .where((player) => player.userId != user.uid)
                .map((player) => player.toMap())
                .toList();

        await _lobbiesRef.doc(lobbyId).update({'players': updatedPlayers});
        _logger.info('Player removed from lobby', tag: _logTag);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _handleError('Erreur lors de la tentative de quitter le lobby', e);
      return false;
    }
  }

  // Changer le statut d'un joueur (prêt/en attente)
  Future<bool> togglePlayerStatus(String lobbyId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        _handleError('Utilisateur non connecté', null);
        return false;
      }

      _logger.debug('Toggling status for player ${user.uid}', tag: _logTag);

      // Récupérer les données du lobby
      final lobbyDoc = await _lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        _handleError('Le lobby n\'existe pas', null);
        return false;
      }

      final lobbyData = lobbyDoc.data() as Map<String, dynamic>;
      final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

      // L'hôte est toujours prêt
      if (lobby.hostId == user.uid) {
        return true;
      }

      // Trouver le joueur actuel
      int playerIndex = lobby.players.indexWhere((p) => p.userId == user.uid);
      if (playerIndex == -1) {
        _handleError('Joueur non trouvé dans le lobby', null);
        return false;
      }

      // Mettre à jour le statut du joueur
      List<Map<String, dynamic>> updatedPlayers =
          lobby.players.map((p) => p.toMap()).toList();
      updatedPlayers[playerIndex]['isReady'] =
          !lobby.players[playerIndex].isReady;
      updatedPlayers[playerIndex]['lastActive'] = Timestamp.fromDate(
        DateTime.now(),
      );

      // Mettre à jour le document
      await _lobbiesRef.doc(lobbyId).update({'players': updatedPlayers});

      _logger.debug(
        'Player status toggled to: ${updatedPlayers[playerIndex]['isReady']}',
        tag: _logTag,
      );
      return true;
    } catch (e) {
      _handleError('Erreur lors du changement de statut', e);
      return false;
    }
  }

  // Démarrer un quiz (hôte uniquement)
  Future<bool> startQuiz(String lobbyId) async {
    _setLoading(true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _handleError('Utilisateur non connecté', null);
        return false;
      }

      // Vérifier si l'utilisateur est l'hôte
      final lobbyDoc = await _lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        _handleError('Le lobby n\'existe pas', null);
        return false;
      }

      final lobbyData = lobbyDoc.data() as Map<String, dynamic>;
      final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

      if (lobby.hostId != user.uid) {
        _handleError('Seul l\'hôte peut démarrer le quiz', null);
        return false;
      }

      // Vérifier si tous les joueurs sont prêts
      final allPlayersReady =
          lobby.players.length >= lobby.minPlayers &&
          lobby.players.every((p) => p.isReady || p.userId == lobby.hostId);

      if (!allPlayersReady) {
        _handleError(
          'Tous les joueurs ne sont pas prêts ou nombre insuffisant de joueurs',
          null,
        );
        return false;
      }

      // Mettre à jour le statut du lobby
      await _lobbiesRef.doc(lobbyId).update({'isInProgress': true});

      _logger.info('Quiz started in lobby: $lobbyId', tag: _logTag);
      _setLoading(false);
      return true;
    } catch (e) {
      _handleError('Erreur lors du démarrage du quiz', e);
      return false;
    }
  }

  // Expulser un joueur (hôte uniquement)
  Future<bool> kickPlayer(String lobbyId, String playerId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        _handleError('Utilisateur non connecté', null);
        return false;
      }

      // Vérifier si l'utilisateur est l'hôte
      final lobbyDoc = await _lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        _handleError('Le lobby n\'existe pas', null);
        return false;
      }

      final lobbyData = lobbyDoc.data() as Map<String, dynamic>;
      final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

      if (lobby.hostId != user.uid) {
        _handleError('Seul l\'hôte peut expulser un joueur', null);
        return false;
      }

      // On ne peut pas expulser l'hôte
      if (playerId == lobby.hostId) {
        _handleError('L\'hôte ne peut pas être expulsé', null);
        return false;
      }

      // Retirer le joueur de la liste
      final updatedPlayers =
          lobby.players
              .where((player) => player.userId != playerId)
              .map((player) => player.toMap())
              .toList();

      await _lobbiesRef.doc(lobbyId).update({'players': updatedPlayers});

      _logger.info('Player $playerId kicked from lobby $lobbyId', tag: _logTag);
      return true;
    } catch (e) {
      _handleError('Erreur lors de l\'expulsion du joueur', e);
      return false;
    }
  }

  // Rejoindre un stream de lobby pour recevoir les mises à jour en temps réel
  Future<void> joinLobbyStream(String lobbyId) async {
    _setLoading(true);

    try {
      _logger.debug('Rejoindre le stream du lobby: $lobbyId', tag: _logTag);

      // Configurer un écouteur pour les mises à jour en temps réel
      _lobbiesRef
          .doc(lobbyId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                _currentLobby = LobbyModel.fromMap(
                  snapshot.data() as Map<String, dynamic>,
                  snapshot.id,
                );
                notifyListeners();
                _logger.debug(
                  'Lobby mis à jour: ${_currentLobby?.name}',
                  tag: _logTag,
                );
              } else {
                _currentLobby = null;
                notifyListeners();
                _logger.warning('Lobby non trouvé: $lobbyId', tag: _logTag);
              }
            },
            onError: (e) {
              _handleError(
                'Erreur lors de l\'écoute des mises à jour du lobby',
                e,
              );
            },
          );

      _setLoading(false);
    } catch (e) {
      _handleError('Erreur lors de la connexion au stream du lobby', e);
    }
  }

  // Se désabonner du stream du lobby
  void leaveLobbyStream() {
    _logger.debug('Quitter le stream du lobby', tag: _logTag);
    // L'implémentation actuelle ne nécessite pas de désabonnement explicite
    // car le stream sera automatiquement fermé lorsque le contrôleur sera disposé
  }

  // Démarrer une partie de quiz dans un lobby et créer une session
  Future<String?> startGame(String lobbyId) async {
    _setLoading(true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _handleError('Utilisateur non connecté', null);
        return null;
      }

      _logger.info(
        'Démarrage d\'une partie dans le lobby: $lobbyId',
        tag: _logTag,
      );

      // Vérifier si l'utilisateur est l'hôte
      final lobbyDoc = await _lobbiesRef.doc(lobbyId).get();
      if (!lobbyDoc.exists) {
        _handleError('Le lobby n\'existe pas', null);
        return null;
      }

      final lobbyData = lobbyDoc.data() as Map<String, dynamic>;
      final lobby = LobbyModel.fromMap(lobbyData, lobbyId);

      if (lobby.hostId != user.uid) {
        _handleError('Seul l\'hôte peut démarrer la partie', null);
        return null;
      }

      // Vérifier si tous les joueurs sont prêts
      if (!lobby.canStart) {
        _handleError(
          'Impossible de démarrer la partie : nombre insuffisant de joueurs ou joueurs non prêts',
          null,
        );
        return null;
      }

      // Créer une session de jeu
      final sessionRef = await _firebaseService.firestore
          .collection('quiz_sessions')
          .add({
            'lobbyId': lobbyId,
            'hostId': user.uid,
            'players': lobby.players.map((p) => p.toMap()).toList(),
            'status': 'starting',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Mettre à jour le statut du lobby
      await _lobbiesRef.doc(lobbyId).update({
        'isInProgress': true,
        'sessionId': sessionRef.id,
      });

      _logger.info('Session de jeu créée: ${sessionRef.id}', tag: _logTag);
      _setLoading(false);
      return sessionRef.id;
    } catch (e) {
      _handleError('Erreur lors du démarrage de la partie', e);
      return null;
    }
  }

  // Supprimer un joueur d'un lobby (action de l'hôte)
  Future<bool> removePlayerFromLobby(String lobbyId, String playerId) async {
    try {
      return await kickPlayer(lobbyId, playerId);
    } catch (e) {
      _handleError('Erreur lors de la suppression du joueur', e);
      return false;
    }
  }

  // Méthodes privées utilitaires

  // Mettre à jour l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Gérer les erreurs
  void _handleError(String message, dynamic error) {
    _error = message;
    _isLoading = false;
    _logger.error('$message : $error', tag: _logTag);
    notifyListeners();
  }

  // Générer un code d'accès aléatoire pour les lobbys privés
  static String GenerateAccessCode() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sans I, O, 0, 1 pour éviter confusion
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6, // Longueur du code
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ),
    );
  }
}
