/// Service de gestion des listeners Firestore
///
/// Ce service optimise l'utilisation des listeners Firestore en les partageant
/// entre différentes parties de l'application, réduisant ainsi la charge réseau.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizzzed/services/logger_service.dart';

/// Gestionnaire de listeners Firestore
class FirestoreListenerManager {
  // Instance singleton
  static final FirestoreListenerManager _instance =
      FirestoreListenerManager._internal();
  factory FirestoreListenerManager() => _instance;

  // Map des listeners de documents actifs
  final Map<String, _SharedDocumentListener> _documentListeners = {};

  // Map des listeners de collections actifs
  final Map<String, _SharedCollectionListener> _collectionListeners = {};

  // Service de journalisation
  final LoggerService _logger = LoggerService();

  // Constructeur privé
  FirestoreListenerManager._internal() {
    _logger.info(
      'FirestoreListenerManager initialisé',
      tag: 'FirestoreListeners',
    );
  }

  /// Écoute un document avec un listener partagé
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToDocument(
    DocumentReference<Map<String, dynamic>> reference, {
    String? clientId,
  }) {
    final path = reference.path;
    final client =
        clientId ?? 'anonymous-${DateTime.now().millisecondsSinceEpoch}';

    // Si le listener existe déjà, on l'utilise
    if (_documentListeners.containsKey(path)) {
      _logger.debug(
        'Réutilisation du listener pour document: $path',
        tag: 'FirestoreListeners',
      );
      return _documentListeners[path]!.addClient(client);
    }

    // Sinon, on crée un nouveau listener avec une création sécurisée
    _logger.debug(
      'Création d\'un nouveau listener pour document: $path',
      tag: 'FirestoreListeners',
    );

    try {
      final listener = _SharedDocumentListener(reference);
      _documentListeners[path] = listener;
      return listener.addClient(client);
    } catch (e) {
      _logger.error(
        'Erreur lors de la création du listener de document: $e',
        tag: 'FirestoreListeners',
      );

      // Retourner un stream vide en cas d'erreur d'initialisation
      // Cela évite un crash complet de l'application
      final controller =
          StreamController<DocumentSnapshot<Map<String, dynamic>>>();
      controller.close();
      return controller.stream;
    }
  }

  /// Écoute une collection avec un listener partagé
  Stream<QuerySnapshot<Map<String, dynamic>>> listenToCollection(
    Query<Map<String, dynamic>> query, {
    String? clientId,
  }) {
    try {
      final cacheKey = _getQueryCacheKey(query);
      final client =
          clientId ?? 'anonymous-${DateTime.now().millisecondsSinceEpoch}';

      // Si le listener existe déjà, on l'utilise
      if (_collectionListeners.containsKey(cacheKey)) {
        _logger.debug(
          'Réutilisation du listener pour collection: $cacheKey',
          tag: 'FirestoreListeners',
        );
        return _collectionListeners[cacheKey]!.addClient(client);
      }

      // Sinon, on crée un nouveau listener avec une création sécurisée
      _logger.debug(
        'Création d\'un nouveau listener pour collection: $cacheKey',
        tag: 'FirestoreListeners',
      );

      final listener = _SharedCollectionListener(query);
      _collectionListeners[cacheKey] = listener;
      return listener.addClient(client);
    } catch (e) {
      _logger.error(
        'Erreur lors de la création du listener de collection: $e',
        tag: 'FirestoreListeners',
      );

      // Retourner un stream vide en cas d'erreur d'initialisation
      final controller =
          StreamController<QuerySnapshot<Map<String, dynamic>>>();
      controller.close();
      return controller.stream;
    }
  }

  /// Arrête l'écoute d'un document pour un client spécifique
  void stopListeningToDocument(
    DocumentReference<Map<String, dynamic>> reference, {
    String? clientId,
  }) {
    final path = reference.path;
    final client = clientId ?? 'anonymous';

    if (_documentListeners.containsKey(path)) {
      _documentListeners[path]!.removeClient(client);

      // Si plus aucun client n'écoute, on supprime le listener
      if (_documentListeners[path]!.clientCount == 0) {
        _logger.debug(
          'Suppression du listener pour document: $path',
          tag: 'FirestoreListeners',
        );
        _documentListeners[path]!.dispose();
        _documentListeners.remove(path);
      }
    }
  }

  /// Arrête l'écoute d'une collection pour un client spécifique
  void stopListeningToCollection(
    Query<Map<String, dynamic>> query, {
    String? clientId,
  }) {
    final cacheKey = _getQueryCacheKey(query);
    final client = clientId ?? 'anonymous';

    if (_collectionListeners.containsKey(cacheKey)) {
      _collectionListeners[cacheKey]!.removeClient(client);

      // Si plus aucun client n'écoute, on supprime le listener
      if (_collectionListeners[cacheKey]!.clientCount == 0) {
        _logger.debug(
          'Suppression du listener pour collection: $cacheKey',
          tag: 'FirestoreListeners',
        );
        _collectionListeners[cacheKey]!.dispose();
        _collectionListeners.remove(cacheKey);
      }
    }
  }

  /// Arrête tous les listeners pour un client spécifique
  void stopAllListenersForClient(String clientId) {
    // Arrêter les listeners de documents
    List<String> documentsToCheck = List.from(_documentListeners.keys);
    for (var path in documentsToCheck) {
      if (_documentListeners.containsKey(path)) {
        _documentListeners[path]!.removeClient(clientId);

        // Si plus aucun client n'écoute, on supprime le listener
        if (_documentListeners[path]!.clientCount == 0) {
          _logger.debug(
            'Suppression du listener pour document: $path',
            tag: 'FirestoreListeners',
          );
          _documentListeners[path]!.dispose();
          _documentListeners.remove(path);
        }
      }
    }

    // Arrêter les listeners de collections
    List<String> collectionsToCheck = List.from(_collectionListeners.keys);
    for (var cacheKey in collectionsToCheck) {
      if (_collectionListeners.containsKey(cacheKey)) {
        _collectionListeners[cacheKey]!.removeClient(clientId);

        // Si plus aucun client n'écoute, on supprime le listener
        if (_collectionListeners[cacheKey]!.clientCount == 0) {
          _logger.debug(
            'Suppression du listener pour collection: $cacheKey',
            tag: 'FirestoreListeners',
          );
          _collectionListeners[cacheKey]!.dispose();
          _collectionListeners.remove(cacheKey);
        }
      }
    }
  }

  /// Obtient des statistiques sur les listeners actifs
  Map<String, dynamic> getListenerStats() {
    // Calculer le nombre total de clients uniques
    final Set<String> uniqueClients = {};

    // Ajouter tous les clients des listeners de documents
    for (final listener in _documentListeners.values) {
      uniqueClients.addAll(listener.clients.keys);
    }

    // Ajouter tous les clients des listeners de collections
    for (final listener in _collectionListeners.values) {
      uniqueClients.addAll(listener.clients.keys);
    }

    // Calculer le nombre de connexions économisées (total des clients moins nombre de streams)
    final int totalClients = uniqueClients.length;
    final int totalSharedStreams =
        _documentListeners.length + _collectionListeners.length;
    final int savedConnections =
        totalClients > totalSharedStreams
            ? totalClients - totalSharedStreams
            : 0;

    return {
      'activeDocumentListeners': _documentListeners.length,
      'activeCollectionListeners': _collectionListeners.length,
      'activeSharedStreams': totalSharedStreams,
      'uniqueClients': totalClients,
      'savedConnections': savedConnections,
    };
  }

  /// Ferme tous les listeners non utilisés
  void cleanupUnusedListeners() {
    // Identifier les listeners document sans clients
    final deadDocumentListeners = <String>[];
    for (final entry in _documentListeners.entries) {
      if (entry.value.clientCount == 0) {
        deadDocumentListeners.add(entry.key);
      }
    }

    // Supprimer les listeners document sans clients
    for (final key in deadDocumentListeners) {
      _documentListeners.remove(key);
      _logger.debug(
        'Suppression du listener inactif pour document: $key',
        tag: 'FirestoreListeners',
      );
    }

    // Identifier les listeners collection sans clients
    final deadCollectionListeners = <String>[];
    for (final entry in _collectionListeners.entries) {
      if (entry.value.clientCount == 0) {
        deadCollectionListeners.add(entry.key);
      }
    }

    // Supprimer les listeners collection sans clients
    for (final key in deadCollectionListeners) {
      _collectionListeners.remove(key);
      _logger.debug(
        'Suppression du listener inactif pour collection: $key',
        tag: 'FirestoreListeners',
      );
    }

    // Journaliser le résultat du nettoyage
    if (deadDocumentListeners.isNotEmpty ||
        deadCollectionListeners.isNotEmpty) {
      _logger.info(
        'Nettoyage de ${deadDocumentListeners.length} listeners document et '
        '${deadCollectionListeners.length} listeners collection inactifs',
        tag: 'FirestoreListeners',
      );
    }
  }

  /// Obtient une clé de cache pour une requête
  String _getQueryCacheKey(Query<Map<String, dynamic>> query) {
    // Pour les requêtes simples, utiliser le chemin
    if (query is CollectionReference) {
      if (query is CollectionReference<Map<String, dynamic>>) {
        return query.path;
      }
      throw UnsupportedError(
        'Query type not supported for cache key generation',
      );
    }

    // Pour les requêtes complexes, utiliser le hash
    return query.toString();
  }
}

/// Classe interne pour gérer un listener de document partagé
class _SharedDocumentListener {
  final DocumentReference<Map<String, dynamic>> reference;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _stream;
  final Map<String, StreamController<DocumentSnapshot<Map<String, dynamic>>>>
  clients = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  final LoggerService _logger = LoggerService();
  bool _isInitialized = false;

  _SharedDocumentListener(this.reference) {
    _initializeStream();
  }

  // Initialisation sécurisée du stream
  void _initializeStream() {
    if (_isInitialized) return;

    try {
      // Créer le stream principal
      _stream = reference.snapshots();

      // S'abonner au stream Firestore
      _subscription = _stream.listen(
        (snapshot) {
          // Propager les données à tous les clients
          for (final controller in clients.values) {
            if (!controller.isClosed) {
              controller.add(snapshot);
            }
          }
        },
        onError: (error) {
          _logger.error(
            'Erreur sur le stream document ${reference.path}: $error',
            tag: 'FirestoreListeners',
          );

          // Propager les erreurs à tous les clients
          for (final controller in clients.values) {
            if (!controller.isClosed) {
              controller.addError(error);
            }
          }
        },
      );

      _isInitialized = true;
    } catch (e) {
      _logger.error(
        'Erreur lors de l\'initialisation du stream document: $e',
        tag: 'FirestoreListeners',
      );
      rethrow;
    }
  }

  /// Ajoute un client au listener partagé
  Stream<DocumentSnapshot<Map<String, dynamic>>> addClient(String clientId) {
    // Si le client existe déjà, retourner son stream
    if (clients.containsKey(clientId)) {
      return clients[clientId]!.stream;
    }

    // Créer un nouveau controller pour ce client
    final controller =
        StreamController<DocumentSnapshot<Map<String, dynamic>>>();

    // Ajouter un handler pour quand le client se désabonne
    controller.onCancel = () {
      // Nettoyer ce client quand il se désabonne
      removeClient(clientId);
    };

    // Enregistrer le client
    clients[clientId] = controller;

    return controller.stream;
  }

  /// Retire un client du listener partagé
  void removeClient(String clientId) {
    // Si le client n'existe pas, ne rien faire
    if (!clients.containsKey(clientId)) {
      return;
    }

    // Fermer le controller du client
    final controller = clients[clientId]!;
    if (!controller.isClosed) {
      controller.close();
    }

    // Supprimer le client
    clients.remove(clientId);
  }

  /// Obtient le nombre de clients actifs
  int get clientCount => clients.length;

  /// Ferme ce listener partagé
  void dispose() {
    // Annuler l'abonnement principal
    _subscription?.cancel();

    // Fermer tous les controllers clients
    for (final controller in clients.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }

    // Vider la liste des clients
    clients.clear();
    _isInitialized = false;
  }
}

/// Classe interne pour gérer un listener de collection partagé
class _SharedCollectionListener {
  final Query<Map<String, dynamic>> query;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  final Map<String, StreamController<QuerySnapshot<Map<String, dynamic>>>>
  clients = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final LoggerService _logger = LoggerService();
  bool _isInitialized = false;

  _SharedCollectionListener(this.query) {
    _initializeStream();
  }

  // Initialisation sécurisée du stream
  void _initializeStream() {
    if (_isInitialized) return;

    try {
      // Créer le stream principal
      _stream = query.snapshots();

      // S'abonner au stream Firestore
      _subscription = _stream.listen(
        (snapshot) {
          // Propager les données à tous les clients
          for (final controller in clients.values) {
            if (!controller.isClosed) {
              controller.add(snapshot);
            }
          }
        },
        onError: (error) {
          _logger.error(
            'Erreur sur le stream collection: $error',
            tag: 'FirestoreListeners',
          );

          // Propager les erreurs à tous les clients
          for (final controller in clients.values) {
            if (!controller.isClosed) {
              controller.addError(error);
            }
          }
        },
      );

      _isInitialized = true;
    } catch (e) {
      _logger.error(
        'Erreur lors de l\'initialisation du stream collection: $e',
        tag: 'FirestoreListeners',
      );
      rethrow;
    }
  }

  /// Ajoute un client au listener partagé
  Stream<QuerySnapshot<Map<String, dynamic>>> addClient(String clientId) {
    // Si le client existe déjà, retourner son stream
    if (clients.containsKey(clientId)) {
      return clients[clientId]!.stream;
    }

    // Créer un nouveau controller pour ce client
    final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>();

    // Ajouter un handler pour quand le client se désabonne
    controller.onCancel = () {
      // Nettoyer ce client quand il se désabonne
      removeClient(clientId);
    };

    // Enregistrer le client
    clients[clientId] = controller;

    return controller.stream;
  }

  /// Retire un client du listener partagé
  void removeClient(String clientId) {
    // Si le client n'existe pas, ne rien faire
    if (!clients.containsKey(clientId)) {
      return;
    }

    // Fermer le controller du client
    final controller = clients[clientId]!;
    if (!controller.isClosed) {
      controller.close();
    }

    // Supprimer le client
    clients.remove(clientId);
  }

  /// Obtient le nombre de clients actifs
  int get clientCount => clients.length;

  /// Ferme ce listener partagé
  void dispose() {
    // Annuler l'abonnement principal
    _subscription?.cancel();

    // Fermer tous les controllers clients
    for (final controller in clients.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }

    // Vider la liste des clients
    clients.clear();
    _isInitialized = false;
  }
}
