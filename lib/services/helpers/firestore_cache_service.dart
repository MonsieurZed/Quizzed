import 'package:cloud_firestore/cloud_firestore.dart';

/// Service de mise en cache des requêtes Firestore pour optimiser les performances
class FirestoreCacheService {
  // Singleton pattern
  static final FirestoreCacheService _instance =
      FirestoreCacheService._internal();
  factory FirestoreCacheService() => _instance;
  FirestoreCacheService._internal();

  /// Cache pour les documents
  final Map<String, _CacheEntry<Map<String, dynamic>>> _documentCache = {};

  /// Cache pour les collections
  final Map<String, _CacheEntry<List<Map<String, dynamic>>>> _collectionCache =
      {};

  /// Statistiques de cache pour analyse de performance
  final _CacheStats _stats = _CacheStats();

  /// Durée de vie par défaut du cache en minutes
  final int _defaultTTLMinutes = 5;

  /// Taille maximale du cache (pour éviter la surcharge mémoire)
  final int _maxCacheSize = 100;

  /// Obtient un document depuis le cache ou Firestore
  ///
  /// [docRef] - Référence du document Firestore
  /// [ttlMinutes] - Durée de vie du cache en minutes (utilise la valeur par défaut si null)
  /// [forceRefresh] - Force une actualisation depuis Firestore
  Future<Map<String, dynamic>?> getDocument({
    required DocumentReference docRef,
    int? ttlMinutes,
    bool forceRefresh = false,
  }) async {
    final String cacheKey = docRef.path;
    final int ttl = ttlMinutes ?? _defaultTTLMinutes;

    // Vérifier si le document est dans le cache et toujours valide
    if (!forceRefresh && _documentCache.containsKey(cacheKey)) {
      final cacheEntry = _documentCache[cacheKey]!;
      if (!cacheEntry.isExpired()) {
        _stats.cacheHits++;
        return cacheEntry.data;
      }
    }

    // Si pas dans le cache ou expiré, récupérer depuis Firestore
    _stats.cacheMisses++;
    try {
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        // Mettre en cache le résultat
        _documentCache[cacheKey] = _CacheEntry<Map<String, dynamic>>(
          data: data,
          expiryTime: DateTime.now().add(Duration(minutes: ttl)),
        );

        // Gérer la taille maximale du cache
        _ensureCacheLimit();

        return data;
      }
      return null;
    } catch (e) {
      // En cas d'erreur, retourner la version en cache si disponible
      if (_documentCache.containsKey(cacheKey)) {
        _stats.fallbackHits++;
        return _documentCache[cacheKey]!.data;
      }
      rethrow;
    }
  }

  /// Obtient une collection depuis le cache ou Firestore
  ///
  /// [query] - Requête Firestore
  /// [ttlMinutes] - Durée de vie du cache en minutes (utilise la valeur par défaut si null)
  /// [forceRefresh] - Force une actualisation depuis Firestore
  Future<List<Map<String, dynamic>>> getCollection({
    required Query query,
    int? ttlMinutes,
    bool forceRefresh = false,
  }) async {
    // Générer une clé de cache unique pour cette requête
    final String cacheKey = _generateQueryCacheKey(query);
    final int ttl = ttlMinutes ?? _defaultTTLMinutes;

    // Vérifier si la collection est dans le cache et toujours valide
    if (!forceRefresh && _collectionCache.containsKey(cacheKey)) {
      final cacheEntry = _collectionCache[cacheKey]!;
      if (!cacheEntry.isExpired()) {
        _stats.cacheHits++;
        return cacheEntry.data;
      }
    }

    // Si pas dans le cache ou expiré, récupérer depuis Firestore
    _stats.cacheMisses++;
    try {
      final querySnapshot = await query.get();
      final List<Map<String, dynamic>> results =
          querySnapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList();

      // Mettre en cache le résultat
      _collectionCache[cacheKey] = _CacheEntry<List<Map<String, dynamic>>>(
        data: results,
        expiryTime: DateTime.now().add(Duration(minutes: ttl)),
      );

      // Gérer la taille maximale du cache
      _ensureCacheLimit();

      return results;
    } catch (e) {
      // En cas d'erreur, retourner la version en cache si disponible
      if (_collectionCache.containsKey(cacheKey)) {
        _stats.fallbackHits++;
        return _collectionCache[cacheKey]!.data;
      }
      rethrow;
    }
  }

  /// Invalide manuellement une entrée du cache pour un document spécifique
  void invalidateDocument(DocumentReference docRef) {
    final String cacheKey = docRef.path;
    _documentCache.remove(cacheKey);
  }

  /// Invalide manuellement une entrée du cache pour une collection spécifique
  void invalidateCollection(Query query) {
    final String cacheKey = _generateQueryCacheKey(query);
    _collectionCache.remove(cacheKey);
  }

  /// Invalide toutes les entrées du cache contenant le chemin spécifié
  void invalidateByPath(String path) {
    _documentCache.removeWhere((key, _) => key.contains(path));
    _collectionCache.removeWhere((key, _) => key.contains(path));
  }

  /// Obtient les statistiques du cache
  CacheStatistics getStatistics() {
    return CacheStatistics(
      documentCacheSize: _documentCache.length,
      collectionCacheSize: _collectionCache.length,
      cacheHits: _stats.cacheHits,
      cacheMisses: _stats.cacheMisses,
      fallbackHits: _stats.fallbackHits,
    );
  }

  /// Vide entièrement le cache
  void clearCache() {
    _documentCache.clear();
    _collectionCache.clear();
    _stats.reset();
  }

  /// Génère une clé de cache unique pour une requête
  /// Cette méthode tente de créer une représentation stable de la requête
  String _generateQueryCacheKey(Query query) {
    // Cette implémentation basique utilise le path de la collection
    // Dans une implémentation plus avancée, il faudrait aussi considérer
    // les filtres, les tris et les limites
    return query.toString();
  }

  /// Assure que le cache ne dépasse pas la taille limite
  void _ensureCacheLimit() {
    // Vérifier et nettoyer le cache des documents si nécessaire
    if (_documentCache.length > _maxCacheSize) {
      // Stratégie simple: supprimer les éléments les plus anciens
      final sortedEntries =
          _documentCache.entries.toList()
            ..sort((a, b) => a.value.expiryTime.compareTo(b.value.expiryTime));

      // Supprimer les 25% les plus anciens
      final itemsToRemove = (_documentCache.length * 0.25).ceil();
      for (int i = 0; i < itemsToRemove && i < sortedEntries.length; i++) {
        _documentCache.remove(sortedEntries[i].key);
      }
    }

    // Vérifier et nettoyer le cache des collections si nécessaire
    if (_collectionCache.length > _maxCacheSize) {
      final sortedEntries =
          _collectionCache.entries.toList()
            ..sort((a, b) => a.value.expiryTime.compareTo(b.value.expiryTime));

      final itemsToRemove = (_collectionCache.length * 0.25).ceil();
      for (int i = 0; i < itemsToRemove && i < sortedEntries.length; i++) {
        _collectionCache.remove(sortedEntries[i].key);
      }
    }
  }
}

/// Classe représentant une entrée dans le cache avec sa durée de vie
class _CacheEntry<T> {
  final T data;
  final DateTime expiryTime;

  _CacheEntry({required this.data, required this.expiryTime});

  /// Vérifie si l'entrée du cache est expirée
  bool isExpired() {
    return DateTime.now().isAfter(expiryTime);
  }
}

/// Statistiques du cache pour l'analyse de performances
class _CacheStats {
  int cacheHits = 0;
  int cacheMisses = 0;
  int fallbackHits = 0;

  void reset() {
    cacheHits = 0;
    cacheMisses = 0;
    fallbackHits = 0;
  }
}

/// Classe publique pour exposer les statistiques du cache
class CacheStatistics {
  final int documentCacheSize;
  final int collectionCacheSize;
  final int cacheHits;
  final int cacheMisses;
  final int fallbackHits;

  CacheStatistics({
    required this.documentCacheSize,
    required this.collectionCacheSize,
    required this.cacheHits,
    required this.cacheMisses,
    required this.fallbackHits,
  });

  /// Calcule le taux de succès du cache (hit rate)
  double get hitRate {
    final total = cacheHits + cacheMisses;
    if (total == 0) return 0.0;
    return cacheHits / total;
  }
}
