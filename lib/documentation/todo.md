# Checklist des corrections et améliorations à apporter

## Corrections d'interface déjà réalisées

- ✅ Correction de l'affichage du statut "prêt" des joueurs dans `lobby_player_item.dart`
- ✅ Amélioration du bouton "Je suis prêt" avec un retour visuel approprié
- ✅ Ajouter le bouton pour rejoindre le tchat dans la page détails du lobby
- ✅ Mettre à jour l'interface du lobby pour mieux afficher le code d'accès

## Documentation initiale

- ✅ Créer un fichier process.md pour décrire le processus de développement et de documentation
- ✅ Créer un fichier information.md pour décrire les fonctionnalités du système de jeux
- ✅ Créer un fichier memory.md pour suivre les actions réalisées

## Refonte du système quiz en système de jeux

### Phase 1 : Préparation et nettoyage

#### 1.1 : Identification et documentation des fichiers à supprimer

- ⬜ Lister tous les fichiers dans `/lib/models/quiz/` à supprimer
- ⬜ Lister tous les fichiers dans `/lib/controllers/` liés aux quiz à supprimer
- ⬜ Lister tous les fichiers dans `/lib/services/quiz/` à supprimer
- ⬜ Lister tous les fichiers dans `/lib/views/` liés aux quiz à supprimer
- ⬜ Lister tous les widgets liés aux quiz à supprimer
- ⬜ Documenter les références aux fichiers quiz dans d'autres parties du code
- ⬜ Créer un fichier de documentation `game.md` sur le nouveau système de jeux

#### 1.2 : Suppression des fichiers quiz

- ⬜ Supprimer les fichiers de modèles quiz (`/lib/models/quiz/`)
- ⬜ Supprimer les fichiers de contrôleurs quiz
- ⬜ Supprimer les fichiers de services quiz (`/lib/services/quiz/`)
- ⬜ Supprimer les fichiers de vues quiz
- ⬜ Supprimer les widgets quiz
- ⬜ Mettre à jour `files.md` pour refléter les suppressions

#### 1.3 : Création de la nouvelle structure de dossiers

- ⬜ Créer le répertoire `/lib/models/game/`
- ⬜ Créer le répertoire `/lib/services/game/`
- ⬜ Créer le répertoire `/lib/controllers/game/` (si nécessaire)
- ⬜ Créer le répertoire `/lib/views/game/` (si nécessaire)
- ⬜ Créer le répertoire `/lib/widgets/game/`
- ⬜ Mettre à jour `files.md` avec la nouvelle structure

### Phase 2 : Implémentation de l'architecture de base des jeux

#### 2.1 : Création des énumérations et constantes

- ⬜ Créer `lib/models/game/game_enums.dart` avec les énumérations :
  - ⬜ `GameType` (quiz, etc.)
  - ⬜ `GameStatus` (waiting, playing, finished)
  - ⬜ Mettre à jour `files.md`
- ⬜ Créer `lib/models/game/game_constants.dart` avec les constantes :
  - ⬜ Timeouts
  - ⬜ Limites
  - ⬜ Mettre à jour `files.md`

#### 2.2 : Création de l'interface et des modèles de base

- ⬜ Créer `lib/models/game/i_game.dart` avec :

  - ⬜ Définir les propriétés communes à tous les jeux
  - ⬜ Définir la méthode `joinGame()`
  - ⬜ Définir la méthode `leaveGame()`
  - ⬜ Définir la méthode `saveState()`
  - ⬜ Définir la méthode `restoreState()`
  - ⬜ Définir la méthode `startGame()`
  - ⬜ Définir la méthode `endGame()`
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/models/game/base_game_model.dart` avec :

  - ⬜ Implémentation de l'interface `IGame`
  - ⬜ Propriétés communes (id, lobbyd, creatorId, status, players, etc.)
  - ⬜ Méthodes de sérialisation/désérialisation Firestore
  - ⬜ Méthode `copyWith()`
  - ⬜ Méthode de snapshot pour sauvegarder l'état
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/models/game/game_player_model.dart` avec :
  - ⬜ Propriétés du joueur (id, name, isActive, score, etc.)
  - ⬜ Méthodes de sérialisation/désérialisation
  - ⬜ Méthode `copyWith()`
  - ⬜ Mettre à jour `files.md`

#### 2.3 : Création du service de gestion de jeu

- ⬜ Créer `lib/services/game/game_service.dart` avec :

  - ⬜ Méthode `createGame()`
  - ⬜ Méthode `joinGame()`
  - ⬜ Méthode `leaveGame()`
  - ⬜ Méthode `getGameById()`
  - ⬜ Méthode `listenToGameUpdates()`
  - ⬜ Méthode `saveGameState()`
  - ⬜ Méthode `checkForActiveGames()`
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/services/game/game_state_service.dart` avec :
  - ⬜ Méthode `saveSnapshot()`
  - ⬜ Méthode `loadLatestSnapshot()`
  - ⬜ Méthode `cleanupOldSnapshots()`
  - ⬜ Mettre à jour `files.md`

#### 2.4 : Création du jeu PlaceholderGame pour tests

- ⬜ Créer `lib/models/game/placeholder_game_model.dart` avec :

  - ⬜ Étendre `BaseGameModel`
  - ⬜ Implémenter des fonctionnalités minimales
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/views/game/placeholder_game_view.dart` avec :
  - ⬜ Interface simple pour tester le jeu
  - ⬜ Boutons pour les actions de base
  - ⬜ Mettre à jour `files.md`

### Phase 3 : Système de résultats et classement

#### 3.1 : Modèles de résultats

- ⬜ Créer `lib/models/game/game_result_model.dart` avec :

  - ⬜ Liste des joueurs et leurs scores
  - ⬜ Timestamp
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/models/game/player_result_model.dart` avec :
  - ⬜ ID du joueur
  - ⬜ Score final
  - ⬜ Position dans le classement
  - ⬜ Points gagnés
  - ⬜ Statistiques additionnelles
  - ⬜ Mettre à jour `files.md`

#### 3.2 : Widgets de visualisation des résultats

- ⬜ Créer `lib/widgets/game/podium_widget.dart` avec :

  - ⬜ Affichage visuel des 3 premiers joueurs
  - ⬜ Avatars, couleurs et noms des joueurs
  - ⬜ Animations pour l'affichage
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/widgets/game/leaderboard_widget.dart` avec :

  - ⬜ Liste de tous les joueurs classés par score
  - ⬜ Surbrillance pour le joueur actuel
  - ⬜ Pagination pour les grandes listes
  - ⬜ Tri par différents critères
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/views/game/result_view.dart` avec :
  - ⬜ Intégration du podium et du classement
  - ⬜ Boutons de navigation (retour au lobby, rejouer, etc.)
  - ⬜ Mettre à jour `files.md`

### Phase 4 : Système de persistance et reconnexion

#### 4.1 : Gestion des snapshots d'état

- ⬜ Créer `lib/models/game/game_snapshot_model.dart` avec :

  - ⬜ État complet du jeu à un instant T
  - ⬜ Timestamp
  - ⬜ Mettre à jour `files.md`

- ⬜ Étendre `lib/services/game/game_state_service.dart` avec :
  - ⬜ Système de snapshots automatiques à intervalles réguliers
  - ⬜ Système de snapshots à des moments clés du jeu
  - ⬜ Mettre à jour `files.md`

#### 4.2 : Détection et gestion des déconnexions

- ⬜ Étendre `lib/services/game/game_service.dart` avec :

  - ⬜ Méthode `markPlayerAsInactive()`
  - ⬜ Méthode `handlePlayerReconnection()`
  - ⬜ Système de timeout pour les joueurs inactifs
  - ⬜ Mettre à jour `files.md`

- ⬜ Implémenter les listeners de présence dans Firebase
  - ⬜ Créer `lib/services/game/game_presence_service.dart`
  - ⬜ Système de détection des déconnexions
  - ⬜ Système de reconnexion automatique
  - ⬜ Mettre à jour `files.md`

#### 4.3 : UI pour reconnexion

- ⬜ Créer `lib/widgets/game/game_reconnection_dialog.dart` avec :
  - ⬜ Dialog de reconnexion
  - ⬜ Informations sur le jeu en cours
  - ⬜ Options pour rejoindre ou abandonner
  - ⬜ Mettre à jour `files.md`

### Phase 5 : Implémentation du jeu Quiz

#### 5.1 : Modèles de base pour le Quiz

- ⬜ Créer `lib/models/game/quiz/quiz_game_model.dart` avec :

  - ⬜ Extension de `BaseGameModel`
  - ⬜ Liste de questions
  - ⬜ Paramètres spécifiques au quiz
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/models/game/quiz/question_model.dart` avec :

  - ⬜ Propriétés communes à tous les types de questions
  - ⬜ Propriétés spécifiques au type de question
  - ⬜ Méthodes de sérialisation/désérialisation
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/models/game/quiz/answer_model.dart` avec :
  - ⬜ Structure commune aux réponses
  - ⬜ Propriétés spécifiques au type de réponse
  - ⬜ Mettre à jour `files.md`

#### 5.2 : Types de questions

- ⬜ Créer `lib/models/game/quiz/question_types/multiple_choice_question.dart` avec :

  - ⬜ Extension de `QuestionModel`
  - ⬜ Liste des options
  - ⬜ Réponses correctes
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/models/game/quiz/question_types/free_text_question.dart` avec :

  - ⬜ Extension de `QuestionModel`
  - ⬜ Paramètres de validation
  - ⬜ Mode de validation (IA, joueurs)
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/models/game/quiz/question_types/slider_question.dart` avec :

  - ⬜ Extension de `QuestionModel`
  - ⬜ Valeur minimale, maximale
  - ⬜ Valeur correcte
  - ⬜ Marge d'erreur acceptée
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/models/game/quiz/question_types/date_question.dart` avec :
  - ⬜ Extension de `QuestionModel`
  - ⬜ Date correcte
  - ⬜ Marge d'erreur (jours)
  - ⬜ Mettre à jour `files.md`

#### 5.3 : Contenu multimédia

- ⬜ Créer `lib/models/game/quiz/media/question_media.dart` avec :

  - ⬜ Classes pour les différents types de médias
  - ⬜ Gestion des URLs/chemins
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/services/game/quiz/media_service.dart` avec :

  - ⬜ Méthodes de téléchargement/récupération des médias
  - ⬜ Gestion du cache
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer des widgets pour chaque type de média :
  - ⬜ `lib/widgets/game/quiz/media/image_display_widget.dart`
  - ⬜ `lib/widgets/game/quiz/media/audio_player_widget.dart`
  - ⬜ `lib/widgets/game/quiz/media/video_player_widget.dart`
  - ⬜ `lib/widgets/game/quiz/media/web_content_widget.dart`
  - ⬜ Mettre à jour `files.md`

#### 5.4 : Interface du quiz

- ⬜ Créer `lib/views/game/quiz/quiz_game_view.dart` avec :

  - ⬜ Vue principale du quiz
  - ⬜ Gestion de l'état du jeu
  - ⬜ Navigation entre les questions
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer des widgets pour chaque type de question :
  - ⬜ `lib/widgets/game/quiz/question/multiple_choice_question_widget.dart`
  - ⬜ `lib/widgets/game/quiz/question/free_text_question_widget.dart`
  - ⬜ `lib/widgets/game/quiz/question/slider_question_widget.dart`
  - ⬜ `lib/widgets/game/quiz/question/date_question_widget.dart`
  - ⬜ Mettre à jour `files.md`

### Phase 6 : Système de validation des réponses

#### 6.1 : Validation automatique

- ⬜ Créer `lib/services/game/quiz/answer_validation_service.dart` avec :
  - ⬜ Validation des réponses à choix multiples
  - ⬜ Validation des réponses avec slider (avec marge d'erreur)
  - ⬜ Validation des réponses avec date (avec marge d'erreur)
  - ⬜ Mettre à jour `files.md`

#### 6.2 : Validation par les joueurs

- ⬜ Créer `lib/models/game/quiz/peer_review_model.dart` avec :

  - ⬜ Structure pour les votes
  - ⬜ Super likes
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/services/game/quiz/peer_review_service.dart` avec :

  - ⬜ Gestion des votes
  - ⬜ Calcul des pourcentages
  - ⬜ Validation des seuils (70%)
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/views/game/quiz/peer_review_view.dart` avec :
  - ⬜ Interface pour voter sur les réponses
  - ⬜ Système de like/dislike
  - ⬜ Super like
  - ⬜ Mettre à jour `files.md`

#### 6.3 : Validation par IA

- ⬜ Créer `lib/services/game/quiz/ai_validation_service.dart` avec :

  - ⬜ Intégration avec l'API Gemini
  - ⬜ Construction des prompts
  - ⬜ Traitement des résultats
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/models/game/quiz/ai_validation_result.dart` avec :
  - ⬜ Structure pour les résultats d'évaluation par IA
  - ⬜ Score attribué
  - ⬜ Explication
  - ⬜ Mettre à jour `files.md`

### Phase 7 : Interface pour le créateur du quiz

#### 7.1 : Interface en temps réel

- ⬜ Créer `lib/views/game/quiz/creator_view.dart` avec :
  - ⬜ Vue spécifique au créateur
  - ⬜ Réponses en temps réel
  - ⬜ Progression du jeu
  - ⬜ Mettre à jour `files.md`

#### 7.2 : Système de points bonus

- ⬜ Créer `lib/models/game/quiz/bonus_points_model.dart` avec :

  - ⬜ Structure pour les points bonus
  - ⬜ Justification
  - ⬜ Mettre à jour `files.md`

- ⬜ Étendre `lib/services/game/quiz/quiz_service.dart` avec :

  - ⬜ Méthode `awardBonusPoints()`
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/widgets/game/quiz/creator/bonus_points_widget.dart` avec :

  - ⬜ Interface pour attribuer des points bonus
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/widgets/game/quiz/player/bonus_points_notification.dart` avec :
  - ⬜ Notification pour les joueurs recevant des points bonus
  - ⬜ Mettre à jour `files.md`

### Phase 8 : Statistiques et analytique

#### 8.1 : Modèles et services pour les statistiques

- ⬜ Créer `lib/models/game/quiz/question_statistics_model.dart` avec :

  - ⬜ Structure pour les statistiques de réponses
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/services/game/quiz/statistics_service.dart` avec :
  - ⬜ Calcul des statistiques pour le lobby actuel
  - ⬜ Récupération des statistiques globales
  - ⬜ Mettre à jour `files.md`

#### 8.2 : Interface des statistiques

- ⬜ Créer `lib/widgets/game/quiz/statistics/answer_distribution_chart.dart` avec :

  - ⬜ Visualisation des réponses
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/widgets/game/quiz/statistics/comparative_statistics_widget.dart` avec :
  - ⬜ Comparaison entre lobby actuel et statistiques globales
  - ⬜ Mettre à jour `files.md`

#### 8.3 : Système de badges

- ⬜ Créer `lib/models/game/achievements/badge_model.dart` avec :

  - ⬜ Structure pour les badges
  - ⬜ Conditions d'obtention
  - ⬜ Mettre à jour `files.md`

- ⬜ Créer `lib/services/game/achievements/badge_service.dart` avec :
  - ⬜ Attribution des badges
  - ⬜ Vérification des conditions
  - ⬜ Mettre à jour `files.md`

### Phase 9 : Tests et optimisation

#### 9.1 : Tests unitaires

- ⬜ Créer des tests pour les modèles de jeu
- ⬜ Créer des tests pour les services
- ⬜ Créer des tests pour la validation des réponses

#### 9.2 : Tests d'intégration

- ⬜ Créer des tests pour le flux complet d'un quiz
- ⬜ Tester les scénarios de déconnexion/reconnexion
- ⬜ Tester le système de validation des réponses libres

#### 9.3 : Optimisation

- ⬜ Optimiser les requêtes Firestore
- ⬜ Implémenter un système de cache efficace
- ⬜ Optimiser le chargement des médias
- ⬜ Réduire l'utilisation de la bande passante

#### 9.4 : Compatibilité

- ⬜ Tester sur différentes tailles d'écran
- ⬜ Tester sur différents appareils
- ⬜ Adapter l'interface selon les contraintes

## Résolution des fonctionnalités dupliquées

### Élimination des duplications dans les contrôleurs

- ⬜ Consolider les fonctions de gestion de lobby dupliquées
  - ⬜ Éliminer la duplication entre `lobby_operation_helper.dart` et `lobby_management_controller.dart` pour `createLobby()`
  - ⬜ Éliminer la duplication entre `lobby_operation_helper.dart` et `lobby_player_controller.dart` pour `joinLobbyById()`, `joinLobbyByCode()` et `leaveLobby()`
- ⬜ Refactoriser la hiérarchie des contrôleurs
  - ⬜ S'assurer que `lobby_controller.dart` utilise correctement les contrôleurs spécialisés
  - ⬜ Documenter clairement la responsabilité de chaque contrôleur

### Élimination des duplications dans les services

- ⬜ Consolider les fonctions de gestion de lobby
  - ⬜ Éliminer la duplication entre `services/quiz/lobby_service.dart` et les contrôleurs lobby pour les fonctions comme `createLobby()`, `joinLobby()`, etc.
  - ⬜ Définir clairement si la logique appartient au service ou au contrôleur
- ⬜ Résoudre les chevauchements entre `game_service.dart` et les autres services
  - ⬜ Clarifier les responsabilités entre `game_service.dart` et `lobby_service.dart` pour le démarrage des jeux
  - ⬜ S'assurer que `startLobbyQuiz()` et `startSession()` ne font pas double emploi

### Élimination des duplications dans les widgets

- ⬜ Consolider les widgets liés au chat
  - ⬜ Clarifier la relation entre `chat_view.dart` et `chat_widget.dart`
  - ⬜ S'assurer qu'un seul widget est responsable de l'envoi des messages
- ⬜ Vérifier les duplications dans les widgets d'erreur
  - ⬜ Clarifier les rôles de `error_dialog.dart`, `error_display.dart` et `error_handler.dart`
  - ⬜ Créer une stratégie cohérente pour la gestion des erreurs

### Normalisation des modèles

- ⬜ Standardiser les méthodes de conversion Firestore
  - ⬜ S'assurer que tous les modèles utilisent une approche cohérente pour `fromFirestore()` et `toFirestore()`
  - ⬜ Vérifier si certains modèles utilisent `toMap()` au lieu de `toFirestore()` et normaliser
- ⬜ Normaliser les méthodes `copyWith()`
  - ⬜ S'assurer que tous les modèles implémentent `copyWith()` de manière cohérente
  - ⬜ Considérer l'utilisation d'un package comme `freezed` pour générer automatiquement ces méthodes
