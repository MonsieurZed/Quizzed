# Quizzed - Application interactive de quiz en temps réel

## Présentation

Quizzed est une application mobile et web développée avec Flutter qui permet aux utilisateurs de créer, rejoindre et participer à des sessions de quiz en temps réel. Le projet évolue actuellement vers une architecture plus générique de jeux interactifs, avec le quiz comme premier type de jeu implémenté.

## État actuel du projet

L'application dispose déjà de:

- Un système d'authentification complet (inscription, connexion, profil)
- Un système de lobby fonctionnel avec gestion des joueurs
- Un chat intégré dans les lobbies
- Une première version du système de quiz

## Plan de développement

### 1. Refactorisation du système de quiz en système de jeux

#### 1.1 Phase de préparation et documentation

- [x] Documenter l'arborescence des fichiers dans `lib/documentation/files.md`
- [x] Documenter les fonctions existantes pour chaque fichier
- [x] Créer une description générale du projet dans `lib/documentation/readme.md`
- [x] Identifier les fonctionnalités dupliquées à corriger

#### 1.2 Suppression et renommage

- [ ] Supprimer les fichiers et classes liés au système de quiz actuel
  - [ ] Fichiers dans `/lib/models/quiz/`
  - [ ] Contrôleurs liés aux quiz dans `/lib/controllers/`
  - [ ] Services dans `/lib/services/quiz/`
  - [ ] Vues liées aux quiz dans `/lib/views/`
  - [ ] Widgets liés aux quiz
- [ ] Créer le répertoire `/lib/models/game/` pour remplacer `/lib/models/quiz/`
- [ ] Créer le répertoire `/lib/services/game/` pour remplacer `/lib/services/quiz/`
- [ ] Mettre à jour les références dans la documentation

#### 1.3 Implémentation de l'architecture abstraite des jeux

- [ ] Créer une interface abstraite pour les jeux (`game_interface.dart`)
  - [ ] Définir les états possibles du jeu (en attente, en cours, terminé)
  - [ ] Définir les méthodes pour rejoindre/quitter un jeu
  - [ ] Définir les méthodes pour sauvegarder/restaurer l'état du jeu
- [ ] Créer un modèle de base pour les jeux (`base_game_model.dart`)
  - [ ] Implémenter les méthodes de sérialisation/désérialisation pour Firestore
- [ ] Créer un jeu "PlaceholderGame" de test implémentant l'interface
- [ ] Créer une vue de test pour l'implémentation de base

#### 1.4 Système de résultat et classement

- [ ] Créer un modèle pour les résultats de jeu (`game_result_model.dart`)
- [ ] Développer un widget de podium (`podium_widget.dart`) avec:
  - [ ] Représentation visuelle du top 3
  - [ ] Avatars, couleurs et noms des joueurs
  - [ ] Animations pour l'affichage
- [ ] Créer un widget de classement complet (`leaderboard_widget.dart`) avec:
  - [ ] Tri par score et pagination
  - [ ] Mise en évidence du joueur actuel

#### 1.5 Persistance et reconnexion

- [ ] Implémenter un système de sauvegarde d'état dans Firestore
- [ ] Créer un mécanisme de snapshots réguliers pendant le jeu
- [ ] Développer la logique de détection de déconnexion
- [ ] Implémenter la restauration d'état lors de la reconnexion
- [ ] Gérer les timeouts et cas limites (joueur déconnecté trop longtemps)

#### 1.6 Réimplémentation du jeu Quiz

- [ ] Créer les modèles pour le jeu Quiz:
  - [ ] `quiz_game_model.dart` étendant `base_game_model.dart`
  - [ ] `question_model.dart` avec tous les types de questions
- [ ] Implémenter les différents types de questions:
  - [ ] Questions à choix multiples
  - [ ] Questions à réponse libre
  - [ ] Questions avec slider
  - [ ] Questions avec date
- [ ] Ajouter le support pour les éléments multimédias:
  - [ ] Images
  - [ ] Sons
  - [ ] Vidéos
  - [ ] Liens (avec chargement dans un encart)

#### 1.7 Système de validation des réponses

- [ ] Implémenter la validation automatique des réponses:
  - [ ] Validation directe pour les choix multiples
  - [ ] Validation avec marge d'erreur pour les sliders et dates
- [ ] Créer un système de validation par les joueurs:
  - [ ] Interface de vote (like/dislike)
  - [ ] Système de comptage des votes (validation à 70%)
  - [ ] Fonctionnalité de "super like" avec points bonus
- [ ] Intégrer la validation par IA:
  - [ ] Service d'intégration avec l'API Gemini
  - [ ] Formatage des prompts pour l'évaluation
  - [ ] Gestion des scores attribués par l'IA

#### 1.8 Interface pour le créateur du jeu

- [ ] Développer une vue spéciale pour le créateur:
  - [ ] Affichage des réponses des joueurs en temps réel
  - [ ] Statistiques sur l'avancement du jeu
- [ ] Implémenter un système de points bonus:
  - [ ] Interface pour attribuer des points bonus
  - [ ] Synchronisation temps réel
  - [ ] Notifications pour les joueurs récompensés

#### 1.9 Statistiques et analytique

- [ ] Implémenter l'affichage des statistiques de réponses
- [ ] Créer des visualisations pour les statistiques (graphiques)
- [ ] Ajouter un système de badges et récompenses

#### 1.10 Tests et optimisation

- [ ] Créer des tests unitaires pour les composants critiques
- [ ] Réaliser des tests d'intégration pour le flux complet
- [ ] Optimiser les performances pour les grandes sessions
- [ ] Vérifier la compatibilité sur différents appareils

### 2. Correction des fonctionnalités dupliquées

#### 2.1 Élimination des duplications dans les contrôleurs

- [ ] Consolider les fonctions dupliquées:
  - [ ] Fusionner `createLobby()` entre `lobby_operation_helper.dart` et `lobby_management_controller.dart`
  - [ ] Consolider `joinLobbyById()`, `joinLobbyByCode()` et `leaveLobby()` entre les différents contrôleurs
- [ ] Refactoriser la hiérarchie des contrôleurs:
  - [ ] Clarifier le rôle de `lobby_controller.dart`
  - [ ] Documenter les responsabilités de chaque contrôleur

#### 2.2 Élimination des duplications dans les services

- [ ] Clarifier la séparation entre services et contrôleurs:
  - [ ] Déterminer si la logique appartient au service ou au contrôleur
  - [ ] Éliminer la duplication entre `services/quiz/lobby_service.dart` et les contrôleurs de lobby
- [ ] Résoudre les chevauchements entre services:
  - [ ] Répartir clairement les responsabilités entre `game_service.dart` et `lobby_service.dart`
  - [ ] Éviter la duplication entre `startLobbyQuiz()` et `startSession()`

#### 2.3 Nettoyage des widgets

- [ ] Consolider les widgets de chat:
  - [ ] Clarifier la relation entre `chat_view.dart` et `chat_widget.dart`
  - [ ] Définir un seul point de responsabilité pour l'envoi des messages
- [ ] Standardiser la gestion des erreurs:
  - [ ] Définir les rôles spécifiques de `error_dialog.dart`, `error_display.dart` et `error_handler.dart`
  - [ ] Créer une stratégie cohérente pour l'affichage des erreurs

#### 2.4 Standardisation des modèles

- [ ] Normaliser les méthodes de conversion Firestore:
  - [ ] Standardiser l'utilisation de `fromFirestore()` et `toFirestore()`
  - [ ] Remplacer les instances de `toMap()` par `toFirestore()` lorsque nécessaire
- [ ] Uniformiser les méthodes `copyWith()`:
  - [ ] Assurer une implémentation cohérente dans tous les modèles
  - [ ] Évaluer l'utilisation du package `freezed` pour la génération de code

## Instructions d'installation

1. Cloner le dépôt

   ```bash
   git clone https://github.com/votre-nom/quizzed.git
   cd quizzed
   ```

2. Installer les dépendances

   ```bash
   flutter pub get
   ```

3. Configurer Firebase

   - Créer un projet Firebase
   - Ajouter les applications (Android, iOS, Web) nécessaires
   - Télécharger et placer les fichiers de configuration
   - Activer Authentication, Firestore et Storage

4. Lancer l'application
   ```bash
   flutter run
   ```

## Structure du projet

Pour une documentation détaillée de la structure du projet, consultez les fichiers dans le répertoire `lib/documentation/`:

- `files.md`: Liste complète des fichiers avec leurs fonctions
- `firestore.md`: Structure de la base de données Firestore
- `lobby.md`: Documentation du système de lobby
- `tchat.md`: Documentation du système de chat
- `todo.md`: Checklist détaillée des tâches à réaliser

## Contribution

Les contributions sont les bienvenues! Veuillez suivre ces étapes:

1. Consulter la liste des tâches dans `lib/documentation/todo.md`
2. Créer une branche pour votre fonctionnalité
3. Développer et tester votre code
4. Soumettre une pull request

## Licence

[Spécifier la licence]
