# Checklist d'amélioration pour Quizzed

Ce document transforme les recommandations d'amélioration de futur.md en une checklist pour suivre la progression.

## Code dupliqué et problèmes identifiés

- [x] 1. Gestion des objets Color dans les modèles
- [ ] 2. Structure des contrôleurs de lobby
- [x] 3. Validation redondante des données
- [ ] 4. Méthodes de conversion to/from Map
- [x] 5. Gestion des erreurs inconsistante
- [ ] 6. Méthodes de requêtes Firebase dupliquées
- [ ] 7. Duplication entre `createLobby` et `_legacyCreateLobby`
- [ ] 8. Vues redondantes pour les lobbies

## Plan d'amélioration structuré

### Phase 1: Correction des bugs critiques et refactorisation de base

#### Étape 1: Unifier la gestion des objets Color

- [x] Création de la classe utilitaire `ColorUtils` dans `lib/utils/color_utils.dart`
- [x] Implémentation des méthodes standards pour convertir les couleurs
- [x] Remplacement de tout le code de conversion de couleurs dans les modèles
- [x] Fusion de ProfileColor avec AppConfig et suppression du fichier séparé

#### Étape 2: Centraliser la validation des données

- [x] Créer une classe `ValidationService` dans `lib/services/validation_service.dart`
- [x] Déplacer la logique de validation des formulaires depuis les vues vers ce service
- [x] Utiliser ce service dans les contrôleurs et les vues

#### Étape 3: Améliorer la gestion des erreurs

- [x] Étendre `ErrorMessageService` pour centraliser tous les messages d'erreur
- [x] Standardiser l'utilisation des codes d'erreur à travers l'application
- [x] Ajouter des méthodes pour la journalisation cohérente des erreurs

### Phase 2: Refactorisation des modèles et services

#### Étape 4: Créer une classe de base pour les modèles

- [ ] Créer une classe abstraite `BaseModel` dans `lib/models/base_model.dart`
- [ ] Implémenter des méthodes génériques `toMap()` et `fromMap()`
- [ ] Étendre tous les modèles existants depuis cette classe de base
- [ ] Utiliser des génériques pour rendre le code plus type-safe

#### Étape 5: Réorganiser les helpers Firebase

- [ ] Consolider les helpers existants (`firestore_helper.dart`, `cloud_storage_helper.dart`)
- [ ] Créer une classe `FirebaseRepository<T>` générique pour les opérations CRUD
- [ ] Implémenter des méthodes standards comme `getById`, `create`, `update`, `delete`

#### Étape 6: Standardiser les services Firebase

- [ ] Refactoriser les services pour utiliser la nouvelle classe `FirebaseRepository`
- [ ] Éliminer la duplication dans les requêtes Firebase de base
- [ ] Ajouter une gestion de cache cohérente

### Phase 3: Optimisation de l'architecture

#### Étape 7: Restructurer la hiérarchie des contrôleurs

- [ ] Refactoriser `LobbyBaseController` pour extraire plus de fonctionnalités communes
- [ ] Unifier `_legacyCreateLobby` et `createLobby` en une seule méthode paramétrable
- [ ] Améliorer la séparation des responsabilités entre les contrôleurs

#### Étape 8: Nettoyage des vues dupliquées

- [ ] Consolider `create_lobby_view.dart` et `create_lobby_screen.dart`
- [ ] Créer des composants partagés pour les éléments d'UI répétés
- [ ] Extraire la logique d'état des vues vers les contrôleurs

#### Étape 9: Améliorer la gestion des états

- [ ] Considérer l'utilisation de Riverpod ou un autre gestionnaire d'état plus avancé
- [ ] Réduire les appels à `notifyListeners()` inutiles
- [ ] Implémenter une stratégie de mise à jour sélective de l'UI

### Phase 4: Optimisations de performances et stabilité

#### Étape 10: Stratégie de mise en cache

- [ ] Implémenter un système de cache pour les données fréquemment utilisées
- [ ] Ajouter des mécanismes de pagination cohérents pour toutes les listes
- [ ] Réduire les requêtes Firebase redondantes

#### Étape 11: Tests unitaires et d'intégration

- [ ] Ajouter des tests unitaires pour les services et les contrôleurs
- [ ] Implémenter des tests d'intégration pour les flux principaux
- [ ] Créer des mocks pour Firebase dans les tests

#### Étape 12: Optimisation des performances UI

- [ ] Audit des performances avec Flutter DevTools
- [ ] Optimiser les rebuilds de widgets avec `const` et mémorisation
- [ ] Améliorer les animations et transitions

## Résumé de l'avancement

### Phases complétées

- Étape 1: Unifier la gestion des objets Color ✅
- Étape 2: Centraliser la validation des données ✅
- Étape 3: Améliorer la gestion des erreurs ✅

### Prochaines étapes

- Étape 4: Créer une classe de base pour les modèles
- Étape 5: Réorganiser les helpers Firebase
- Étape 6: Standardiser les services Firebase

## Notes sur les implémentations terminées

### Étape 1: Unifier la gestion des objets Color ✅

- Une classe utilitaire `ColorUtils` a été créée dans `lib/utils/color_utils.dart`
- Cette classe fournit des méthodes standardisées pour la manipulation et la conversion des couleurs
- Tout le code de conversion de couleurs des modèles utilise maintenant cette classe
- ProfileColor a été fusionné avec AppConfig pour centraliser la gestion des couleurs

### Étape 2: Centraliser la validation des données ✅

- Une classe `ValidationService` a été implémentée dans `lib/services/validation_service.dart`
- Toutes les validations sont maintenant centralisées dans cette classe
- Les vues utilisent maintenant ValidationService au lieu de validation inline
- Cela a permis d'unifier les règles de validation à travers l'application

### Étape 3: Améliorer la gestion des erreurs ✅

- ErrorMessageService a été étendu avec un modèle singleton et des méthodes centralisées
- Une méthode handleError centrale a été ajoutée pour standardiser le traitement des erreurs
- Un système de détection automatique de code d'erreur a été implémenté
- Les classes ErrorHandler ont été améliorées avec de nouvelles méthodes d'extension sur BuildContext
- Un exemple complet d'utilisation a été créé dans error_handling_example.dart
- LobbyController et LobbyBaseController ont été mis à jour pour utiliser le nouveau système
