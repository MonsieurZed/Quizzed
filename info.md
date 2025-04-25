# Structure et fonctionnalités de l'application Quizzed

## Arborescence du projet

```
lib/
├── config/
│   └── app_config.dart               # Configuration globale de l'application et couleurs de profil
├── controllers/
│   ├── helpers/                      # Classes auxiliaires pour les contrôleurs
│   │   ├── lobby_activity_helper.dart # Aide pour les activités de lobby
│   │   └── lobby_player_helper.dart   # Aide pour la gestion des joueurs
│   ├── interfaces/                   # Interfaces pour les contrôleurs
│   │   ├── i_controller_base.dart     # Interface de base pour tous les contrôleurs
│   │   ├── i_lobby_activity_controller.dart # Interface pour les activités de lobby
│   │   ├── i_lobby_management_controller.dart # Interface pour la gestion des lobbies
│   │   └── i_lobby_player_controller.dart # Interface pour la gestion des joueurs
│   └── lobby/                        # Contrôleurs pour les fonctionnalités de lobby
│       ├── lobby_activity_controller.dart # Gère les activités dans un lobby
│       ├── lobby_base_controller.dart # Classe de base pour les contrôleurs de lobby
│       ├── lobby_controller.dart      # Contrôleur principal pour les lobbies
│       ├── lobby_management_controller.dart # Gère la création/suppression des lobbies
│       ├── lobby_player_controller.dart # Gère les interactions des joueurs
│       └── README.md                  # Documentation pour les contrôleurs de lobby
├── models/                           # Modèles de données
│   ├── chat/                         # Modèles pour le chat
│   │   └── chat_message_model.dart    # Modèle pour les messages de chat
│   ├── lobby/                        # Modèles pour les lobbies
│   │   ├── lobby_model.dart           # Modèle principal pour un lobby
│   │   └── lobby_player_model.dart    # Modèle pour un joueur dans un lobby
│   ├── quiz/                         # Modèles pour les quiz
│   │   ├── question_model.dart        # Modèle pour une question
│   │   ├── quiz_answer_model.dart     # Modèle pour une réponse à une question
│   │   ├── quiz_category_model.dart   # Modèle pour une catégorie de quiz
│   │   ├── quiz_model.dart            # Modèle principal pour un quiz
│   │   └── quiz_session_model.dart    # Modèle pour une session de quiz
│   ├── user/                         # Modèles pour les utilisateurs
│   │   └── user_model.dart            # Modèle pour un utilisateur
│   └── error_code.dart               # Codes d'erreur standardisés
├── routes/                           # Configuration du routage
│   └── app_routes.dart               # Définition des routes de l'application
├── services/                         # Services de l'application
│   ├── helpers/                      # Classes d'aide pour les services
│   │   ├── auth_helper.dart           # Fonctions d'aide pour l'authentification
│   │   ├── cloud_storage_helper.dart  # Fonctions d'aide pour Cloud Storage
│   │   ├── firestore_helper.dart      # Fonctions d'aide pour Firestore
│   │   └── mapping_helper.dart        # Fonctions d'aide pour le mapping de données
│   ├── quiz/                         # Services liés aux quiz
│   │   ├── lobby_service.dart         # Service pour la gestion des lobbies
│   │   ├── question_service.dart      # Service pour la gestion des questions
│   │   ├── quiz_service.dart          # Service principal pour les quiz
│   │   └── session_service.dart       # Service pour les sessions de quiz
│   ├── auth_service.dart             # Service d'authentification
│   ├── avatar_service.dart           # Service de gestion des avatars
│   ├── chat_service.dart             # Service de chat
│   ├── error_message_service.dart    # Service de gestion des messages d'erreur
│   ├── firebase_service.dart         # Service principal pour Firebase
│   ├── logger_service.dart           # Service de journalisation
│   └── validation_service.dart       # Service de validation des données
├── theme/                            # Configuration des thèmes
│   └── theme_service.dart            # Service de gestion des thèmes
├── utils/                            # Utilitaires pour l'application
│   └── color_utils.dart              # Utilitaires pour la manipulation des couleurs
├── views/                            # Vues de l'application
│   ├── auth/                         # Vues d'authentification
│   │   ├── login_view.dart            # Vue de connexion
│   │   ├── register_view.dart         # Vue d'inscription
│   │   └── user_profile_view.dart     # Vue de profil utilisateur
│   └── home/                         # Vues principales
│       ├── components/                # Composants réutilisables
│       │   ├── chat_panel.dart         # Panneau de chat
│       │   ├── daily_reward.dart       # Composant de récompense quotidienne
│       │   └── sidebar_menu.dart       # Menu latéral
│       ├── lobby/                     # Vues de lobby
│       │   ├── create_lobby_screen.dart # Écran de création de lobby
│       │   ├── find_lobby_view.dart     # Vue de recherche de lobby
│       │   ├── lobby_detail_view.dart   # Vue détaillée d'un lobby
│       │   └── lobby_list_view.dart     # Vue de liste des lobbies
│       ├── create_lobby_view.dart     # Vue de création de lobby
│       └── home_view.dart             # Vue principale de l'application
├── widgets/                          # Widgets réutilisables
│   ├── auth/                         # Widgets d'authentification
│   │   ├── login_form.dart            # Formulaire de connexion
│   │   └── register_form.dart         # Formulaire d'inscription
│   ├── chat/                         # Widgets de chat
│   │   ├── chat_bubble.dart           # Bulle de message de chat
│   │   ├── chat_input.dart            # Champ de saisie de chat
│   │   └── chat_message_list.dart     # Liste des messages de chat
│   ├── home/                         # Widgets de la page d'accueil
│   │   ├── category_filter.dart       # Filtre par catégorie
│   │   ├── lobby_card.dart            # Carte représentant un lobby
│   │   ├── news_carousel.dart         # Carrousel d'actualités
│   │   ├── quiz_card.dart             # Carte représentant un quiz
│   │   ├── quiz_history_item.dart     # Élément d'historique de quiz
│   │   └── user_stats_card.dart       # Carte des statistiques utilisateur
│   ├── profile/                       # Widgets de profil
│   │   ├── avatar_picker.dart         # Sélecteur d'avatar
│   │   ├── avatar_preview.dart        # Prévisualisation d'avatar
│   │   └── color_selector.dart        # Sélecteur de couleur
│   └── shared/                        # Widgets partagés
│       ├── animated_button.dart       # Bouton animé
│       ├── error_display.dart         # Affichage d'erreur
│       ├── loading_display.dart       # Indicateur de chargement
│       ├── progress_button.dart       # Bouton avec indicateur de progression
│       ├── search_bar.dart            # Barre de recherche
│       └── section_header.dart        # En-tête de section
├── main.dart                         # Point d'entrée de l'application
└── private_key.dart                  # Clés privées (non incluses dans le dépôt)
```

## Description des fichiers et leurs fonctions

### Fichiers principaux

#### main.dart

Point d'entrée de l'application qui initialise Firebase, configure les providers (injection de dépendances) et définit la structure de base de l'application. Il configure également le routeur et le thème.

#### private_key.dart

Stocke les clés privées et les configurations sensibles qui ne sont pas incluses dans le dépôt Git.

### Configuration

#### app_config.dart

Contient toutes les constantes et les configurations globales de l'application comme les URLs, les valeurs par défaut, les limites de validation et les paramètres de jeu. Inclut également la définition et la liste des couleurs de profil disponibles pour les avatars utilisateurs.

### Utilitaires

#### color_utils.dart

Fournit des méthodes standardisées pour la manipulation et la conversion des couleurs dans l'application :

- `fromValue()` : Convertit différentes représentations (int, string, nom) en objet Color
- `toStorageValue()` : Standardise le format de stockage des couleurs
- `getProfileColorByName()` : Trouve une couleur de profil par son nom
- `getProfileColorFromColor()` : Trouve une ProfileColor correspondant à une Color
- `getTextColorForBackground()` : Détermine la couleur de texte appropriée pour un fond

### Contrôleurs

Les contrôleurs suivent le modèle MVC (Modèle-Vue-Contrôleur) et sont responsables de la logique métier de l'application.

#### Contrôleurs de Lobby

- **lobby_controller.dart**: Contrôleur principal qui orchestre les autres contrôleurs de lobby. Il sert de façade pour les vues.
- **lobby_base_controller.dart**: Classe de base abstraite qui fournit des fonctionnalités communes à tous les contrôleurs de lobby.
- **lobby_management_controller.dart**: Gère la création, modification et suppression des lobbies.
- **lobby_player_controller.dart**: Gère les actions des joueurs dans un lobby (rejoindre, quitter, être prêt, etc.).
- **lobby_activity_controller.dart**: Gère les activités qui se déroulent dans un lobby (démarrer une partie, passer à la question suivante, etc.).

#### Helpers des contrôleurs

- **lobby_activity_helper.dart**: Fonctions d'aide pour les activités de lobby.
- **lobby_player_helper.dart**: Fonctions d'aide pour la gestion des joueurs.

#### Interfaces des contrôleurs

- **i_controller_base.dart**: Interface de base pour tous les contrôleurs.
- **i_lobby_activity_controller.dart**: Interface pour les contrôleurs d'activités de lobby.
- **i_lobby_management_controller.dart**: Interface pour les contrôleurs de gestion de lobby.
- **i_lobby_player_controller.dart**: Interface pour les contrôleurs de joueurs.

### Modèles

Les modèles représentent les structures de données utilisées dans l'application.

#### Modèles de Chat

- **chat_message_model.dart**: Représente un message de chat avec son contenu, son expéditeur et sa date.

#### Modèles de Lobby

- **lobby_model.dart**: Représente un lobby avec ses propriétés (nom, hôte, joueurs, paramètres).
- **lobby_player_model.dart**: Représente un joueur dans un lobby (identifiant, nom, avatar, statut).

#### Modèles de Quiz

- **quiz_model.dart**: Représente un quiz avec ses métadonnées et ses questions.
- **question_model.dart**: Représente une question de quiz avec ses réponses possibles.
- **quiz_answer_model.dart**: Représente une réponse à une question.
- **quiz_category_model.dart**: Représente une catégorie de quiz.
- **quiz_session_model.dart**: Représente une session de jeu active.

#### Modèles d'Utilisateur

- **user_model.dart**: Représente un utilisateur avec son profil et ses paramètres.

#### Autres Modèles

- **error_code.dart**: Énumération des codes d'erreur standardisés pour l'application.

### Services

Les services sont des classes qui fournissent des fonctionnalités spécifiques à l'application.

#### Services Firebase

- **firebase_service.dart**: Service principal pour l'initialisation et l'accès à Firebase.
- **auth_service.dart**: Gère l'authentification des utilisateurs.
- **avatar_service.dart**: Gère les avatars des utilisateurs.

#### Services de validation et d'erreur

- **validation_service.dart**: Centralise toutes les validations de données dans l'application :
  - Validation des champs d'authentification (nom d'utilisateur, email, mot de passe)
  - Validation des paramètres de lobby (nom, nombre de joueurs, code d'accès)
  - Validation des éléments de quiz (titre, questions, réponses)
  - Fournit des méthodes statiques réutilisables pour tous les contrôleurs et vues
- **error_message_service.dart**: Gère l'affichage des messages d'erreur.
- **logger_service.dart**: Service de journalisation pour le débogage.

#### Services Quiz

- **quiz_service.dart**: Service principal pour la gestion des quiz.
- **question_service.dart**: Gère les questions des quiz.
- **session_service.dart**: Gère les sessions de jeu.
- **lobby_service.dart**: Gère les lobbies de quiz.

#### Autres Services

- **chat_service.dart**: Gère les fonctionnalités de chat.
- **theme_service.dart**: Gère les thèmes de l'application.

#### Helpers de Services

- **auth_helper.dart**: Fonctions d'aide pour l'authentification.
- **cloud_storage_helper.dart**: Fonctions d'aide pour Cloud Storage.
- **firestore_helper.dart**: Fonctions d'aide pour Firestore.
- **mapping_helper.dart**: Fonctions d'aide pour le mapping de données.

### Vues

Les vues sont les interfaces utilisateur de l'application.

#### Vues d'Authentification

- **login_view.dart**: Vue de connexion.
- **register_view.dart**: Vue d'inscription.
- **user_profile_view.dart**: Vue de profil utilisateur.

#### Vues Principales

- **home_view.dart**: Vue principale de l'application.
- **create_lobby_view.dart**: Vue pour créer un nouveau lobby.

#### Vues de Lobby

- **lobby_list_view.dart**: Affiche la liste des lobbies disponibles.
- **lobby_detail_view.dart**: Affiche les détails d'un lobby spécifique.
- **find_lobby_view.dart**: Vue pour rechercher un lobby.
- **create_lobby_screen.dart**: Écran de création de lobby.

#### Composants

- **chat_panel.dart**: Panneau de chat intégré.
- **sidebar_menu.dart**: Menu latéral de navigation.
- **daily_reward.dart**: Composant pour les récompenses quotidiennes.

### Widgets

Les widgets sont des composants d'interface utilisateur réutilisables.

#### Widgets d'Authentification

- **login_form.dart**: Formulaire de connexion.
- **register_form.dart**: Formulaire d'inscription.

#### Widgets de Chat

- **chat_bubble.dart**: Bulle de message pour le chat.
- **chat_input.dart**: Champ de saisie pour le chat.
- **chat_message_list.dart**: Liste des messages de chat.

#### Widgets de la Page d'Accueil

- **lobby_card.dart**: Carte représentant un lobby.
- **quiz_card.dart**: Carte représentant un quiz.
- **category_filter.dart**: Filtre par catégorie.
- **news_carousel.dart**: Carrousel pour afficher les actualités.
- **user_stats_card.dart**: Carte des statistiques utilisateur.
- **quiz_history_item.dart**: Élément d'historique de quiz.

#### Widgets de Profil

- **avatar_picker.dart**: Sélecteur d'avatar.
- **avatar_preview.dart**: Prévisualisation d'avatar.
- **color_selector.dart**: Sélecteur de couleur pour le profil.

#### Widgets Partagés

- **animated_button.dart**: Bouton avec animations.
- **error_display.dart**: Widget pour afficher les erreurs.
- **loading_display.dart**: Widget pour afficher un indicateur de chargement.
- **progress_button.dart**: Bouton avec indicateur de progression.
- **search_bar.dart**: Barre de recherche personnalisée.
- **section_header.dart**: En-tête pour les sections de l'interface.

### Routage

#### app_routes.dart

Définit toutes les routes de l'application en utilisant GoRouter pour une navigation fluide et une gestion des paramètres d'URL.
