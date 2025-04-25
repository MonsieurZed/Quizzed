/// Service d'optimisation des requêtes Firestore
///
/// Ce service combine les fonctionnalités de mise en cache, de gestion
/// des listeners et de traitement par lots pour offrir une interface unifiée
/// d'accès optimisé aux données Firestore.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizzzed/services/helpers/firestore_batch_service.dart';
import 'package:quizzzed/services/helpers/firestore_cache_service.dart';
import 'package:quizzzed/services/helpers/firestore_listener_manager.dart';
import 'package:quizzzed/services/logger_service.dart';

/// Service d'optimisation Firestore
class FirestoreOptimizationService {
  // Instance singleton
  static final FirestoreOptimizationService _instance =
      FirestoreOptimizationService._internal();
  factory FirestoreOptimizationService() => _instance;

  // Services utilisés - initialisation différée
  late final FirestoreCacheService _cacheService;
  late final FirestoreListenerManager _listenerManager;
  late final FirestoreBatchService _batchService;
  final LoggerService _logger = LoggerService();

  // Indicateur d'initialisation
  bool _areServicesInitialized = false;

  // Cache des stats pour la surveillance des performances
  DateTime _lastStatsTime = DateTime.now();
  final Duration _statsInterval = const Duration(minutes: 5);

  // Durée de vie par défaut du cache en minutes
  int _defaultTTLMinutes = 5;

  // Constructeur privé
  FirestoreOptimizationService._internal() {
    _logger.info(
      'FirestoreOptimizationService initialisé',
      tag: 'FirestoreOpt',
    );
  }

  // Initialiser les services de manière sécurisée
  void _initServicesIfNeeded() {
    if (!_areServicesInitialized) {
      try {
        _cacheService = FirestoreCacheService();
        _listenerManager = FirestoreListenerManager();
        _batchService = FirestoreBatchService();
        _areServicesInitialized = true;

        // Démarrer la surveillance périodique des performances
        Timer.periodic(
          const Duration(minutes: 5),
          (_) => _logPerformanceStats(),
        );

        _logger.debug(
          'Services Firestore initialisés avec succès',
          tag: 'FirestoreOpt',
        );
      } catch (e) {
        _logger.error(
          'Erreur lors de l\'initialisation des services Firestore: $e',
          tag: 'FirestoreOpt',
        );
        rethrow;
      }
    }
  }

  /// Configure la durée de vie par défaut du cache
  void setDefaultCacheDuration(int minutes) {
    _defaultTTLMinutes = minutes;
  }

  //
  // SECTION 1: FONCTIONNALITÉS DE CACHE
  //

  /// Récupère un document avec mise en cache
  Future<Map<String, dynamic>?> getDocument({
    required DocumentReference<Map<String, dynamic>> docRef,
    int? ttlMinutes,
    bool forceRefresh = false,
  }) async {
    _initServicesIfNeeded();
    return await _cacheService.getDocument(
      docRef: docRef,
      ttlMinutes: ttlMinutes ?? _defaultTTLMinutes,
      forceRefresh: forceRefresh,
    );
  }

  /// Récupère une collection avec mise en cache
  Future<List<Map<String, dynamic>>> getCollection({
    required Query<Map<String, dynamic>> query,
    int? ttlMinutes,
    bool forceRefresh = false,
  }) async {
    _initServicesIfNeeded();
    return await _cacheService.getCollection(
      query: query,
      ttlMinutes: ttlMinutes ?? _defaultTTLMinutes,
      forceRefresh: forceRefresh,
    );
  }

  /// Invalide le cache pour un document spécifique
  void invalidateDocumentCache(
    DocumentReference<Map<String, dynamic>> reference,
  ) {
    _initServicesIfNeeded();
    _cacheService.invalidateDocument(reference);
  }

  /// Invalide le cache pour une collection spécifique
  void invalidateCollectionCache(Query<Map<String, dynamic>> query) {
    _initServicesIfNeeded();
    _cacheService.invalidateCollection(query);
  }

  /// Invalide le cache pour tous les documents et collections commençant par le préfixe spécifié
  void invalidateCacheByPath(String pathPrefix) {
    _initServicesIfNeeded();
    _cacheService.invalidateByPath(pathPrefix);
  }

  /// Vide tout le cache
  void clearCache() {
    _initServicesIfNeeded();
    _cacheService.clearCache();
  }

  //
  // SECTION 2: GESTION DES LISTENERS
  //

  /// S'abonne à un document avec optimisation des listeners
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToDocument(
    DocumentReference<Map<String, dynamic>> reference, {
    String? clientId,
  }) {
    _initServicesIfNeeded();
    // Utiliser le gestionnaire de listeners pour optimiser les abonnements
    return _listenerManager.listenToDocument(reference, clientId: clientId);
  }

  /// S'abonne à une collection avec optimisation des listeners
  Stream<QuerySnapshot<Map<String, dynamic>>> listenToCollection(
    Query<Map<String, dynamic>> query, {
    String? clientId,
  }) {
    _initServicesIfNeeded();
    // Utiliser le gestionnaire de listeners pour optimiser les abonnements
    return _listenerManager.listenToCollection(query, clientId: clientId);
  }

  /// Arrête l'écoute d'un document pour un client spécifique
  void stopListeningToDocument(
    DocumentReference<Map<String, dynamic>> reference, {
    String? clientId,
  }) {
    _initServicesIfNeeded();
    _listenerManager.stopListeningToDocument(reference, clientId: clientId);
  }

  /// Arrête l'écoute d'une collection pour un client spécifique
  void stopListeningToCollection(
    Query<Map<String, dynamic>> query, {
    String? clientId,
  }) {
    _initServicesIfNeeded();
    _listenerManager.stopListeningToCollection(query, clientId: clientId);
  }

  /// Arrête tous les listeners pour un client spécifique
  void stopAllListenersForClient(String clientId) {
    _initServicesIfNeeded();
    _listenerManager.stopAllListenersForClient(clientId);
  }

  /// Ferme tous les listeners non utilisés
  void cleanupUnusedListeners() {
    _initServicesIfNeeded();
    _listenerManager.cleanupUnusedListeners();
  }

  //
  // SECTION 3: OPÉRATIONS PAR LOTS
  //

  /// Exécute plusieurs opérations d'écriture par lots pour optimiser les performances
  Future<int> executeBatch(List<FirestoreBatchOperation> operations) {
    _initServicesIfNeeded();
    return _batchService.executeBatch(operations);
  }

  /// Définit plusieurs documents en une seule opération réseau
  Future<int> bulkSet(
    Map<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>> data, {
    SetOptions? options,
  }) {
    _initServicesIfNeeded();
    return _batchService.bulkSet(data, options: options);
  }

  /// Met à jour plusieurs documents en une seule opération réseau
  Future<int> bulkUpdate(
    Map<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>> data,
  ) {
    _initServicesIfNeeded();
    return _batchService.bulkUpdate(data);
  }

  /// Supprime plusieurs documents en une seule opération réseau
  Future<int> bulkDelete(
    List<DocumentReference<Map<String, dynamic>>> references,
  ) {
    _initServicesIfNeeded();
    return _batchService.bulkDelete(references);
  }

  /// Réalise une opération conditionnelle sur les documents correspondant à une requête
  Future<int> conditionalBatchOperation(
    Query<Map<String, dynamic>> query,
    FirestoreBatchOperation Function(DocumentSnapshot<Map<String, dynamic>> doc)
    processDocument, {
    int maxLimit = 1000,
  }) {
    _initServicesIfNeeded();
    return _batchService.conditionalBatchOperation(
      query,
      processDocument,
      maxLimit: maxLimit,
    );
  }

  /// Incrémente ou décrémente un champ numérique pour plusieurs documents
  Future<int> bulkIncrement(
    List<DocumentReference<Map<String, dynamic>>> references,
    String field,
    num value,
  ) {
    _initServicesIfNeeded();
    return _batchService.bulkIncrement(references, field, value);
  }

  /// Ajoute ou supprime des éléments dans un champ de tableau pour plusieurs documents
  Future<int> bulkArrayOperation(
    List<DocumentReference<Map<String, dynamic>>> references,
    String field,
    List<dynamic> elements,
    ArrayOperationType operation,
  ) {
    _initServicesIfNeeded();
    return _batchService.bulkArrayOperation(
      references,
      field,
      elements,
      operation,
    );
  }

  /// Met à jour un document s'il existe, sinon le crée avec les données par défaut
  Future<void> upsertDocument(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> updateData,
    Map<String, dynamic> defaultData,
  ) {
    _initServicesIfNeeded();
    return _batchService.upsertDocument(reference, updateData, defaultData);
  }

  //
  // SECTION 4: STATISTIQUES ET PERFORMANCE
  //

  /// Obtenir des statistiques combinées sur le cache et les listeners
  Map<String, dynamic> getPerformanceStats() {
    if (!_areServicesInitialized) {
      return {
        'cache': {
          'documentCacheSize': 0,
          'collectionCacheSize': 0,
          'cacheHits': 0,
          'cacheMisses': 0,
          'hitRate': 0,
          'fallbackHits': 0,
        },
        'listeners': {},
        'batch': {},
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Services not initialized',
      };
    }

    final cacheStats = _cacheService.getStatistics();
    final listenerStats = _listenerManager.getListenerStats();
    final batchStats = _batchService.getStatistics();

    return {
      'cache': {
        'documentCacheSize': cacheStats.documentCacheSize,
        'collectionCacheSize': cacheStats.collectionCacheSize,
        'cacheHits': cacheStats.cacheHits,
        'cacheMisses': cacheStats.cacheMisses,
        'hitRate': cacheStats.hitRate * 100, // Convert to percentage
        'fallbackHits': cacheStats.fallbackHits,
      },
      'listeners': listenerStats,
      'batch': batchStats,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'Services initialized',
    };
  }

  /// Journalise des statistiques de performance
  void _logPerformanceStats() {
    if (!_areServicesInitialized) return;

    final now = DateTime.now();
    if (now.difference(_lastStatsTime) >= _statsInterval) {
      try {
        final stats = getPerformanceStats();
        final cacheStats = stats['cache'] as Map<String, dynamic>;
        final listenerStats = stats['listeners'] as Map<String, dynamic>;
        final batchStats = stats['batch'] as Map<String, dynamic>;

        _logger.info(
          'Performances Firestore - '
          'Cache: ${cacheStats["hitRate"].toStringAsFixed(1)}% hits, '
          '${cacheStats["documentCacheSize"]} documents en cache. '
          'Listeners: ${listenerStats["activeSharedStreams"] ?? 0} streams partagés, '
          '${listenerStats["savedConnections"] ?? 0} connexions économisées. '
          'Batch: ${batchStats["batchesCreated"] ?? 0} lots, '
          '${batchStats["operationsExecuted"] ?? 0} opérations (moy. ${batchStats["averageOperationsPerBatch"] ?? 0} par lot).',
          tag: 'FirestoreOpt',
        );

        _lastStatsTime = now;
      } catch (e) {
        _logger.error(
          'Erreur lors de l\'enregistrement des statistiques: $e',
          tag: 'FirestoreOpt',
        );
      }
    }
  }
}
