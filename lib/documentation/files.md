# Documentation des fichiers du projet Quizzed

**IMPORTANT**: Toute modification ou ajout de fichiers doit être répertorié dans ce document.

## Arborescence complète

```
lib/
  ├── main.dart                                     # Point d'entrée de l'application
  ├── private_key.dart                              # Clés privées (ne pas committer)
  ├── config/
  │   └── app_config.dart                           # Configurations globales
  ├── controllers/
  │   ├── helpers/
  │   │   ├── lobby_operation_helper.dart           # Assistant pour les opérations de lobby
  │   │   └── quiz_helper.dart                      # Assistant pour les opérations de quiz
  │   ├── interfaces/
  │   │   ├── i_lobby_activity_controller.dart      # Interface pour l'activité du lobby
  │   │   ├── i_lobby_controller.dart               # Interface principale du contrôleur de lobby
  │   │   ├── i_lobby_management_controller.dart    # Interface pour la gestion des lobbies
  │   │   └── i_lobby_player_controller.dart        # Interface pour la gestion des joueurs du lobby
  │   └── lobby/
  │       ├── lobby_activity_controller.dart        # Contrôleur d'activité du lobby
  │       ├── lobby_base_controller.dart            # Contrôleur de base pour les lobbies
  │       ├── lobby_controller.dart                 # Contrôleur principal pour les lobbies
  │       ├── lobby_management_controller.dart      # Contrôleur de gestion des lobbies
  │       └── lobby_player_controller.dart          # Contrôleur de gestion des joueurs
  ├── documentation/
  │   ├── files.md                                  # Liste des fichiers du projet
  │   ├── firestore.md                              # Documentation de la structure Firebase
  │   ├── lobby.md                                  # Documentation du système de lobby
  │   ├── tchat.md                                  # Documentation du système de chat
  │   └── todo.md                                   # Liste des tâches à réaliser
  ├── examples/
  │   └── error_handling_example.dart               # Exemple de gestion des erreurs
  ├── models/
  │   ├── error_code.dart                           # Énumération des codes d'erreur
  │   ├── chat/
  │   │   └── chat_message_model.dart               # Modèle pour les messages de chat
  │   ├── lobby/
  │   │   ├── lobby_model.dart                      # Modèle pour les lobbies
  │   │   └── lobby_player_model.dart               # Modèle pour les joueurs dans un lobby
  │   ├── quiz/
  │   │   ├── answer_model.dart                     # Modèle pour les réponses aux questions de quiz
  │   │   ├── question_model.dart                   # Modèle pour les questions de quiz
  │   │   ├── quiz_model.dart                       # Modèle pour les quiz
  │   │   ├── quiz_session_model.dart               # Modèle pour les sessions de quiz
  │   │   └── score_model.dart                      # Modèle pour les scores de quiz
  │   └── user/
  │       └── user_model.dart                       # Modèle pour les utilisateurs
  ├── routes/
  │   └── app_routes.dart                           # Configuration des routes de l'application
  ├── services/
  │   ├── auth_service.dart                         # Service d'authentification
  │   ├── avatar_service.dart                       # Service de gestion des avatars
  │   ├── chat_service.dart                         # Service de gestion du chat
  │   ├── error_message_service.dart                # Service de gestion des messages d'erreur
  │   ├── firebase_service.dart                     # Service d'accès à Firebase
  │   ├── logger_service.dart                       # Service de journalisation
  │   ├── validation_service.dart                   # Service de validation des données
  │   ├── helpers/
  │   │   ├── firestore_batch_service.dart          # Service d'optimisation des opérations batch Firestore
  │   │   ├── firestore_cache_service.dart          # Service de mise en cache Firestore
  │   │   ├── firestore_listener_manager.dart       # Gestionnaire d'écouteurs Firestore
  │   │   └── firestore_optimization_service.dart   # Service d'optimisation Firestore
  │   └── quiz/
  │       ├── game_service.dart                     # Service de gestion des jeux
  │       ├── lobby_service.dart                    # Service de gestion des lobbies
  │       ├── question_service.dart                 # Service de gestion des questions
  │       └── score_service.dart                    # Service de gestion des scores
  ├── theme/
  │   └── theme_service.dart                        # Service de gestion des thèmes
  ├── utils/
  │   └── color_utils.dart                          # Utilitaires pour la gestion des couleurs
  ├── views/
  │   ├── auth/
  │   │   ├── forgot_password_view.dart             # Vue pour la récupération de mot de passe
  │   │   ├── login_view.dart                       # Vue de connexion
  │   │   └── register_view.dart                    # Vue d'inscription
  │   └── home/
  │       ├── home_view.dart                        # Vue principale de l'accueil
  │       ├── components/
  │       │   ├── home_content.dart                 # Contenu de la page d'accueil
  │       │   ├── index.dart                        # Index des composants de la page d'accueil
  │       │   └── settings_content.dart             # Contenu de la page des paramètres
  │       └── lobby/
  │           ├── create_lobby_view.dart            # Vue de création de lobby
  │           ├── lobby_detail_view.dart            # Vue détaillée d'un lobby
  │           └── lobby_list_view.dart              # Vue de la liste des lobbies
  └── widgets/
      ├── auth/
      │   ├── auth_button.dart                      # Bouton pour l'authentification
      │   └── auth_text_field.dart                  # Champ de texte pour l'authentification
      ├── chat/
      │   ├── chat_bubble.dart                      # Bulle de chat
      │   ├── chat_view.dart                        # Vue du chat
      │   └── chat_widget.dart                      # Widget de chat
      ├── home/
      │   ├── lobby_card.dart                       # Carte de lobby
      │   ├── lobby_player_item.dart                # Élément de joueur de lobby
      │   ├── quiz_card.dart                        # Carte de quiz
      │   ├── quiz_category_card.dart               # Carte de catégorie de quiz
      │   ├── recent_activity_card.dart             # Carte d'activité récente
      │   └── stats_card.dart                       # Carte de statistiques
      ├── profile/
      │   ├── avatar_preview.dart                   # Prévisualisation d'avatar
      │   ├── avatar_selector.dart                  # Sélecteur d'avatar
      │   └── color_selector.dart                   # Sélecteur de couleur
      └── shared/
          ├── empty_state.dart                      # État vide
          ├── error_dialog.dart                     # Dialogue d'erreur
          ├── error_display.dart                    # Affichage d'erreur
          ├── error_handler.dart                    # Gestionnaire d'erreur
          ├── loading_display.dart                  # Affichage de chargement
          └── section_header.dart                   # En-tête de section
```

## Structure générale

Le projet Quizzed est organisé selon l'architecture suivante:

```
lib/
  ├── main.dart              # Point d'entrée de l'application
  ├── private_key.dart       # Clés privées (ne pas committer)
  ├── config/                # Configurations globales
  ├── controllers/           # Logique métier (contrôleurs)
  ├── documentation/         # Documentation interne du projet
  ├── examples/              # Exemples de code
  ├── models/                # Modèles de données
  ├── routes/                # Configuration des routes
  ├── services/              # Services (accès aux données, auth, etc.)
  ├── theme/                 # Gestion des thèmes
  ├── utils/                 # Utilitaires génériques
  ├── views/                 # Interfaces utilisateur
  └── widgets/               # Composants réutilisables
```

## Liste des fichiers avec leurs fonctions

### Fichiers racine

#### `lib/main.dart` - Point d'entrée de l'application

- `main()` : Initialise Firebase, les providers et lance l'application
- `QuizzzedApp` : Widget principal de l'application
  - `build()` : Configure le thème et les routes de l'application

#### `lib/private_key.dart` - Clés privées (ne pas committer)

- Contient des constantes pour les clés d'API et les identifiants

### Configuration

#### `lib/config/app_config.dart` - Constantes et paramètres globaux

- `ProfileColor` : Classe représentant une couleur de profil pour les avatars
- `AppConfig` : Classe de configuration globale avec des constantes
  - `colorOpacity` : Opacité standard pour les couleurs (0.5 ou 50%)
  - `availableProfileColors` : Liste des couleurs disponibles pour les profils
- `AppEnvironment` : Paramètres d'environnement (prod/dev)

### Contrôleurs

#### `lib/controllers/helpers/lobby_operation_helper.dart` - Assistant pour les opérations de lobby

- `LobbyOperationHelper` : Classe utilitaire pour les opérations de lobby
  - `createLobby()` : Crée un nouveau lobby
  - `joinLobbyById()` : Rejoint un lobby par son ID
  - `joinLobbyByCode()` : Rejoint un lobby par son code d'accès
  - `leaveLobby()` : Quitte un lobby

#### `lib/controllers/helpers/quiz_helper.dart` - Assistant pour les opérations de quiz

- `QuizHelper` : Classe utilitaire pour les opérations de quiz
  - `startQuiz()` : Démarre une session de quiz
  - `submitAnswer()` : Soumet une réponse à une question
  - `calculateScore()` : Calcule le score d'une réponse

#### `lib/controllers/interfaces/i_lobby_activity_controller.dart` - Interface pour l'activité du lobby

- `ILobbyActivityController` : Interface pour la gestion des activités dans un lobby
  - `togglePlayerStatus()` : Change le statut "prêt" d'un joueur
  - `updatePlayerActivity()` : Met à jour l'horodatage d'activité d'un joueur

#### `lib/controllers/interfaces/i_lobby_controller.dart` - Interface principale du contrôleur de lobby

- `ILobbyController` : Interface principale pour la gestion des lobbies
  - `loadExistingLobby()` : Charge un lobby existant
  - `getLobbyById()` : Récupère un lobby par son ID
  - `joinLobbyStream()` : S'abonne au stream de mises à jour d'un lobby
  - `leaveLobbyStream()` : Se désabonne du stream d'un lobby

#### `lib/controllers/interfaces/i_lobby_management_controller.dart` - Interface pour la gestion des lobbies

- `ILobbyManagementController` : Interface pour la gestion administrative des lobbies
  - `createLobby()` : Crée un nouveau lobby
  - `updateLobby()` : Met à jour un lobby existant
  - `deleteLobby()` : Supprime un lobby
  - `kickPlayer()` : Expulse un joueur d'un lobby
  - `transferOwnership()` : Transfère la propriété du lobby à un autre joueur

#### `lib/controllers/interfaces/i_lobby_player_controller.dart` - Interface pour la gestion des joueurs du lobby

- `ILobbyPlayerController` : Interface pour la gestion des joueurs dans un lobby
  - `joinLobbyById()` : Rejoint un lobby par son ID
  - `joinLobbyByCode()` : Rejoint un lobby par son code d'accès
  - `leaveLobby()` : Quitte un lobby
  - `startGame()` : Démarre le jeu dans le lobby

#### `lib/controllers/lobby/lobby_activity_controller.dart` - Contrôleur d'activité du lobby

- `LobbyActivityController` : Implémentation de ILobbyActivityController
  - `togglePlayerStatus()` : Change le statut "prêt" d'un joueur
  - `updatePlayerActivity()` : Met à jour l'horodatage d'activité d'un joueur

#### `lib/controllers/lobby/lobby_base_controller.dart` - Contrôleur de base pour les lobbies

- `LobbyBaseController` : Classe de base pour les contrôleurs de lobby
  - `forceLoadingReset()` : Force la réinitialisation de l'état de chargement
  - `debugVerifyLobbyExists()` : Vérifie l'existence d'un lobby (debug)

#### `lib/controllers/lobby/lobby_controller.dart` - Contrôleur principal pour les lobbies

- `LobbyController` : Implémentation complète des interfaces de lobby
  - Fonctions héritées des contrôleurs spécialisés

#### `lib/controllers/lobby/lobby_management_controller.dart` - Contrôleur de gestion des lobbies

- `LobbyManagementController` : Implémentation de ILobbyManagementController
  - `createLobby()` : Crée un nouveau lobby
  - `updateLobby()` : Met à jour un lobby existant
  - `deleteLobby()` : Supprime un lobby
  - `kickPlayer()` : Expulse un joueur d'un lobby
  - `transferOwnership()` : Transfère la propriété du lobby à un autre joueur

#### `lib/controllers/lobby/lobby_player_controller.dart` - Contrôleur de gestion des joueurs

- `LobbyPlayerController` : Implémentation de ILobbyPlayerController
  - `joinLobbyById()` : Rejoint un lobby par son ID
  - `joinLobbyByCode()` : Rejoint un lobby par son code d'accès
  - `leaveLobby()` : Quitte un lobby
  - `startGame()` : Démarre le jeu dans le lobby

### Exemples

#### `lib/examples/error_handling_example.dart` - Exemple de gestion des erreurs

- `showExampleErrorHandling()` : Exemple de gestion d'erreurs dans l'application
- `handleExampleError()` : Exemple de traitement d'une erreur

### Modèles

#### `lib/models/chat/chat_message_model.dart` - Modèle pour les messages de chat

- `ChatChannel` : Énumération des canaux de chat
- `ChatMessageModel` : Classe représentant un message de chat
  - `fromFirestore()` : Crée un modèle à partir des données Firestore
  - `toFirestore()` : Convertit le modèle en données pour Firestore
  - `copyWith()` : Crée une copie avec des valeurs modifiées

#### `lib/models/error_code.dart` - Énumération des codes d'erreur

- `ErrorCode` : Énumération des codes d'erreur possibles dans l'application
- `ErrorSeverity` : Niveau de gravité d'une erreur

#### `lib/models/lobby/lobby_model.dart` - Modèle pour les lobbies

- `LobbyStatus` : Énumération des états d'un lobby
- `LobbyVisibility` : Énumération de la visibilité d'un lobby
- `LobbyModel` : Classe représentant un lobby
  - `fromFirestore()` : Crée un modèle à partir des données Firestore
  - `toFirestore()` : Convertit le modèle en données pour Firestore
  - `copyWith()` : Crée une copie avec des valeurs modifiées
  - `create()` : Crée un nouveau lobby
  - `canJoin()` : Vérifie si un joueur peut rejoindre
  - `canStart` : Propriété calculée indiquant si le jeu peut démarrer

#### `lib/models/lobby/lobby_player_model.dart` - Modèle pour les joueurs dans un lobby

- `LobbyPlayerModel` : Classe représentant un joueur dans un lobby
  - `fromFirestore()` : Crée un modèle à partir des données Firestore
  - `toMap()` : Convertit le modèle en Map
  - `fromUser()` : Crée un joueur à partir d'un modèle utilisateur
  - `copyWith()` : Crée une copie avec des valeurs modifiées

#### `lib/models/quiz/answer_model.dart` - Modèle pour les réponses aux questions de quiz

- `AnswerModel` : Classe représentant une réponse à une question
  - `fromFirestore()` : Crée un modèle à partir des données Firestore
  - `toFirestore()` : Convertit le modèle en données pour Firestore
  - `copyWith()` : Crée une copie avec des valeurs modifiées

#### `lib/models/quiz/question_model.dart` - Modèle pour les questions de quiz

- `QuestionType` : Énumération des types de questions
- `QuestionDifficulty` : Énumération des niveaux de difficulté
- `QuestionModel` : Classe représentant une question de quiz
  - `fromFirestore()` : Crée un modèle à partir des données Firestore
  - `toFirestore()` : Convertit le modèle en données pour Firestore
  - `copyWith()` : Crée une copie avec des valeurs modifiées

#### `lib/models/quiz/quiz_model.dart` - Modèle pour les quiz

- `QuizModel` : Classe représentant un quiz
  - `from
  - `addListener()` : Ajoute un écouteur
  - `removeListener()` : Supprime un écouteur
  - `removeAllListeners()` : Supprime tous les écouteurs

#### `lib/services/helpers/firestore_optimization_service.dart` - Service d'optimisation Firestore

- `FirestoreOptimizationService` : Optimise les requêtes et opérations Firestore
  - `optimizeQuery()` : Optimise une requête Firestore
  - `optimizeReads()` : Optimise les lectures Firestore

#### `lib/services/quiz/game_service.dart` - Service de gestion des jeux

- `GameService` : Service gérant les sessions de jeu
  - `createSession()` : Crée une nouvelle session de jeu
  - `joinSession()` : Rejoint une session existante
  - `startSession()` : Démarre une session de jeu
  - `endSession()` : Termine une session de jeu
  - `getSessionData()` : Récupère les données d'une session

#### `lib/services/quiz/lobby_service.dart` - Service de gestion des lobbies

- `LobbyService` : Service gérant les lobbies
  - `createLobby()` : Crée un nouveau lobby
  - `joinLobby()` : Rejoint un lobby existant
  - `joinPrivateLobbyByCode()` : Rejoint un lobby privé par code d'accès
  - `leaveLobby()` : Quitte un lobby
  - `kickPlayer()` : Expulse un joueur d'un lobby
  - `updatePlayerReadyStatus()` : Met à jour le statut "prêt" d'un joueur
  - `updateLobbySettings()` : Met à jour les paramètres d'un lobby
  - `startLobbyQuiz()` : Démarre un quiz dans un lobby
  - `getLobbyById()` : Récupère un lobby par son ID
  - `getLobbyStream()` : Récupère le flux de mises à jour d'un lobby
  - `transferOwnership()` : Transfère la propriété du lobby à un autre joueur

#### `lib/services/quiz/question_service.dart` - Service de gestion des questions

- `QuestionService` : Service gérant les questions de quiz
  - `getQuestions()` : Récupère des questions pour un quiz
  - `createQuestion()` : Crée une nouvelle question
  - `updateQuestion()` : Met à jour une question existante
  - `deleteQuestion()` : Supprime une question
  - `validateAnswer()` : Valide une réponse à une question

#### `lib/services/quiz/score_service.dart` - Service de gestion des scores

- `ScoreService` : Service gérant les scores des quiz
  - `saveScore()` : Sauvegarde un score
  - `getScores()` : Récupère les scores d'un quiz
  - `getUserScores()` : Récupère les scores d'un utilisateur
  - `calculateLeaderboard()` : Calcule le classement pour un quiz

### Thème

#### `lib/theme/theme_service.dart` - Service de gestion des thèmes

- `ThemeService` : Service gérant le thème de l'application
  - `lightTheme` : Thème clair
  - `darkTheme` : Thème sombre
  - `isDarkMode` : Indique si le mode sombre est activé
  - `toggleTheme()` : Bascule entre les thèmes clair et sombre
  - `setAuthService()` : Configure le service d'authentification pour la persistance

### Utilitaires

#### `lib/utils/color_utils.dart` - Utilitaires pour la gestion des couleurs

- `ColorUtils` : Classe utilitaire pour la gestion des couleurs
  - `fromValue()` : Convertit une valeur numérique en Color
  - `toStorageValue()` : Convertit une Color en valeur stockable
  - `getTextColorForBackground()` : Détermine la couleur de texte adaptée
  - `getProfileColorByName()` : Récupère une couleur de profil par son nom
  - `getProfileColorFromColor()` : Récupère une ProfileColor à partir d'une Color

### Vues

#### `lib/views/auth/forgot_password_view.dart` - Vue pour la récupération de mot de passe

- `ForgotPasswordView` : Vue permettant de réinitialiser son mot de passe
  - `_handleResetPassword()` : Gère la demande de réinitialisation

#### `lib/views/auth/login_view.dart` - Vue de connexion

- `LoginView` : Vue de connexion à l'application
  - `_handleLogin()` : Gère la tentative de connexion
  - `_navigateToRegister()` : Navigue vers la page d'inscription
  - `_navigateToForgotPassword()` : Navigue vers la récupération de mot de passe

#### `lib/views/auth/register_view.dart` - Vue d'inscription

- `RegisterView` : Vue d'inscription à l'application
  - `_handleRegister()` : Gère la tentative d'inscription
  - `_showAvatarSelectorDialog()` : Affiche le sélecteur d'avatar
  - `_showColorSelectorDialog()` : Affiche le sélecteur de couleur

#### `lib/views/home/components/home_content.dart` - Contenu de la page d'accueil

- `HomeContent` : Contenu principal de la page d'accueil
  - `_loadUserData()` : Charge les données de l'utilisateur
  - `_navigateToCreateLobby()` : Navigue vers la création de lobby
  - `_navigateToLobbyDetail()` : Navigue vers les détails d'un lobby
  - `_showJoinByCodeDialog()` : Affiche le dialogue pour rejoindre par code

#### `lib/views/home/components/index.dart` - Index des composants de la page d'accueil

- Exporte les composants de la page d'accueil

#### `lib/views/home/components/settings_content.dart` - Contenu de la page des paramètres

- `SettingsContent` : Contenu de la page des paramètres
  - `_initUserData()` : Initialise les données utilisateur
  - `_updateUserProfile()` : Met à jour le profil utilisateur
  - `_handleLogout()` : Gère la déconnexion
  - `_toggleTheme()` : Bascule le thème clair/sombre

#### `lib/views/home/home_view.dart` - Vue principale de l'accueil

- `HomeView` : Vue principale avec menu latéral
  - `_buildDrawer()` : Construit le menu latéral
  - `_navigateToPage()` : Navigue vers une page du menu
  - `_getCurrentPageIndex()` : Détermine l'index de la page actuelle

#### `lib/views/home/lobby/create_lobby_view.dart` - Vue de création de lobby

- `CreateLobbyView` : Vue pour créer ou modifier un lobby
  - `_createLobby()` : Crée un nouveau lobby
  - `_updateLobby()` : Met à jour un lobby existant
  - `_generateRandomName()` : Génère un nom aléatoire pour le lobby

#### `lib/views/home/lobby/lobby_detail_view.dart` - Vue détaillée d'un lobby

- `LobbyDetailView` : Vue détaillée d'un lobby
  - `_loadLobbyWithDebug()` : Charge les données du lobby
  - `_leaveLobby()` : Quitte le lobby
  - `_startGame()` : Démarre le jeu
  - `_toggleReadyStatus()` : Change le statut "prêt" du joueur
  - `_kickPlayer()` : Expulse un joueur
  - `_copyLobbyCode()` : Copie le code d'accès du lobby
  - `_deleteLobby()` : Supprime le lobby
  - `_transferOwnership()` : Transfère la propriété du lobby
  - `_navigateToChat()` : Ouvre le chat du lobby
  - `_shareLobbyCode()` : Partage le code d'accès du lobby

#### `lib/views/home/lobby/lobby_list_view.dart` - Vue de la liste des lobbies

- `LobbyListView` : Vue listant les lobbies disponibles
  - `_onRefresh()` : Rafraîchit la liste des lobbies
  - `_showJoinPrivateLobbyDialog()` : Affiche le dialogue pour rejoindre un lobby privé
  - `_navigateToLobbyDetail()` : Navigue vers les détails d'un lobby
  - `_navigateToCreateLobby()` : Navigue vers la création de lobby

### Widgets

#### `lib/widgets/auth/auth_button.dart` - Bouton pour l'authentification

- `AuthButton` : Bouton stylisé pour l'authentification
  - `build()` : Construit le bouton avec le style approprié

#### `lib/widgets/auth/auth_text_field.dart` - Champ de texte pour l'authentification

- `AuthTextField` : Champ de texte stylisé pour l'authentification
  - `build()` : Construit le champ de texte avec le style approprié

#### `lib/widgets/chat/chat_bubble.dart` - Bulle de chat

- `ChatBubble` : Bulle affichant un message de chat
  - `build()` : Construit la bulle de chat selon le type de message

#### `lib/widgets/chat/chat_view.dart` - Vue du chat

- `ChatView` : Vue complète du chat d'un lobby
  - `_sendMessage()` : Envoie un message
  - `_buildMessageList()` : Construit la liste des messages

#### `lib/widgets/chat/chat_widget.dart` - Widget de chat

- `ChatWidget` : Widget encapsulant les fonctionnalités de chat
  - `build()` : Construit l'interface de chat

#### `lib/widgets/home/lobby_card.dart` - Carte de lobby

- `LobbyCard` : Carte affichant les informations d'un lobby
  - `build()` : Construit la carte avec les informations du lobby
  - `_buildPlayersList()` : Construit la liste des joueurs du lobby
  - `_getCategoryIcon()` : Récupère l'icône correspondant à la catégorie

#### `lib/widgets/home/lobby_player_item.dart` - Élément de joueur de lobby

- `LobbyPlayerItem` : Élément affichant un joueur dans un lobby
  - `build()` : Construit l'élément avec les informations du joueur
  - `_getTimeAgo()` : Formate le temps écoulé depuis que le joueur a rejoint

#### `lib/widgets/home/quiz_card.dart` - Carte de quiz

- `QuizCard` : Carte affichant les informations d'un quiz
  - `build()` : Construit la carte avec les informations du quiz

#### `lib/widgets/home/quiz_category_card.dart` - Carte de catégorie de quiz

- `QuizCategoryCard` : Carte affichant une catégorie de quiz
  - `build()` : Construit la carte avec les informations de la catégorie

#### `lib/widgets/home/recent_activity_card.dart` - Carte d'activité récente

- `RecentActivityCard` : Carte affichant une activité récente
  - `build()` : Construit la carte avec les informations de l'activité

#### `lib/widgets/home/stats_card.dart` - Carte de statistiques

- `StatsCard` : Carte affichant des statistiques
  - `build()` : Construit la carte avec les statistiques

#### `lib/widgets/profile/avatar_preview.dart` - Prévisualisation d'avatar

- `AvatarPreview` : Widget affichant un aperçu d'avatar
  - `build()` : Construit l'aperçu de l'avatar
  - `_buildOverflowAvatar()` : Construit un avatar avec débordement

#### `lib/widgets/profile/avatar_selector.dart` - Sélecteur d'avatar

- `AvatarSelector` : Widget permettant de sélectionner un avatar
  - `_loadAvatars()` : Charge la liste des avatars disponibles
  - `build()` : Construit le sélecteur d'avatar

#### `lib/widgets/profile/color_selector.dart` - Sélecteur de couleur

- `ColorSelector` : Widget permettant de sélectionner une couleur de profil
  - `build()` : Construit le sélecteur de couleur

#### `lib/widgets/shared/empty_state.dart` - État vide

- `EmptyState` : Widget affiché quand une liste est vide
  - `build()` : Construit l'état vide avec message et illustration

#### `lib/widgets/shared/error_dialog.dart` - Dialogue d'erreur

- `ErrorDialog` : Dialogue affichant une erreur
  - `build()` : Construit le dialogue d'erreur

#### `lib/widgets/shared/error_display.dart` - Affichage d'erreur

- `ErrorDisplay` : Widget affichant une erreur
  - `build()` : Construit l'affichage d'erreur

#### `lib/widgets/shared/error_handler.dart` - Gestionnaire d'erreur

- `ErrorHandler` : Widget gérant les erreurs
  - `build()` : Construit le gestionnaire d'erreur

#### `lib/widgets/shared/loading_display.dart` - Affichage de chargement

- `LoadingDisplay` : Widget affichant un indicateur de chargement
  - `build()` : Construit l'affichage de chargement

#### `lib/widgets/shared/section_header.dart` - En-tête de section

- `SectionHeader` : Widget d'en-tête de section
  - `build()` : Construit l'en-tête de section
