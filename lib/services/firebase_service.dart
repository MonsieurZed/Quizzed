/// Firebase Service
///
/// Service principal pour l'initialisation et la gestion des connexions Firebase
/// Gère Firebase Auth, Firestore et Storage
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:quizzzed/private_key.dart';
import 'package:quizzzed/services/logger_service.dart';

class FirebaseService {
  final logger = LoggerService();
  static final FirebaseService _instance = FirebaseService._internal();

  // Singletons pour les services Firebase
  late final FirebaseAuth auth;
  late final FirebaseFirestore firestore;
  late final FirebaseStorage storage;

  bool _initialized = false;

  // Constructeur factory pour assurer un singleton
  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  // Initialise Firebase et ses services
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: PrivateKey.firebaseKey['apiKey']!,
          authDomain: PrivateKey.firebaseKey['authDomain']!,
          projectId: PrivateKey.firebaseKey['projectId']!,
          storageBucket: PrivateKey.firebaseKey['storageBucket']!,
          messagingSenderId: PrivateKey.firebaseKey['messagingSenderId']!,
          appId: PrivateKey.firebaseKey['appId']!,
          measurementId: PrivateKey.firebaseKey['measurementId']!,
          databaseURL: PrivateKey.firebaseKey['databaseURL']!,
        ),
      );

      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
      storage = FirebaseStorage.instance;

      // Configuration spécifique pour le développement
      if (kDebugMode) {
        // Firestore emulator settings if needed
        // FirebaseFirestore.instance.settings =
        //   Settings(host: 'localhost:8080', sslEnabled: false, persistenceEnabled: false);
      }

      _initialized = true;
      logger.info('Firebase initialized successfully');
    } catch (e, stackTrace) {
      logger.info(
        'Error initializing Firebase: $e',
        tag: 'FIREBASE',
        data: stackTrace,
      );
      rethrow;
    }
  }

  // Vérifie si un utilisateur est actuellement connecté
  bool get isUserLoggedIn => auth.currentUser != null;

  // Récupère l'utilisateur actuel
  User? get currentUser => auth.currentUser;

  // Obtient un stream d'état d'authentification
  Stream<User?> get authStateChanges => auth.authStateChanges();
}
