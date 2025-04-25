/// Authentication Service
///
/// Gère toutes les opérations d'authentification utilisateur
/// S'appuie sur FirebaseService pour les opérations Firebase Auth
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/models/user/user_model.dart';
import 'package:quizzzed/private_key.dart';
import 'package:quizzzed/services/error_message_service.dart';
import 'package:quizzzed/services/firebase_service.dart';
import 'package:quizzzed/services/logger_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  final ErrorMessageService _errorMessageService = ErrorMessageService();

  UserModel? _currentUserModel;
  bool _isLoading = false;

  // Getters
  User? get currentFirebaseUser => _firebase.currentUser;
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
        if (currentFirebaseUser != null) {
          await _createUserDocument(currentFirebaseUser!);
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
        if (currentFirebaseUser != null) {
          final now = DateTime.now();
          _currentUserModel = UserModel(
            uid: currentFirebaseUser!.uid,
            email: currentFirebaseUser!.email ?? 'inconnu@email.com',
            displayName:
                currentFirebaseUser!.displayName ??
                currentFirebaseUser!.email?.split('@')[0] ??
                'Utilisateur',
            avatar:
                currentFirebaseUser!.photoURL ?? AppConfig.defaultUserAvatar,
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

      UserModel newUser = UserModel(
        uid: user.uid,
        email: user.email!,
        displayName:
            displayName ?? user.displayName ?? user.email!.split('@')[0],
        avatar: user.photoURL ?? AppConfig.defaultUserAvatar,
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
          avatar: user.photoURL ?? AppConfig.defaultUserAvatar,
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
      final errorCode = _mapAuthErrorToCode(e);
      final errorMessage = _errorMessageService.getUserMessage(errorCode);

      logger.error(
        'Erreur lors de la connexion: $errorMessage',
        tag: logTag,
        data: {
          'error': e.toString(),
          'errorCode': errorCode,
          'stackTrace': stackTrace,
        },
      );

      throw _errorMessageService.handleError(
        operation: errorMessage,
        errorCode: errorCode,
        error: e,
        stackTrace: stackTrace,
        tag: logTag,
      );
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
      final errorCode = _mapAuthErrorToCode(e);
      final errorMessage = _errorMessageService.getUserMessage(errorCode);

      logger.error(
        'Erreur lors de l\'inscription: $errorMessage',
        tag: logTag,
        data: {
          'error': e.toString(),
          'errorCode': errorCode,
          'stackTrace': stackTrace,
        },
      );

      throw _errorMessageService.getUserMessage(errorCode);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Met à jour le profil utilisateur
  Future<void> updateUserProfile({
    String? displayName,
    String? avatar,
    Color? userColor,
    String? currentPassword,
    String? newPassword,
    bool? isDarkMode,
  }) async {
    try {
      if (currentFirebaseUser == null || _currentUserModel == null) {
        throw _errorMessageService.handleError(
          errorCode: ErrorCode.notAuthenticated,
          operation: 'Utilisateur non authentifié',
          tag: logTag,
        );
      }

      _isLoading = true;
      notifyListeners();

      // Si le mot de passe doit être modifié
      if (currentPassword != null && newPassword != null) {
        try {
          // Récupérer les identifiants de connexion actuels pour vérifier l'ancien mot de passe
          AuthCredential credential = EmailAuthProvider.credential(
            email: currentFirebaseUser!.email!,
            password: currentPassword,
          );

          // Ré-authentifier l'utilisateur avec les identifiants actuels
          await currentFirebaseUser!.reauthenticateWithCredential(credential);

          // Changer le mot de passe
          await currentFirebaseUser!.updatePassword(newPassword);

          logger.info('Mot de passe modifié avec succès', tag: logTag);
        } catch (passwordError) {
          final errorCode = _mapAuthErrorToCode(passwordError);
          throw _errorMessageService.handleError(
            errorCode: errorCode,
            operation: 'Erreur de ré-authentification',
            tag: logTag,
            error: passwordError,
          );
        }
      }

      String? finalAvatar = avatar;

      // Mettre à jour le profil Firebase Auth si nécessaire
      if (displayName != null) {
        await currentFirebaseUser!.updateDisplayName(displayName);
      }
      if (finalAvatar != null) {
        await currentFirebaseUser!.updatePhotoURL(finalAvatar);
      }

      // Mettre à jour Firestore
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (finalAvatar != null) updates['avatar'] = finalAvatar;
      if (userColor != null) {
        // Convertir la couleur en valeur numérique avant de l'enregistrer
        updates['color'] = userColor.value.toString();
        // Mettre également à jour le champ 'color' pour assurer la cohérence
        updates['color'] = userColor.value.toString();
      }
      // Ajouter la mise à jour de la préférence de thème
      if (isDarkMode != null) {
        updates['isDarkMode'] = isDarkMode;
      }

      if (updates.isNotEmpty) {
        await _firebase.firestore
            .collection(AppConfig.usersCollection)
            .doc(currentFirebaseUser!.uid)
            .update(updates);

        // Mettre à jour le modèle local
        _currentUserModel = _currentUserModel!.copyWith(
          displayName: displayName ?? _currentUserModel!.displayName,
          avatar: finalAvatar,
          userColor: userColor?.value.toString(),
          isDarkMode: isDarkMode,
        );

        // Synchroniser les changements dans tous les lobbies où l'utilisateur est présent
        if (displayName != null || finalAvatar != null || userColor != null) {
          _syncProfileUpdatesToLobbies(
            displayName: displayName,
            photoUrl: finalAvatar,
            userColor: userColor?.value.toString(),
          );
        }
      }
    } catch (e, stackTrace) {
      final errorCode =
          e is Exception ? _mapAuthErrorToCode(e) : ErrorCode.unknown;
      final errorMessage = errorCode.defaultMessage;

      logger.error(
        'Erreur lors de la mise à jour du profil: $errorMessage',
        tag: logTag,
        data: {
          'error': e.toString(),
          'errorCode': errorCode,
          'stackTrace': stackTrace,
        },
      );

      throw _errorMessageService.handleError(
        errorCode: errorCode,
        error: e,
        operation: errorMessage,
        tag: logTag,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Synchronise les mises à jour de profil dans tous les lobbies où l'utilisateur est présent
  Future<void> _syncProfileUpdatesToLobbies({
    String? displayName,
    String? photoUrl,
    String? userColor,
  }) async {
    try {
      if (currentFirebaseUser == null) return;

      logger.info(
        'Synchronisation du profil mis à jour dans les lobbies actifs',
        tag: logTag,
      );

      // Vérifier si l'utilisateur est actuellement dans un lobby
      final currentLobbyId = _currentUserModel?.currentLobbyId;
      if (currentLobbyId != null) {
        logger.debug(
          'L\'utilisateur est actuellement dans le lobby $currentLobbyId, mise à jour prioritaire',
          tag: logTag,
        );

        // Traiter d'abord le lobby actuel pour une meilleure expérience utilisateur
        await _updatePlayerInLobby(
          currentLobbyId,
          displayName: displayName,
          photoUrl: photoUrl,
          color: userColor,
        );
      }

      // Rechercher tous les lobbies actifs où l'utilisateur pourrait être présent
      final lobbiesSnapshot =
          await _firebase.firestore
              .collection('lobbies')
              .where('isInProgress', isEqualTo: false)
              .get();

      int updatedLobbies = 0;

      // Pour chaque lobby, vérifier si l'utilisateur en fait partie et mettre à jour ses infos
      for (var lobbyDoc in lobbiesSnapshot.docs) {
        // Sauter le lobby actuel car il a déjà été mis à jour
        if (lobbyDoc.id == currentLobbyId) continue;

        if (await _updatePlayerInLobby(
          lobbyDoc.id,
          displayName: displayName,
          photoUrl: photoUrl,
          color: userColor,
        )) {
          updatedLobbies++;
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

  // Mise à jour d'un joueur dans un lobby spécifique
  Future<bool> _updatePlayerInLobby(
    String lobbyId, {
    String? displayName,
    String? photoUrl,
    String? color,
  }) async {
    try {
      final lobbyDoc =
          await _firebase.firestore.collection('lobbies').doc(lobbyId).get();

      if (!lobbyDoc.exists) return false;

      final lobbyData = lobbyDoc.data()!;
      final List<dynamic> players = lobbyData['players'] ?? [];

      // Rechercher l'index du joueur dans la liste
      int playerIndex = -1;
      for (int i = 0; i < players.length; i++) {
        if (players[i]['userId'] == currentFirebaseUser!.uid) {
          playerIndex = i;
          break;
        }
      }

      // Si le joueur est trouvé dans ce lobby, mettre à jour ses informations
      if (playerIndex >= 0) {
        // Créer une copie de la liste des joueurs pour la modifier
        List<dynamic> updatedPlayers = List.from(players);
        Map<String, dynamic> playerData = Map.from(updatedPlayers[playerIndex]);

        // Mettre à jour les informations du joueur
        bool hasChanges = false;

        if (displayName != null && playerData['displayName'] != displayName) {
          playerData['displayName'] = displayName;
          hasChanges = true;
        }

        if (photoUrl != null && playerData['avatarUrl'] != photoUrl) {
          playerData['avatarUrl'] = photoUrl;
          hasChanges = true;
        }

        if (color != null && playerData['color'] != color) {
          playerData['color'] = color;
          hasChanges = true;
        }

        // Ne mettre à jour que si des changements ont été détectés
        if (hasChanges) {
          // Remplacer les données du joueur dans la liste
          updatedPlayers[playerIndex] = playerData;

          // Mettre à jour le document du lobby
          await _firebase.firestore.collection('lobbies').doc(lobbyId).update({
            'players': updatedPlayers,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          logger.debug(
            'Profil mis à jour dans le lobby: $lobbyId',
            tag: logTag,
          );
          return true;
        }
      }

      return false;
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la mise à jour du joueur dans le lobby $lobbyId: $e',
        tag: logTag,
        data: stackTrace,
      );
      return false;
    }
  }

  // Réinitialisation du mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebase.auth.sendPasswordResetEmail(email: email);
    } catch (e, stackTrace) {
      final errorCode = _mapAuthErrorToCode(e);
      final errorMessage = _errorMessageService.handleError(
        errorCode: errorCode,
        operation: 'Erreur d\'envoi de l\'email de réinitialisation',
        tag: logTag,
        error: e,
        stackTrace: stackTrace,
      );

      logger.error(
        'Erreur d\'envoi de l\'email de réinitialisation: $errorMessage',
        tag: logTag,
        data: {
          'error': e.toString(),
          'errorCode': errorCode,
          'stackTrace': stackTrace,
        },
      );

      throw _errorMessageService.handleError(
        errorCode: errorCode,
        operation: errorMessage,
        error: e,
        stackTrace: stackTrace,
        tag: logTag,
      );
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

      // S'assurer que l'utilisateur quitte tous les lobbies avant de se déconnecter
      if (_currentUserModel?.currentLobbyId != null) {
        await updateCurrentLobby(null);
      }

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

  /// Met à jour le lobby actuel de l'utilisateur
  ///
  /// Si lobbyId est null, cela signifie que l'utilisateur quitte son lobby actuel
  /// Si previousLobbyId est fourni, on vérifie que l'utilisateur est bien dans ce lobby avant de le changer
  Future<void> updateCurrentLobby(
    String? lobbyId, {
    String? previousLobbyId,
  }) async {
    try {
      if (currentFirebaseUser == null || _currentUserModel == null) {
        throw Exception('Non authentifié');
      }

      // Si on fournit un previousLobbyId, vérifier que c'est bien le lobby actuel
      if (previousLobbyId != null &&
          _currentUserModel!.currentLobbyId != previousLobbyId) {
        logger.warning(
          'Tentative de changement de lobby avec un ID précédent incorrect',
          tag: logTag,
        );
        return; // On ne fait rien si le lobby précédent n'est pas le bon
      }

      _isLoading = true;
      notifyListeners();

      logger.info(
        lobbyId == null
            ? 'L\'utilisateur quitte son lobby actuel'
            : 'L\'utilisateur rejoint le lobby: $lobbyId',
        tag: logTag,
      );

      // Mettre à jour Firestore
      await _firebase.firestore
          .collection(AppConfig.usersCollection)
          .doc(currentFirebaseUser!.uid)
          .update({'currentLobbyId': lobbyId});

      // Mettre à jour le modèle local
      _currentUserModel = _currentUserModel!.copyWith(currentLobbyId: lobbyId);

      // Si l'utilisateur quitte un lobby (et pas pour en rejoindre un autre)
      // On peut nettoyer ses références dans ce lobby
      if (lobbyId == null && previousLobbyId != null) {
        await _cleanupUserFromLobby(previousLobbyId);
      }
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors de la mise à jour du lobby actuel: $e',
        tag: logTag,
        data: stackTrace,
      );
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nettoie la référence de l'utilisateur dans un lobby
  Future<void> _cleanupUserFromLobby(String lobbyId) async {
    try {
      if (currentFirebaseUser == null) return;

      final lobbyDoc =
          await _firebase.firestore.collection('lobbies').doc(lobbyId).get();

      if (!lobbyDoc.exists) {
        logger.debug(
          'Le lobby $lobbyId n\'existe plus, aucun nettoyage nécessaire',
          tag: logTag,
        );
        return;
      }

      final lobbyData = lobbyDoc.data()!;
      final List<dynamic> players = lobbyData['players'] ?? [];

      // Rechercher le joueur dans la liste
      int playerIndex = -1;
      for (int i = 0; i < players.length; i++) {
        if (players[i]['userId'] == currentFirebaseUser!.uid) {
          playerIndex = i;
          break;
        }
      }

      if (playerIndex >= 0) {
        // Supprimer le joueur de la liste
        List<dynamic> updatedPlayers = List.from(players);
        updatedPlayers.removeAt(playerIndex);

        // Mettre à jour le document du lobby
        await _firebase.firestore.collection('lobbies').doc(lobbyId).update({
          'players': updatedPlayers,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        logger.debug('Utilisateur retiré du lobby: $lobbyId', tag: logTag);
      }
    } catch (e, stackTrace) {
      logger.error(
        'Erreur lors du nettoyage du lobby: $e',
        tag: logTag,
        data: stackTrace,
      );
      // On n'échoue pas la mise à jour si le nettoyage échoue
    }
  }

  // Mapper les erreurs Firebase Auth vers nos codes d'erreur standardisés
  ErrorCode _mapAuthErrorToCode(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return ErrorCode.invalidEmail;
        case 'user-disabled':
          return ErrorCode.authUserDisabled;
        case 'user-not-found':
          return ErrorCode.authUserNotFound;
        case 'wrong-password':
          return ErrorCode.authWrongPassword;
        case 'email-already-in-use':
          return ErrorCode.authEmailAlreadyInUse;
        case 'operation-not-allowed':
          return ErrorCode.authOperationNotAllowed;
        case 'weak-password':
          return ErrorCode.authWeakPassword;
        case 'network-request-failed':
          return ErrorCode.networkError;
        case 'too-many-requests':
          return ErrorCode.authTooManyRequests;
        default:
          logger.warning(
            'Code d\'erreur Firebase Auth non géré: ${error.code}',
            tag: logTag,
          );
          return ErrorCode.authUnknown;
      }
    }
    return ErrorCode.unknown;
  }
}
