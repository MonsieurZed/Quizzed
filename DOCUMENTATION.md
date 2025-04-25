# 📚 Documentation Quizzzed

> **⚠️ IMPORTANT : Navigation et Structure d'interface**  
> Toutes les interfaces de l'application doivent impérativement conserver le menu latéral affiché.  
> Pour la navigation entre vues, il est essentiel d'utiliser `pushReplacementNamed` au lieu de `goNamed`  
> afin de préserver l'affichage du menu et maintenir la cohérence de l'expérience utilisateur.

## 🧱 Structure du Projet

```
lib/
  ├── main.dart              # Point d'entrée de l'application
  ├── config/                # Configurations globales
  │   └── app_config.dart    # Constantes et paramètres
  ├── controllers/           # Logique métier
  ├── models/                # Modèles de données
  │   ├── quiz/              # Modèles liés aux quiz
  │   │   ├── quiz_model.dart       # Modèle de quiz
  │   │   ├── question_model.dart   # Modèle de question
  │   │   ├── answer_model.dart     # Modèle de réponse
  │   │   ├── quiz_session_model.dart # Session de jeu
  │   │   └── score_model.dart      # Modèle de score
  │   └── user/              # Modèles liés aux utilisateurs
  │       ├── user_model.dart       # Modèle d'utilisateur
  │       └── profile_color.dart    # Modèle de couleur de profil
  ├── routes/                # Gestion de la navigation
  │   └── app_routes.dart    # Configuration du routeur
  ├── services/              # Services d'accès aux données
  │   ├── auth_service.dart  # Service d'authentification
  │   ├── avatar_service.dart # Service de gestion des avatars
  │   ├── firebase_service.dart # Service Firebase
  │   ├── logger_service.dart   # Service de journalisation
  │   └── quiz/              # Services de gestion des quiz
  │       ├── quiz_service.dart      # Service CRUD pour les quiz
  │       ├── question_service.dart  # Gestion des questions
  │       └── score_service.dart     # Gestion des scores
  ├── theme/                 # Thèmes et styles
  │   └── theme_service.dart # Service de gestion des thèmes
  ├── utils/                 # Fonctions utilitaires
  ├── views/                 # Interfaces utilisateur
  │   ├── auth/              # Vues d'authentification
  │   │   ├── login_view.dart         # Écran de connexion
  │   │   ├── register_view.dart      # Écran d'inscription
  │   │   └── forgot_password_view.dart # Écran de récupération de mot de passe
  │   ├── debug/             # Vues de débogage
  │   │   └── debug_view.dart         # Console de débogage
  │   ├── home/              # Vues de l'accueil
  │   │   ├── home_view.dart          # Écran d'accueil principal avec menu latéral
  │   │   ├── quiz_categories_view.dart # Liste des catégories
  │   │   ├── quiz_category_view.dart   # Quiz par catégorie
  │   │   ├── create_lobby_view.dart    # Création de lobby avec menu latéral
  │   │   ├── lobby_detail_view.dart    # Détails d'un lobby
  │   │   ├── lobby_list_view.dart      # Liste des lobbies disponibles
  │   │   └── lobbies_view.dart         # Vue conteneur pour les lobbies
  │   └── profile/           # Vues du profil utilisateur
  │       └── edit_profile_view.dart   # Édition du profil
  └── widgets/               # Composants réutilisables
      ├── auth/              # Widgets d'authentification
      │   ├── auth_button.dart        # Bouton d'authentification personnalisé
      │   └── auth_text_field.dart    # Champ de texte personnalisé
      ├── debug/             # Widgets de débogage
      │   ├── debug_access_button.dart # Bouton d'accès à la console
      │   └── log_viewer_widget.dart   # Visualiseur de logs
      ├── home/              # Widgets de l'accueil
      │   ├── quiz_category_card.dart # Carte de catégorie de quiz
      │   ├── quiz_card.dart         # Carte de quiz
      │   ├── recent_activity_card.dart # Carte d'activité récente
      │   ├── stats_card.dart         # Carte de statistiques
      │   ├── lobby_card.dart         # Carte de lobby
      │   └── lobby_player_item.dart  # Item de joueur dans un lobby
      └── profile/           # Widgets du profil utilisateur
          ├── avatar_preview.dart     # Prévisualisation d'avatar
          ├── avatar_selector.dart    # Sélecteur d'avatar
          └── color_selector.dart     # Sélecteur de couleur de fond
```

## 📝 Description des Services

### FirebaseService

- **Rôle**: Service principal pour l'initialisation et la gestion des connexions Firebase
- **Fonctionnalités**:
  - Initialisation de Firebase Auth, Firestore et Storage
  - Accès aux instances des services Firebase
  - Vérification de l'état de connexion

### AuthService

- **Rôle**: Gestion des opérations d'authentification utilisateur
- **Fonctionnalités**:
  - Connexion/Inscription avec email et mot de passe
  - Récupération de mot de passe
  - Déconnexion
  - Suivi de l'état d'authentification
  - Gestion des profils utilisateurs
  - Persistance de session
  - Gestion des erreurs Firebase
  - **Mode debug**: Authentification automatique avec identifiants admin

### LoggerService

- **Rôle**: Service de journalisation pour le débogage et le suivi des événements
- **Fonctionnalités**:
  - 5 niveaux de logs (debug, info, warning, error, critical)
  - Stockage des logs en mémoire avec limitation
  - Formatage avec horodatage et tags pour organisation
  - Capture des données associées et des stack traces
  - Filtrage des logs par niveau, tag, texte et date
  - Interface visuelle pour consulter et filtrer les logs
  - Accessible uniquement en mode debug

### ThemeService

- **Rôle**: Gestion des thèmes et de l'apparence visuelle
- **Fonctionnalités**:
  - Thèmes clair et sombre
  - Styles communs pour l'interface
  - Couleurs et polices cohérentes
  - Basculement dynamique entre les thèmes

### QuizService

- **Rôle**: Gestion CRUD pour les quiz et leurs composants
- **Fonctionnalités**:
  - Création, lecture, mise à jour et suppression de quiz
  - Gestion des questions et réponses
  - Filtrage par catégorie, popularité, créateur
  - Récupération des catégories disponibles
  - Suivi de la popularité des quiz

### AvatarService

- **Rôle**: Gestion et exploration des avatars disponibles dans l'application
- **Fonctionnalités**:
  - Exploration dynamique des avatars dans le dossier assets
  - Mise en cache des avatars trouvés pour optimiser les performances
  - Utilitaires pour manipuler les chemins d'avatars
  - Compatibilité avec Flutter Web

## 💬 Système de Chat

Le système de chat de l'application Quizzzed offre une communication en temps réel entre les utilisateurs dans les lobbies et sessions de quiz.

### Architecture du système de chat

#### Modèle de données

- `ChatMessageModel`: Représentation structurée des messages avec:
  - ID unique
  - Contenu du message
  - Informations sur l'expéditeur (ID, nom, avatar)
  - Horodatage
  - Type de message (utilisateur, système, notification)

#### Services

- **ChatService**:
  - Gestion des collections Firestore pour les messages
  - Envoi et récupération de messages en temps réel
  - Écoute des changements avec streams
  - Support pour les différents types de messages
  - Filtrage par contexte (lobby, quiz)
  - Gestion des notifications système automatiques

#### Interface utilisateur

- **ChatWidget**:

  - Interface complète de chat avec scrolling automatique
  - Affichage des messages selon le type avec styles différenciés
  - Zone de saisie avec validation
  - Animation lors de nouveaux messages
  - Adaptation responsive
  - Gestion de l'état de chargement

- **ChatBubble**:
  - Rendu visuel d'un message individuel
  - Styles différents pour les messages de l'utilisateur courant et les autres
  - Affichage configurable de l'avatar et de l'horodatage
  - Couleurs adaptées au thème de l'application

### Fonctionnalités

1. **Messages en temps réel**:

   - Synchronisation instantanée des messages
   - Indicateur visuel pour les nouveaux messages
   - Défilement automatique vers le dernier message

2. **Notifications système**:

   - Messages automatiques pour les événements importants (joueur rejoint/quitte)
   - Style visuel distinct pour les messages système
   - Horodatage pour tous les événements

3. **Support contextuel**:

   - Isolation des messages par contexte (lobby ou session quiz)
   - Persistance des messages pendant toute la durée de vie du contexte
   - Filtrage automatique basé sur l'ID du contexte courant

4. **Intégration avec le système d'utilisateurs**:

   - Affichage cohérent des avatars et noms d'utilisateurs
   - Messages associés au profil de l'expéditeur

5. **Gestion de l'état**:
   - États de chargement et d'erreur gérés
   - Fallback pour les situations sans message
   - Conservation du contexte lors du changement de vue

### Implémentation technique

- Utilisation de Firebase Firestore pour le stockage et la synchronisation
- Streams pour l'actualisation en temps réel
- Architecture en couches (modèle, service, widgets)
- Adaptation aux thèmes clair et sombre
- Optimisation des performances avec limitation du nombre de messages chargés

### Bonnes pratiques d'utilisation

1. Toujours initialiser le chat avec un contexte spécifique (lobbyId ou sessionId)
2. Utiliser la méthode `chatService.sendMessage()` pour envoyer des messages utilisateur
3. Utiliser la méthode `chatService.sendSystemMessage()` pour les notifications automatiques
4. Configurer `autoScroll` à true pour une meilleure expérience utilisateur
5. Implémenter une politique de nettoyage des anciens messages pour optimiser les performances

## ⚙️ Configuration Globale

Le fichier `app_config.dart` contient les constantes et paramètres globaux:

- Informations sur l'application (version, nom)
- Paramètres Firebase (noms des collections)
- Paramètres de validation des formulaires
- Configuration des animations
- Valeurs par défaut pour le quiz

## 🧭 Navigation

Le système de routage utilise `go_router` pour gérer:

- Les routes protégées (authentification requise)
- Les redirections basées sur l'état d'authentification
- La navigation entre les pages
- Les paramètres de route
- Écran d'accueil avec délai de redirection

### Architecture ShellRoute pour le menu persistant

Une architecture de navigation avancée a été implémentée pour garantir la persistance du menu latéral dans toutes les vues de l'application:

- **Shell Route Pattern**: Utilisation du pattern "Shell Route" de go_router où une vue parente (HomeView) contient le menu latéral et reçoit le contenu des vues enfants
- **Structure des routes**:

  ```
  ShellRoute (HomeView)
  ├── /home → HomeContent
  ├── /home/lobbies → LobbiesView
  │   └── /home/lobbies/:id → LobbyDetailView
  ├── /home/create → CreateLobbyView
  ├── /home/leaderboard → LeaderboardView
  └── /home/settings → SettingsContent
  ```

- **Séparation des responsabilités**:
  - `HomeView`: Agit uniquement comme conteneur (shell) avec le menu latéral
  - Vues de contenu comme `HomeContent`, `LobbiesView`: Rendent uniquement le contenu spécifique
- **Gestion de l'état du menu**:
  - L'état d'expansion du menu (étendu/compact) est conservé lors de la navigation
  - L'élément actif du menu est déterminé automatiquement en fonction de l'URL actuelle
- **Navigation correcte**:

  - Utilisation de `context.go()` pour naviguer entre les routes imbriquées
  - Les transitions sont fluides sans rechargement du menu

- **Avantages de cette architecture**:
  - Résolution permanente du problème de menu disparaissant lors de la navigation
  - Code plus modulaire avec une séparation claire des composants
  - Expérience utilisateur cohérente entre toutes les sections
  - Réduction de la duplication de code par factorisation du menu

### Bonnes pratiques de navigation

- Éviter d'implémenter des menus latéraux indépendants dans les vues enfants
- Utiliser la navigation imbriquée (`context.go('/home/lobbies')`) plutôt que des remplacements complets
- Respecter la séparation des responsabilités entre le conteneur et les vues de contenu
- Maintenir la structure de routes cohérente avec l'architecture UI

## 🛠️ Fonctionnalités de développement

### Mode debug

Pour faciliter le développement, plusieurs fonctionnalités sont automatiquement activées en mode debug (`kDebugMode`):

- **Authentification automatique**: Connexion automatique avec les identifiants admin depuis `private_key.dart`
- **Champs pré-remplis**: Les formulaires d'authentification sont pré-remplis avec les identifiants admin
- **Console de logs**: Accessible depuis n'importe quelle page via un bouton flottant
- **Journalisation détaillée**: Enregistrement des actions pour faciliter le débogage

### Configuration des ressources

- Les chemins des ressources sont centralisés dans `app_config.dart`
- L'avatar par défaut est configuré pour utiliser une image existante dans le projet

## 📱 Interface Utilisateur

### Authentification

- **Login**: Connexion via email/mot de passe avec validation de formulaire
- **Register**: Création de compte avec:
  - Validation des champs (email, mot de passe, etc.)
  - Sélection d'avatar parmi une galerie prédéfinie
  - Choix de couleur de fond pour l'avatar
  - Prévisualisation en temps réel de l'apparence du profil

### Profil Utilisateur

- **Édition de profil**: Interface complète permettant de:
  - Modifier le pseudo (avec validation)
  - Changer l'avatar parmi une galerie dynamique d'images
  - Sélectionner une couleur de fond pour l'avatar parmi ~20 options
  - Modifier le mot de passe avec double vérification
  - Prévisualiser les changements en temps réel
- **Persistance**: Sauvegarde automatique dans Firestore et Firebase Auth

### Accueil et Navigation Principale

- **Menu latéral adaptatif**:

  - Panneau latéral rétractable avec deux états : étendu (250px) et compact (70px)
  - Affichage du profil utilisateur avec avatar, nom et email
  - Navigation intuitive entre les sections principales
  - Adaptation automatique à la taille d'écran (responsive design)
  - Transitions animées entre les états du menu
  - Option de repli/dépli contrôlé par l'utilisateur
  - Intégré dans toutes les vues principales, y compris la création de lobby

- **Tableau de bord**:

  - Vue d'ensemble des statistiques utilisateur
  - Affichage personnalisé avec salutation utilisant le nom du joueur
  - Sections organisées avec en-têtes clairs et options "voir tout"

- **Sections principales**:

  - Accueil : Statistiques, catégories et quiz populaires
  - Classement : Performances des joueurs (à venir)
  - Création : Outils de création de quiz (à venir)
  - Paramètres : Configuration du profil et de l'application

- **Éléments d'UI interactifs**:
  - Cartes de catégories avec défilement horizontal
  - Cartes de quiz avec indicateurs de difficulté visuels
  - Indicateur de chargement pendant les opérations asynchrones
  - Pull-to-refresh pour actualiser le contenu

### Système de Lobby

- **Création de lobby**:

  - Interface avec menu latéral cohérent avec le reste de l'application
  - Formulaire complet de configuration:
    - Nom du lobby, catégorie
    - Options de visibilité (public/privé)
    - Paramètres de nombre de joueurs (min/max)
  - Validation des champs avec messages d'erreur contextuels
  - Création fluide avec retour visuel pendant le traitement

- **Liste des lobbies**:

  - Interface épurée sans bandeau de titre
  - Menu horizontal d'actions en haut de la liste:
    - Bouton principal "Créer un lobby"
    - Bouton secondaire "Rejoindre avec un code"
    - Bouton de rafraîchissement
  - Liste des lobbies publics disponibles
  - Options pour rejoindre directement un lobby

- **Détails du lobby**:
  - Visualisation des joueurs présents avec leur statut
  - Affichage du code pour les lobbies privés (copiable)
  - Options spécifiques pour l'hôte (expulser des joueurs, démarrer la partie)
  - Indicateur de joueurs prêts/non prêts

### Débogage

- **Console de logs**: Visualisation et filtrage des logs de l'application
- **Bouton d'accès rapide**: Présent en overlay sur toutes les pages en mode debug
- **Configuration du logger**: Modification du niveau minimum des logs affichés
- **Génération de logs test**: Outils pour tester le système de journalisation

## 🔧 Déploiement Firebase

L'application est configurée pour être déployée sur Firebase:

- **Hosting**: Configuration pour héberger l'application web
- **Firestore**: Base de données NoSQL avec règles de sécurité
- **Storage**: Stockage de fichiers pour les avatars et images de quiz
- **Authentication**: Système d'authentification pour les utilisateurs

### Fichiers de Configuration

- `firebase.json`: Configuration principale du déploiement
- `firestore.rules`: Règles de sécurité pour la base de données
- `storage.rules`: Règles de sécurité pour le stockage
- `firestore.indexes.json`: Configuration des index pour les requêtes

---

## ✅ Fonctionnalités implémentées

### ✓ Étape 1 – Base du projet

- Structure du projet
- Configuration Firebase
- Thème de l'application

### ✓ Étape 2 – Authentification

- Pages login / register / mot de passe oublié
- Persistance de session
- AuthGuard sur routes sécurisées
- Modèle d'utilisateur
- Sélection d'avatar et couleur de fond lors de l'inscription

### ✓ Étape 3 – Gestion du profil

- Édition complète du profil utilisateur:
  - Avatar avec exploration dynamique du dossier `/assets/images/avatars`
  - Sélection de couleur de fond parmi ~20 options prédéfinies
  - Modification du pseudo avec validation
  - Changement de mot de passe sécurisé
- Sauvegarde dans Firestore et synchronisation avec Firebase Auth

### ✓ Étape 4 – Page d'accueil et Navigation

- Tableau de bord informatif avec statistiques utilisateur
- Menu latéral adaptatif et responsive:
  - Version compacte pour maximiser l'espace de contenu
  - Version étendue pour une meilleure lisibilité
  - Adaptation automatique selon la taille d'écran
- Affichage des catégories et des quiz populaires
- Paramètres utilisateur et options de déconnexion
- Interface responsive optimisée pour mobiles, tablettes et web

### ✓ Étape 4 – Modèle Quiz

- Définition des modèles de données (Quiz, Question, Réponse)
- Service CRUD pour les quiz
- Affichage des quiz par catégorie

### ✓ Étape 4 – Lobbies et navigation

- Interface de création de lobby avec menu latéral
- Liste des lobbies publics avec filtrage par catégorie
- Système de lobbies privés avec code d'accès
- Vue détaillée des lobbies avec gestion des joueurs
- Interface cohérente avec menu latéral dans toutes les vues principales
- Adaptation responsive pour différentes tailles d'écran

### ✓ Étape 12 – Débogage et Logs

- Service de journalisation avec plusieurs niveaux
- Interface de visualisation des logs
- Filtrage et recherche dans les logs
- Console de débogage accessible depuis toutes les pages

## 🚧 Prochaines étapes

### Étape 5 – Jeu Quiz

- Interface de jeu
- Logique de temps et de score
- Enregistrement des résultats

## 📋 Fonctionnalités spécifiques implémentées

### Système de Lobby

Le développement du système de lobby a été complété avec les fonctionnalités suivantes :

#### Modèles et contrôleurs

- `LobbyModel` et `LobbyPlayerModel` pour représenter les lobbies et leurs joueurs
- `LobbyController` et `QuizSessionController` pour gérer la logique métier

#### Fonctionnalités de base

- Création de lobbies publics et privés avec paramètres configurables
- Affichage de la liste des lobbies publics disponibles
- Filtrage des lobbies par catégorie
- Rejoindre un lobby public ou privé (avec code d'accès)
- Interface détaillée d'un lobby avec liste des joueurs

#### Fonctionnalités avancées

1. **Gestion améliorée des lobbies**

   - Un utilisateur ne peut rejoindre qu'un seul lobby à la fois
   - Déconnexion automatique du lobby précédent lors de la connexion à un nouveau
   - Indicateur visuel du lobby actuel dans la liste des lobbies
   - Accès rapide au lobby actuel via un raccourci dans le menu latéral
   - Persistance de la connexion au lobby même en changeant de page

2. **Affichage optimisé des joueurs**

   - Indicateurs visuels clairs pour les joueurs prêts/en attente
   - Animation de pulsation pour les joueurs en attente
   - Point vert pour indiquer les joueurs actifs récemment

3. **Moteur de recherche de lobby**

   - Barre de recherche par nom ou catégorie
   - Toggle pour afficher/masquer la recherche
   - Messages adaptés lorsqu'aucun résultat n'est trouvé

4. **Gestion de l'activité des joueurs**

   - Détection automatique des joueurs déconnectés
   - Suppression des joueurs inactifs après 3 minutes
   - Suppression des lobbies inactifs après une heure

5. **Animation lors du démarrage d'un quiz**

   - Animation de cercle qui s'agrandit à partir du centre
   - Texte apparaissant progressivement
   - Transition fluide vers la vue de session de quiz

6. **Gestion des erreurs**

   - Correction des défauts d'interface pendant la phase de build
   - Optimisation du système de notification avec Future.microtask
   - Meilleure gestion des exceptions

7. **Contrôle des lobbies**

   - Bouton de suppression de lobby pour l'hôte avec confirmation
   - Limite d'un seul lobby actif par utilisateur pour éviter la prolifération
   - Dialogue de confirmation pour les actions destructives (supprimer un lobby)
   - Séparation claire des actions de sortie et de suppression

8. **Génération de noms aléatoires pour les lobbies**

   - Bouton de génération automatique de noms créatifs pour les lobbies
   - Dictionnaires d'adjectifs et de substantifs stockés dans `assets/dictionary/`
   - Combinaison intelligente produisant des noms comme "Mythique Challenge" ou "Épique Tournoi"
   - Interface intuitive avec bouton de rafraîchissement à côté du champ de nom
   - Architecture flexible permettant d'étendre facilement les dictionnaires

9. **Synchronisation des profils dans les lobbies**
   - Mise à jour automatique des informations utilisateur dans tous les lobbies lorsque le profil est modifié
   - Synchronisation de l'avatar, du nom d'affichage et de la couleur de fond
   - Système robuste qui conserve la cohérence visuelle à travers l'application
   - Implémentation efficace pour minimiser les opérations de base de données

Les améliorations ont rendu le système plus robuste, avec une meilleure expérience utilisateur grâce à des animations fluides, une interface responsive et une gestion efficace des joueurs inactifs.

## 📂 Structure des fichiers de ressources

### Dictionnaires pour la génération de noms

L'application utilise des dictionnaires JSON stockés dans `assets/dictionary/` pour générer des noms de lobbies aléatoires :

- **adjectifs.json** : Liste de 40 adjectifs descriptifs en français
- **names.json** : Liste de 40 substantifs liés aux quiz et défis

Ces dictionnaires permettent de créer automatiquement des noms de lobbies créatifs et engageants. L'architecture modulaire permet d'étendre facilement ces listes sans modifier le code source.

### Avatars

Les avatars sont organisés dans deux dossiers :

- **assets/images/avatars/** : Avatars en résolution standard pour l'interface principale
- **assets/images/avatars1024/** : Avatars en haute résolution pour les prévisualisations détaillées

L'application explore dynamiquement ces dossiers pour offrir aux utilisateurs un large choix d'avatars personnalisés.

## 🎨 Système de couleurs de profil pour les avatars

L'application Quizzzed implémente un système cohérent de couleurs de profil pour les avatars utilisateurs, assurant une identité visuelle cohérente à travers toutes les interfaces de l'application.

### Structure et organisation

- **AppConfig**: Contient la classe `ProfileColor` et la liste des couleurs disponibles

  - La classe `ProfileColor` définit une couleur disponible pour le profil avec:
    - Nom de la couleur (ex: "Rouge", "Bleu", "Vert")
    - Valeur de la couleur (instance de `Color`)
    - Couleur de texte adaptée pour le contraste (blanc par défaut, noir pour les couleurs claires)
  - `availableProfileColors`: Liste de ~40 options prédéfinies couvrant tout le spectre chromatique

- **ColorUtils**: Classe utilitaire pour la manipulation des couleurs
  - `fromValue()`: Convertit différentes représentations (int, string, nom) en objet Color
  - `toStorageValue()`: Standardise le format de stockage des couleurs
  - `getProfileColorByName()`: Trouve une couleur de profil par son nom
  - `getProfileColorFromColor()`: Trouve une ProfileColor correspondant à une Color
  - `getTextColorForBackground()`: Détermine la couleur de texte appropriée pour un fond

### Intégration dans l'interface utilisateur

La couleur de profil sélectionnée par l'utilisateur est utilisée de manière cohérente dans toute l'application:

1. **Chat**:

   - Arrière-plan de l'avatar dans les bulles de chat
   - Couleur des bulles de messages pour les autres utilisateurs
   - Contraste automatique adapté pour la lisibilité du texte

2. **Lobbies**:

   - Couleur d'arrière-plan des avatars dans la liste des joueurs
   - Couleur de la carte du lobby si l'utilisateur est l'hôte
   - Indicateurs visuels cohérents avec la couleur de profil

3. **Profil utilisateur**:
   - Aperçu en temps réel lors de la sélection de couleur
   - Persistance dans les données utilisateur (Firestore)
   - Sélecteur visuel avec échantillons de toutes les couleurs disponibles

### Implémentation technique

- La couleur est stockée comme valeur numérique dans Firestore via `ColorUtils.toStorageValue()`
- Les modèles utilisent `ColorUtils.fromValue()` pour la désérialisation cohérente
- La configuration des couleurs disponibles est centralisée dans `AppConfig`
- Les widgets utilisent `ColorUtils` pour obtenir des couleurs de texte contrastées

### Synchronisation

Lorsqu'un utilisateur modifie sa couleur de profil, cette modification est propagée automatiquement:

1. Mise à jour dans Firebase Auth et Firestore (`UserModel`)
2. Apparition immédiate dans tous les affichages d'avatar de cet utilisateur
3. Actualisation dans les messages de chat et listes de joueurs dans les lobbies

### Avantages de l'implémentation refactorisée

1. **Centralisation**: Toutes les définitions de couleurs dans un seul endroit (`AppConfig`)
2. **Cohérence**: Manipulation standardisée des couleurs via `ColorUtils`
3. **Robustesse**: Gestion améliorée des erreurs et des formats invalides
4. **Maintenabilité**: Logique de conversion séparée des modèles de données
5. **Extensibilité**: Ajout facile de nouvelles couleurs ou méthodes utilitaires

### Bonnes pratiques d'utilisation

1. Utiliser `ColorUtils.fromValue()` pour convertir des données de stockage en couleurs
2. Utiliser `ColorUtils.toStorageValue()` pour préparer les couleurs au stockage
3. Accéder aux couleurs prédéfinies via `AppConfig.availableProfileColors`
4. Utiliser `ColorUtils.getTextColorForBackground()` pour garantir la lisibilité du texte
5. Prévoir des couleurs de repli pour les cas où la couleur n'est pas définie

Cette architecture refactorisée renforce l'identité visuelle des utilisateurs et améliore l'expérience utilisateur en maintenant une cohérence visuelle à travers toutes les interfaces de l'application, tout en rendant le code plus maintainable.
