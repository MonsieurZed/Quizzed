/// Firebase Service
///
/// Service principal pour l'initialisation et la gestion des connexions Firebase
/// Gère Firebase Auth, Firestore et Storage
library;

import 'dart:async';
import 'dart:js' as js;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/private_key.dart';
import 'package:quizzzed/services/error_message_service.dart';
import 'package:quizzzed/services/helpers/firestore_optimization_service.dart';
import 'package:quizzzed/services/logger_service.dart';

class FirebaseService {
  final logger = LoggerService();
  final _errorService = ErrorMessageService();
  final String _logTag = 'FirebaseService';
  static final FirebaseService _instance = FirebaseService._internal();

  // Singletons pour les services Firebase
  late final FirebaseAuth auth;
  late final FirebaseFirestore firestore;
  late final FirebaseStorage storage;

  // Service d'optimisation Firestore
  late final FirestoreOptimizationService _optimizationService;

  bool _initialized = false;

  // Constructeur factory pour assurer un singleton
  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal() {
    _optimizationService = FirestoreOptimizationService();
  }

  // Initialise Firebase et ses services
  Future<void> initialize() async {
    // If already initialized, don't try again
    if (_initialized) {
      logger.debug(
        'Firebase already initialized, skipping initialization',
        tag: _logTag,
      );
      return;
    }

    try {
      // Choisir la méthode d'initialisation appropriée pour la plateforme
      if (kIsWeb) {
        // En environnement web, utiliser la configuration depuis window.firebaseConfig
        logger.debug('Initializing Firebase for web environment', tag: _logTag);
        await _initializeForWeb();
      } else {
        // Pour les environnements non-web, utiliser la configuration depuis private_key.dart
        logger.debug(
          'Initializing Firebase for non-web environment',
          tag: _logTag,
        );
        await _initializeForNative();
      }

      // Only initialize these fields if they haven't been initialized yet
      // This ensures we don't try to reinitialize late final fields
      if (!_initialized) {
        auth = FirebaseAuth.instance;
        firestore = FirebaseFirestore.instance;
        storage = FirebaseStorage.instance;

        // Configuration spécifique pour le développement
        if (kDebugMode) {
          // En mode debug, on utilise un cache plus court pour le développement
          _optimizationService.setDefaultCacheDuration(
            30,
          ); // 30 secondes en debug
        } else {
          // En production, on utilise un cache plus long
          _optimizationService.setDefaultCacheDuration(
            120,
          ); // 2 minutes en production
        }

        _initialized = true;
        logger.info('Firebase initialized successfully', tag: _logTag);
      }
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'initializing Firebase',
        tag: _logTag,
        error: e,
        errorCode: ErrorCode.firebaseError,
        stackTrace: stackTrace,
      );

      logger.error(
        'Firebase initialization failed: $errorMessage',
        tag: _logTag,
      );
      throw Exception(errorMessage);
    }
  }

  /// Initialisation Firebase pour le web - utilise la configuration dans window.firebaseConfig
  Future<void> _initializeForWeb() async {
    try {
      // Vérifier si la configuration est disponible
      final hasConfig = js.context.hasProperty('firebaseConfig');

      if (!hasConfig) {
        final errorMessage = _errorService.handleError(
          operation: 'initializing Firebase for web',
          tag: _logTag,
          error: 'Firebase configuration missing',
          errorCode: ErrorCode.configurationMissing,
        );
        throw Exception(errorMessage);
      }

      // Récupérer chaque valeur de configuration individuellement pour éviter les problèmes d'interopérabilité
      final config = js.context['firebaseConfig'];

      // Créer les options Firebase en extrayant directement chaque propriété
      final options = FirebaseOptions(
        apiKey: config['apiKey'] as String,
        appId: config['appId'] as String,
        messagingSenderId: config['messagingSenderId'] as String,
        projectId: config['projectId'] as String,
        authDomain: config['authDomain'] as String,
        databaseURL: config['databaseURL'] as String,
        storageBucket: config['storageBucket'] as String,
        measurementId: config['measurementId'] as String,
      );

      // Initialiser Firebase avec les options
      logger.debug(
        'Initializing Firebase Web with explicit options',
        tag: _logTag,
      );
      await Firebase.initializeApp(options: options);
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'initializing Firebase for web',
        tag: _logTag,
        error: e,
        errorCode: ErrorCode.firebaseInitError,
        stackTrace: stackTrace,
      );

      logger.error(
        'Firebase web initialization failed: $errorMessage',
        tag: _logTag,
      );
      throw Exception(errorMessage);
    }
  }

  /// Initialisation Firebase pour les plateformes natives - utilise la configuration depuis private_key.dart
  Future<void> _initializeForNative() async {
    try {
      // Verify that the private key configuration exists
      if (PrivateKey.firebaseKey.isEmpty) {
        final errorMessage = _errorService.handleError(
          operation: 'initializing Firebase for native platforms',
          tag: _logTag,
          error: 'Firebase configuration missing from PrivateKey.firebaseKey',
          errorCode: ErrorCode.configurationMissing,
        );
        throw Exception(errorMessage);
      }

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
    } catch (e, stackTrace) {
      final errorMessage = _errorService.handleError(
        operation: 'initializing Firebase for native platforms',
        tag: _logTag,
        error: e,
        errorCode: ErrorCode.firebaseInitError,
        stackTrace: stackTrace,
      );

      logger.error(
        'Firebase native initialization failed: $errorMessage',
        tag: _logTag,
      );
      throw Exception(errorMessage);
    }
  }

  // Vérifie si un utilisateur est actuellement connecté
  bool get isUserLoggedIn => auth.currentUser != null;

  // Récupère l'utilisateur actuel
  User? get currentUser => auth.currentUser;

  // Obtient un stream d'état d'authentification
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // MÉTHODES OPTIMISÉES POUR FIRESTORE
  // Ces méthodes utilisent le système de cache et de gestion des listeners

  /// Récupère un document avec mise en cache
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required DocumentReference<Map<String, dynamic>> docRef,
    int? ttlMinutes,
    bool forceRefresh = false,
  }) async {
    try {
      return await docRef.get();
    } catch (e, stackTrace) {
      logger.error(
        'Error getting document: $e',
        tag: 'FIREBASE',
        data: stackTrace,
      );
      rethrow;
    }
  }

  /// Récupère une collection avec mise en cache
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection({
    required CollectionReference<Map<String, dynamic>> colRef,
    int? ttlMinutes,
    bool forceRefresh = false,
  }) async {
    try {
      return await colRef.get();
    } catch (e, stackTrace) {
      logger.error(
        'Error getting collection: $e',
        tag: 'FIREBASE',
        data: stackTrace,
      );
      rethrow;
    }
  }

  /// S'abonne à un document avec optimisation des listeners
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> listenToDocument({
    required DocumentReference<Map<String, dynamic>> reference,
    required void Function(DocumentSnapshot<Map<String, dynamic>>) onData,
    void Function(Object)? onError,
    void Function()? onDone,
    bool cacheFirstResult = true,
  }) {
    final clientId =
        cacheFirstResult
            ? 'client_${DateTime.now().millisecondsSinceEpoch}'
            : null;
    final stream = _optimizationService.listenToDocument(
      reference,
      clientId: clientId,
    );
    return stream.listen(onData, onError: onError, onDone: onDone);
  }

  /// S'abonne à une collection avec optimisation des listeners
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> listenToCollection({
    required Query<Map<String, dynamic>> query,
    required void Function(QuerySnapshot<Map<String, dynamic>>) onData,
    void Function(Object)? onError,
    void Function()? onDone,
    bool cacheFirstResult = true,
  }) {
    final clientId =
        cacheFirstResult
            ? 'client_${DateTime.now().millisecondsSinceEpoch}'
            : null;
    final stream = _optimizationService.listenToCollection(
      query,
      clientId: clientId,
    );
    return stream.listen(onData, onError: onError, onDone: onDone);
  }

  /// Invalider le cache pour un document spécifique (à appeler après des mises à jour)
  void invalidateDocumentCache(
    DocumentReference<Map<String, dynamic>> reference,
  ) {
    _optimizationService.invalidateDocumentCache(reference);
  }

  /// Invalider le cache pour une collection spécifique (à appeler après des mises à jour)
  void invalidateCollectionCache(Query<Map<String, dynamic>> query) {
    _optimizationService.invalidateCollectionCache(query);
  }

  /// Invalider le cache pour un préfixe de collection (par exemple après une mise à jour de plusieurs documents liés)
  void invalidateCacheByPrefix(String pathPrefix) {
    _optimizationService.invalidateCacheByPath(pathPrefix);
  }

  /// Obtenir des statistiques sur les performances Firestore (cache et listeners)
  Map<String, dynamic> getFirestorePerformanceStats() {
    return _optimizationService.getPerformanceStats();
  }
}
