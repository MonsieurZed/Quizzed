/// Service de traitement par lots pour Firestore
///
/// Ce service permet d'optimiser les opérations d'écriture dans Firestore
/// en regroupant plusieurs opérations dans des lots (batches) pour réduire
/// le nombre d'appels réseau et améliorer les performances.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizzzed/services/logger_service.dart';

/// Service pour optimiser les écritures Firestore en utilisant des opérations par lots
class FirestoreBatchService {
  // Instance singleton
  static final FirestoreBatchService _instance =
      FirestoreBatchService._internal();
  factory FirestoreBatchService() => _instance;

  // Instance Firestore - initialisation différée
  // On n'accède pas directement à FirebaseFirestore.instance dans le constructeur
  late final FirebaseFirestore _firestore;
  bool _isFirestoreInitialized = false;

  // Logger
  final LoggerService _logger = LoggerService();

  // Taille maximale d'un lot (limite Firestore)
  static const int _maxBatchSize = 500;

  // Constructeur privé
  FirestoreBatchService._internal() {
    _logger.info('FirestoreBatchService initialisé', tag: 'FirestoreBatch');
  }

  // Initialise Firestore de manière sécurisée
  void _initFirestoreIfNeeded() {
    if (!_isFirestoreInitialized) {
      try {
        _firestore = FirebaseFirestore.instance;
        _isFirestoreInitialized = true;
        _logger.debug(
          'Firestore instance initialisée avec succès',
          tag: 'FirestoreBatch',
        );
      } catch (e) {
        _logger.error(
          'Erreur lors de l\'initialisation de Firestore: $e',
          tag: 'FirestoreBatch',
        );
        rethrow;
      }
    }
  }

  /// Statistiques des opérations par lots
  int _batchesCreated = 0;
  int _operationsExecuted = 0;
  int _documentsFetched = 0;

  /// Exécute plusieurs opérations d'écriture en une seule transaction réseau
  ///
  /// [operations] - Liste d'opérations à exécuter
  /// Retourne le nombre d'opérations exécutées avec succès
  Future<int> executeBatch(List<FirestoreBatchOperation> operations) async {
    if (operations.isEmpty) return 0;

    try {
      // S'assurer que Firestore est initialisé avant de l'utiliser
      _initFirestoreIfNeeded();

      // Créer des lots de taille appropriée pour respecter les limites de Firestore
      final List<List<FirestoreBatchOperation>> batches = _splitIntoBatches(
        operations,
      );
      _batchesCreated += batches.length;

      int successCount = 0;

      // Exécuter chaque lot
      for (final batchOperations in batches) {
        final batch = _firestore.batch();

        // Ajouter chaque opération au lot
        for (final operation in batchOperations) {
          switch (operation.type) {
            case BatchOperationType.set:
              batch.set(
                operation.reference,
                operation.data!,
                operation.options as SetOptions?,
              );
              break;
            case BatchOperationType.update:
              batch.update(operation.reference, operation.data!);
              break;
            case BatchOperationType.delete:
              batch.delete(operation.reference);
              break;
          }
        }

        // Exécuter le lot
        await batch.commit();
        successCount += batchOperations.length;
      }

      _operationsExecuted += successCount;
      _logger.debug(
        'Batch exécuté: $successCount opérations dans ${batches.length} lots',
        tag: 'FirestoreBatch',
      );
      return successCount;
    } catch (e) {
      _logger.error(
        'Erreur lors de l\'exécution du batch Firestore: $e',
        tag: 'FirestoreBatch',
      );
      rethrow;
    }
  }

  /// Exécute une opération de set sur plusieurs documents en une seule transaction réseau
  ///
  /// [data] - Map des références de documents aux données à définir
  /// [options] - Options de fusion (comme merge: true)
  Future<int> bulkSet(
    Map<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>> data, {
    SetOptions? options,
  }) async {
    final operations =
        data.entries
            .map(
              (entry) => FirestoreBatchOperation.set(
                entry.key,
                entry.value,
                options: options,
              ),
            )
            .toList();

    return await executeBatch(operations);
  }

  /// Exécute une opération de update sur plusieurs documents en une seule transaction réseau
  ///
  /// [data] - Map des références de documents aux données à mettre à jour
  Future<int> bulkUpdate(
    Map<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>> data,
  ) async {
    final operations =
        data.entries
            .map(
              (entry) => FirestoreBatchOperation.update(entry.key, entry.value),
            )
            .toList();

    return await executeBatch(operations);
  }

  /// Supprime plusieurs documents en une seule transaction réseau
  ///
  /// [references] - Liste des références de documents à supprimer
  Future<int> bulkDelete(
    List<DocumentReference<Map<String, dynamic>>> references,
  ) async {
    final operations =
        references
            .map((reference) => FirestoreBatchOperation.delete(reference))
            .toList();

    return await executeBatch(operations);
  }

  /// Exécute une opération conditionnelle sur plusieurs documents en fonction d'une requête
  ///
  /// [query] - Requête pour filtrer les documents
  /// [processDocument] - Fonction qui traite chaque document et retourne une opération par lots
  /// [maxLimit] - Nombre maximal de documents à traiter
  Future<int> conditionalBatchOperation(
    Query<Map<String, dynamic>> query,
    FirestoreBatchOperation Function(DocumentSnapshot<Map<String, dynamic>> doc)
    processDocument, {
    int maxLimit = 1000,
  }) async {
    try {
      // Exécuter la requête pour obtenir les documents
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await query.limit(maxLimit).get();
      _documentsFetched += snapshot.docs.length;

      if (snapshot.docs.isEmpty) return 0;

      // Créer une opération par lots pour chaque document
      final operations = snapshot.docs.map(processDocument).toList();

      // Exécuter les opérations par lots
      return await executeBatch(operations);
    } catch (e) {
      _logger.error(
        'Erreur lors de l\'opération conditionnelle par lots: $e',
        tag: 'FirestoreBatch',
      );
      rethrow;
    }
  }

  /// Incrémenter ou décrémenter un champ numérique pour plusieurs documents
  ///
  /// [references] - Liste des références de documents à mettre à jour
  /// [field] - Nom du champ à incrémenter
  /// [value] - Valeur à ajouter (peut être négative pour décrémenter)
  Future<int> bulkIncrement(
    List<DocumentReference<Map<String, dynamic>>> references,
    String field,
    num value,
  ) async {
    final operations =
        references
            .map(
              (reference) => FirestoreBatchOperation.update(reference, {
                field: FieldValue.increment(value),
              }),
            )
            .toList();

    return await executeBatch(operations);
  }

  /// Ajoute ou supprime des éléments dans un tableau pour plusieurs documents
  ///
  /// [references] - Liste des références de documents à mettre à jour
  /// [field] - Nom du champ de tableau
  /// [elements] - Éléments à ajouter ou supprimer
  /// [operation] - Type d'opération (arrayUnion ou arrayRemove)
  Future<int> bulkArrayOperation(
    List<DocumentReference<Map<String, dynamic>>> references,
    String field,
    List<dynamic> elements,
    ArrayOperationType operation,
  ) async {
    final FieldValue arrayOperation =
        operation == ArrayOperationType.union
            ? FieldValue.arrayUnion(elements)
            : FieldValue.arrayRemove(elements);

    final operations =
        references
            .map(
              (reference) => FirestoreBatchOperation.update(reference, {
                field: arrayOperation,
              }),
            )
            .toList();

    return await executeBatch(operations);
  }

  /// Met à jour un document s'il existe, sinon le crée avec les données par défaut
  ///
  /// [reference] - Référence du document
  /// [updateData] - Données pour la mise à jour
  /// [defaultData] - Données par défaut si le document n'existe pas
  Future<void> upsertDocument(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> updateData,
    Map<String, dynamic> defaultData,
  ) async {
    try {
      // S'assurer que Firestore est initialisé avant de l'utiliser
      _initFirestoreIfNeeded();

      final docSnapshot = await reference.get();
      _documentsFetched++;

      if (docSnapshot.exists) {
        // Document existe, mise à jour
        await reference.update(updateData);
      } else {
        // Document n'existe pas, création avec données par défaut
        await reference.set({...defaultData, ...updateData});
      }

      _operationsExecuted++;
    } catch (e) {
      _logger.error(
        'Erreur lors de l\'opération upsert: $e',
        tag: 'FirestoreBatch',
      );
      rethrow;
    }
  }

  /// Divise une liste d'opérations en lots de taille appropriée
  List<List<FirestoreBatchOperation>> _splitIntoBatches(
    List<FirestoreBatchOperation> operations,
  ) {
    final result = <List<FirestoreBatchOperation>>[];

    for (int i = 0; i < operations.length; i += _maxBatchSize) {
      final end =
          (i + _maxBatchSize < operations.length)
              ? i + _maxBatchSize
              : operations.length;
      result.add(operations.sublist(i, end));
    }

    return result;
  }

  /// Obtient les statistiques d'utilisation du service
  Map<String, dynamic> getStatistics() {
    return {
      'batchesCreated': _batchesCreated,
      'operationsExecuted': _operationsExecuted,
      'documentsFetched': _documentsFetched,
      'averageOperationsPerBatch':
          _batchesCreated > 0
              ? (_operationsExecuted / _batchesCreated).toStringAsFixed(2)
              : '0',
    };
  }

  /// Réinitialise les statistiques
  void resetStatistics() {
    _batchesCreated = 0;
    _operationsExecuted = 0;
    _documentsFetched = 0;
  }
}

/// Types d'opérations par lots supportées
enum BatchOperationType { set, update, delete }

/// Types d'opérations sur les tableaux
enum ArrayOperationType { union, remove }

/// Classe représentant une opération par lots Firestore
class FirestoreBatchOperation {
  final DocumentReference<Map<String, dynamic>> reference;
  final BatchOperationType type;
  final Map<String, dynamic>? data;
  final Object? options;

  /// Constructeur privé
  FirestoreBatchOperation._(this.reference, this.type, this.data, this.options);

  /// Crée une opération de type "set"
  static FirestoreBatchOperation set(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> data, {
    SetOptions? options,
  }) {
    return FirestoreBatchOperation._(
      reference,
      BatchOperationType.set,
      data,
      options,
    );
  }

  /// Crée une opération de type "update"
  static FirestoreBatchOperation update(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> data,
  ) {
    return FirestoreBatchOperation._(
      reference,
      BatchOperationType.update,
      data,
      null,
    );
  }

  /// Crée une opération de type "delete"
  static FirestoreBatchOperation delete(
    DocumentReference<Map<String, dynamic>> reference,
  ) {
    return FirestoreBatchOperation._(
      reference,
      BatchOperationType.delete,
      null,
      null,
    );
  }

  @override
  String toString() =>
      'FirestoreBatchOperation(type: $type, ref: ${reference.path})';
}
