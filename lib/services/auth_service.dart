/// Authentication Service
///
/// Gère toutes les opérations d'authentification utilisateur
/// S'appuie sur FirebaseService pour les opérations Firebase Auth
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/models/user/profile_color.dart';
import 'package:quizzzed/models/user/user_model.dart';
import 'package:quizzzed/private_key.dart';
import 'package:quizzzed/services/firebase_service.dart';
import 'package:quizzzed/services/logger_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();

  UserModel? _currentUserModel;
  bool _isLoading = false;

  // Getters
  User? get currentUser => _firebase.currentUser;
  UserModel? get currentUserModel => _currentUserModel;
  bool get isLoggedIn => _firebase.isUserLoggedIn;
  bool get isLoading => _isLoading;
  Stream<User?> get authStateChanges => _firebase.authStateChanges;
  final logTag = 'AuthService';
  final logger = LoggerService();

  AuthService() {
    // Initialiser l'écouteur pour les changements d'état d'authentification
    _firebase.authStateChanges.listen((User? user) async {
      if (user != null) {
        // L'utilisateur est connecté, charger ses données depuis Firestore
        await _loadUserData(user.uid);
      } else {
        // L'utilisateur est déconnecté
        _currentUserModel = null;
      }
      notifyListeners();
    });

    // Authentification automatique en mode debug
    if (kDebugMode) {
      _autoSignInForDebug();
    }
  }

  // Connexion automatique en mode debug avec les identifiants admin
  Future<void> _autoSignInForDebug() async {
    try {
      logger.debug(
        'Mode debug détecté: tentative de connexion automatique avec les identifiants admin',
        tag: logTag,
      );

      if (_firebase.isUserLoggedIn) {
        logger.debug('Déjà connecté, aucune action nécessaire', tag: logTag);
        return;
      }

      await signInWithEmailAndPassword(
        PrivateKey.admin_email,
        PrivateKey.admin_password,
      );

      logger.debug(
        'Connexion automatique en mode debug réussie avec: ${PrivateKey.admin_email}',
        tag: logTag,
      );
    } catch (e, stackTrace) {
      logger.warning(
        'Échec de la connexion automatique en mode debug: $e',
        tag: logTag,
        data: stackTrace,
      );
      // On ne propage pas l'erreur - c'est juste une facilité de développement
    }
  }

  // Charge les données de l'utilisateur depuis Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      DocumentSnapshot<Map<String, dynamic>> doc =
          await _firebase.firestore
              .collection(AppConfig.usersCollection)
              .doc(uid)
              .get();

      if (doc.exists) {
        _currentUserModel = UserModel.fromMap(doc.data()!);
      } else {
        logger.warning(
          'Aucune donnée utilisateur trouvée pour l\'UID: $uid',
          tag: logTag,
        ); // Si l'utilisateur existe dans Auth mais pas dans Firestore, on crée son document
        if (currentUser != null) {
          await _createUserDocument(currentUser!);
        }
      }
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors du chargement des données utilisateur: $e',
        tag: logTag,
        data: stackTrace,
      );

      // Gestion spécifique de l'erreur de permission
      if (e is FirebaseException && e.code == 'permission-denied') {
        // On crée un modèle utilisateur temporaire basé sur les données Firebase Auth
        // pour permettre à l'application de fonctionner même sans accès à Firestore
        if (currentUser != null) {
          final now = DateTime.now();
          _currentUserModel = UserModel(
            uid: currentUser!.uid,
            email: currentUser!.email ?? 'inconnu@email.com',
            displayName:
                currentUser!.displayName ??
                currentUser!.email?.split('@')[0] ??
                'Utilisateur',
            photoUrl: currentUser!.photoURL ?? AppConfig.defaultAvatarUrl,
            createdAt: now,
            lastLoginAt: now,
          );
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crée un nouveau document utilisateur dans Firestore
  Future<void> _createUserDocument(User user, {String? displayName}) async {
    try {
      final now = DateTime.now();

      // Utiliser la couleur bleu par défaut
      final defaultBackgroundColor =
          ProfileColor.availableColors[4].name; // Bleu

      UserModel newUser = UserModel(
        uid: user.uid,
        email: user.email!,
        displayName:
            displayName ?? user.displayName ?? user.email!.split('@')[0],
        photoUrl: user.photoURL ?? AppConfig.defaultAvatarUrl,
        avatarBackgroundColor: defaultBackgroundColor,
        createdAt: now,
        lastLoginAt: now,
      );

      await _firebase.firestore
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .set(newUser.toMap());

      _currentUserModel = newUser;
      notifyListeners();
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la création du document utilisateur: $e',
        tag: logTag,
        data: stackTrace,
      );
      // En cas d'échec, on utilise quand même un modèle local pour que l'app fonctionne
      if (e is FirebaseException && e.code == 'permission-denied') {
        final now = DateTime.now();
        _currentUserModel = UserModel(
          uid: user.uid,
          email: user.email!,
          displayName:
              displayName ?? user.displayName ?? user.email!.split('@')[0],
          photoUrl: user.photoURL ?? AppConfig.defaultAvatarUrl,
          createdAt: now,
          lastLoginAt: now,
        );
        notifyListeners();
      } else {
        rethrow;
      }
    }
  }

  // Met à jour la date de dernière connexion
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firebase.firestore
          .collection(AppConfig.usersCollection)
          .doc(uid)
          .update({'lastLoginAt': Timestamp.now()});
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la création du document utilisateur: $e',
        tag: logTag,
        data: stackTrace,
      );
      // On ignore cette erreur car elle n'est pas critique pour le fonctionnement de l'app
    }
  }

  // Connexion avec email et mot de passe
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _firebase.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        try {
          await _updateLastLogin(credential.user!.uid);
        } catch (e, stackTrace) {
          // On ignore l'erreur de mise à jour de dernière connexion
          logger.error('Erreur ignorée: $e', tag: logTag, data: stackTrace);
        }
        await _loadUserData(credential.user!.uid);
      }

      return _currentUserModel;
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la connexion: $e',
        tag: logTag,
        data: stackTrace,
      );
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Inscription avec email et mot de passe
  Future<UserModel?> createUserWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _firebase.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _createUserDocument(credential.user!, displayName: displayName);
      }

      return _currentUserModel;
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de l\'inscription: $e',
        tag: logTag,
        data: stackTrace,
      );
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Met à jour le profil utilisateur
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
    String? avatarBackgroundColor,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      if (currentUser == null || _currentUserModel == null) {
        throw Exception('Non authentifié');
      }

      _isLoading = true;
      notifyListeners();

      // Si le mot de passe doit être modifié
      if (currentPassword != null && newPassword != null) {
        // Récupérer les identifiants de connexion actuels pour vérifier l'ancien mot de passe
        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser!.email!,
          password: currentPassword,
        );

        // Ré-authentifier l'utilisateur avec les identifiants actuels
        await currentUser!.reauthenticateWithCredential(credential);

        // Changer le mot de passe
        await currentUser!.updatePassword(newPassword);

        logger.info('Mot de passe modifié avec succès', tag: logTag);
      }

      // Mettre à jour le profil Firebase Auth si nécessaire
      if (displayName != null) {
        await currentUser!.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await currentUser!.updatePhotoURL(photoUrl);
      }

      // Mettre à jour Firestore
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (avatarBackgroundColor != null) {
        updates['avatarBackgroundColor'] = avatarBackgroundColor;
      }

      if (updates.isNotEmpty) {
        await _firebase.firestore
            .collection(AppConfig.usersCollection)
            .doc(currentUser!.uid)
            .update(updates);

        // Mettre à jour le modèle local
        _currentUserModel = _currentUserModel!.copyWith(
          displayName: displayName ?? _currentUserModel!.displayName,
          photoUrl: photoUrl ?? _currentUserModel!.photoUrl,
          avatarBackgroundColor:
              avatarBackgroundColor ?? _currentUserModel!.avatarBackgroundColor,
        );

        // Synchroniser les changements dans tous les lobbies où l'utilisateur est présent
        if (displayName != null ||
            photoUrl != null ||
            avatarBackgroundColor != null) {
          _syncProfileUpdatesToLobbies(
            displayName: displayName,
            photoUrl: photoUrl,
            avatarBackgroundColor: avatarBackgroundColor,
          );
        }
      }
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la mise à jour du profil: $e',
        tag: logTag,
        data: stackTrace,
      );
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Synchronise les mises à jour de profil dans tous les lobbies où l'utilisateur est présent
  Future<void> _syncProfileUpdatesToLobbies({
    String? displayName,
    String? photoUrl,
    String? avatarBackgroundColor,
  }) async {
    try {
      if (currentUser == null) return;

      logger.info(
        'Synchronisation du profil mis à jour dans les lobbies actifs',
        tag: logTag,
      );

      // Rechercher tous les lobbies où l'utilisateur est présent
      final lobbiesQuery =
          await _firebase.firestore
              .collection('lobbies')
              .where('players', arrayContains: {'userId': currentUser!.uid})
              .get();

      // Cette requête ne fonctionnera pas directement avec Firestore, donc nous utilisons une approche différente
      // Rechercher tous les lobbies actifs
      final lobbiesSnapshot =
          await _firebase.firestore.collection('lobbies').get();

      int updatedLobbies = 0;

      // Pour chaque lobby, vérifier si l'utilisateur en fait partie et mettre à jour ses infos
      for (var lobbyDoc in lobbiesSnapshot.docs) {
        final lobbyData = lobbyDoc.data();
        final List<dynamic> players = lobbyData['players'] ?? [];

        // Rechercher l'index du joueur dans la liste
        int playerIndex = -1;
        for (int i = 0; i < players.length; i++) {
          if (players[i]['userId'] == currentUser!.uid) {
            playerIndex = i;
            break;
          }
        }

        // Si le joueur est trouvé dans ce lobby, mettre à jour ses informations
        if (playerIndex >= 0) {
          // Créer une copie de la liste des joueurs pour la modifier
          List<dynamic> updatedPlayers = List.from(players);

          // Mettre à jour les informations du joueur
          if (displayName != null) {
            updatedPlayers[playerIndex]['displayName'] = displayName;
          }
          if (photoUrl != null) {
            updatedPlayers[playerIndex]['avatarUrl'] = photoUrl;
          }
          if (avatarBackgroundColor != null) {
            updatedPlayers[playerIndex]['avatarBackgroundColor'] =
                avatarBackgroundColor;
          }

          // Mettre à jour le document du lobby
          await _firebase.firestore
              .collection('lobbies')
              .doc(lobbyDoc.id)
              .update({
                'players': updatedPlayers,
                'updatedAt': FieldValue.serverTimestamp(),
              });

          updatedLobbies++;
          logger.debug(
            'Profil mis à jour dans le lobby: ${lobbyDoc.id}',
            tag: logTag,
          );
        }
      }

      logger.info(
        'Profil utilisateur mis à jour dans $updatedLobbies lobbies',
        tag: logTag,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la synchronisation du profil dans les lobbies: $e',
        tag: logTag,
        data: stackTrace,
      );
      // On n'échoue pas la mise à jour du profil si la synchronisation échoue
    }
  }

  // Réinitialisation du mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebase.auth.sendPasswordResetEmail(email: email);
    } catch (e, stackTrace) {
      logger.error(
        'Erreur d\'envoi de l\'email de réinitialisation: $e',
        tag: logTag,
        data: stackTrace,
      );
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebase.auth.signOut();
      _currentUserModel = null;
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la déconnexion: $e',
        tag: logTag,
        data: stackTrace,
      );
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
