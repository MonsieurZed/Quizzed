# IA.md — Plan de développement pour le site de quiz LAN (Flutter + Firebase)

Ce fichier est la **source de coordination entre les agents IA** participant au développement du projet.  
Il est stocké à la **racine du projet**. Chaque IA doit :

- Réaliser une seule tâche à la fois
- Cocher l'étape correspondante
- Réémettre ce fichier mis à jour
- Ajouter des **indications pour les agents suivants** si nécessaire (voir plus bas)

---

## Contexte du projet

- Plateforme de quiz multijoueur pour une LAN entre amis
- Thème visuel : vert fluo (#39FF14) sur fond noir
- Un seul MJ (admin) avec compte Firebase Auth
- Joueurs anonymes se connectant avec un pseudo
- Lobby unique
- Plusieurs sessions de quiz possibles
- Types de quiz :
  - QCM
  - Image
  - Son
  - Vidéo
  - Réponse libre (type Petit Bac) avec validation communautaire
- Technologies :
  - Flutter Web
  - Firebase : Auth, Firestore, Storage, Hosting

---

# Checklist de progression

## Étape 1 — Créer la base technique du site

- [x] Initialiser le projet Flutter Web avec Firebase
- [x] Configurer Firebase Auth (compte admin uniquement)
- [x] Configurer Firestore ou Realtime Database
- [x] Configurer Firebase Storage pour les médias
- [x] Déployer l'app sur Firebase Hosting
- [x] Créer l'architecture Flutter avec les pages principales
- [x] Appliquer le thème visuel à la navigation et à la page d'accueil
- [x] Ajouter un favicon personnalisé au site
- [x] Créer une vraie page d'accueil (titre, description, bouton "Rejoindre la partie")

## Étape 2 — Créer les modèles de quiz

- [x] Définir le modèle de données des quiz  
       Champs :

  - `question`
  - `type` (qcm, image, son, vidéo, open)
  - `media` (URL ou Storage)
  - `choices`, `correct` (si QCM)
  - `order` (ordre dans la session)
  - `difficulty` (facile, moyen, difficile)

- [x] Stocker les quiz dans Firestore, organisés par sessions
- [x] Lier les médias à Firebase Storage (upload et URL)

## Étape 3 — Interaction MJ/Joueurs & Lobby (temps réel, synchronisation, sessions)

### 3.1 — Mise en place du système de lobby

- [ ] Ajouter un modèle `Lobby` dans Firestore avec les champs :
  - `lobbyId`, `adminId`, `status` (waiting, started, finished), `players` (array), `createdAt`
- [ ] Créer une interface MJ pour créer un lobby (formulaire simple)
- [ ] Sauvegarder le lobby dans Firestore à la création
- [ ] Afficher la liste des lobbies actifs pour les joueurs en temps réel

### 3.2 — Interface joueur + sauvegarde locale

- [ ] Créer l’interface de connexion joueur (pseudo uniquement)
- [ ] Ajouter la personnalisation (choix d’avatar dans `/assets/avatar`, couleur via color picker)
- [ ] Sauvegarder les infos du joueur dans `localStorage` :
  - `pseudo`, `avatar`, `color`, `lobbyId`, `score`
- [ ] Sauvegarder les mêmes infos dans Firestore (`players/{id}`)

### 3.3 — Reconnexion automatique

- [ ] Au chargement de l’app, vérifier si des infos sont présentes dans `localStorage`
- [ ] Si oui, relier automatiquement l’utilisateur à son lobby
- [ ] Re-synchroniser ses infos avec Firestore (`players/{id}`)

### 3.4 — Rejoindre un lobby + affichage temps réel

- [ ] Permettre au joueur de rejoindre un lobby en attente
- [ ] Ajouter le joueur dans la collection `players` et dans la liste `lobby.players`
- [ ] Afficher la liste des joueurs dans le lobby en temps réel avec avatar, couleur, pseudo

### 3.5 — Démarrage synchrone de la session

- [ ] Créer un bouton "Démarrer la partie" côté MJ
- [ ] À l’appui, changer le champ `status` du lobby dans Firestore → `started`
- [ ] Tous les joueurs reçoivent cet événement en temps réel et passent à l’écran de jeu

### 3.6 — Affichage de la question + réponses

- [ ] Afficher la question en cours avec : contenu, média (si présent), difficulté
- [ ] Démarrer un timer synchronisé
- [ ] Créer une interface de réponse (champ texte ou QCM selon type)

### 3.7 — Affichage en temps réel des réponses

- [ ] Créer un bandeau à droite avec la liste des joueurs
- [ ] Les joueurs sont grisés tant qu’ils n’ont pas répondu
- [ ] Passage en "actif" dès qu’une réponse est soumise

### 3.8 — Validation communautaire des réponses libres

- [ ] Afficher toutes les réponses reçues (texte)
- [ ] Permettre aux joueurs de liker les réponses
- [ ] Valider une réponse si % de likes >= seuil défini dans le lobby

### 3.9 — Calcul et affichage des scores

- [ ] Ajouter le score au joueur en fonction de la bonne réponse ou validation
- [ ] Mettre à jour Firestore (collection `players`)
- [ ] Afficher un classement en direct

### 3.10 — Fin de session et résultats

- [ ] Ajouter un écran de résultats final avec classement
- [ ] Permettre à l’admin de redémarrer une session ou revenir au lobby

### 3.11 — Tests multi-navigateurs LAN

- [ ] Ouvrir plusieurs sessions pour tester la synchro temps réel
- [ ] Vérifier le démarrage synchro, le passage des questions, la sauvegarde locale et la reconnexion automatique

---

## Architecture réalisée

### Initialization du projet Flutter Web avec Firebase

- Installation des dépendances Firebase:
  - `firebase_core`: Pour l'initialisation de Firebase
  - `firebase_auth`: Pour l'authentification
  - `cloud_firestore`: Pour la base de données
  - `firebase_storage`: Pour le stockage des médias
- Mise en place d'une structure de configuration Firebase dans `lib/config/firebase_config.dart`
- Initialisation de Firebase dans l'application principale
- Application du thème vert fluo (#39FF14) sur fond noir
- Création de la page d'accueil avec accès MJ et accès Joueur

### Configuration Firebase Auth (compte admin uniquement)

- Création d'un service d'authentification (`lib/services/auth_service.dart`) pour gérer le compte administrateur
- Mise en place de la méthode de connexion par email/mot de passe pour l'administrateur
- Création d'une page de connexion administrateur (`lib/screens/admin_login_screen.dart`)
- Intégration de la navigation depuis la page d'accueil vers la page de connexion admin
- Mise en place d'un système de validation des formulaires et de gestion des erreurs d'authentification

### Configuration Firestore

- Mise en place d'un service de base de données (`lib/services/database_service.dart`) avec méthodes CRUD complètes
- Définition des modèles de données pour les sessions de quiz, questions et joueurs
- Structure de collections Firestore : `quiz_sessions`, `questions`, `players`
- Implémentation de requêtes optimisées pour afficher les classements et les statistiques
- Configuration des règles de sécurité Firestore pour protéger les données
- Configuration des index Firestore pour améliorer les performances des requêtes
- Support pour la validation communautaire des réponses ouvertes

### Modèles de données et stockage des quiz

- Implémentation du modèle `Question` dans `lib/models/question.dart` avec tous les champs requis :
  - `questionText` pour le contenu de la question
  - `type` (enum pour qcm, image, son, vidéo, open)
  - `mediaUrl` pour les références aux médias
  - `choices` et `correctAnswer` pour les questions à choix multiples
  - `order` pour l'ordre des questions dans une session
  - `difficulty` (enum pour facile, moyen, difficile)
  - Champs additionnels comme `points` et `timeLimit`
- Implémentation du modèle `QuizSession` dans `lib/models/quiz_session.dart` pour organiser les quiz
- Création de `QuizRepository` dans `lib/repositories/quiz_repository.dart` avec méthodes CRUD complètes
- Configuration du service `StorageService` dans `lib/services/storage_service.dart` pour gérer les médias avec :
  - Support pour téléchargement d'images avec compression
  - Support pour médias audio et vidéo
  - Organisation en dossiers (images, audio, vidéo)
  - Génération d'URLs pour accéder aux médias depuis Firestore

### Déploiement sur Firebase Hosting

- Configuration des fichiers nécessaires pour le déploiement sur Firebase Hosting (`firebase.json` et `.firebaserc`)
- Mise à jour du fichier `web/index.html` pour inclure les scripts Firebase SDK
- Création d'un script de déploiement `deploy.bat` pour simplifier le processus de build et déploiement
- Optimisation du build web Flutter (tree-shaking des icônes pour réduire la taille des fichiers)
- Déploiement réussi de l'application sur l'URL: https://quizzed-base.web.app

### Interface de création de quiz

- Développement d'une interface complète pour la création des quiz (`lib/screens/admin/quiz_creation_screen.dart`)
- Mise en place d'un formulaire de création de session de quiz avec validation
- Création d'un formulaire pour l'ajout de questions multiples à une session
- Support pour différents types de questions (QCM, image, audio, vidéo, réponse libre)
- Intégration du service d'upload de médias avec Firebase Storage
- Support spécifique pour la plateforme Web (utilisation de `bytes` au lieu de `path`)
- Correction des règles de sécurité Firebase Storage pour permettre les uploads
- Interface pour la visualisation et la suppression des questions existantes

### Système de logging et débogage

- Création d'un service de logging centralisé (`lib/services/logging_service.dart`)
- Implémentation de niveaux de logs (error, warning, info, debug)
- Intégration du logging dans les services Firebase pour tracer les opérations
- Capture des erreurs lors des opérations avec Firebase (auth, firestore, storage)
- Configuration de `runZonedGuarded` dans le point d'entrée pour capturer toutes les erreurs non gérées
- Personnalisation du handler `FlutterError.onError` pour le logging des erreurs du framework

## Besoins architecturaux futurs

- Implémentation de l'interface de lancement de session de quiz
- Développement de l'écran d'interface joueur et du système de connexion joueur
- Mise en place du système de validation communautaire pour les réponses libres
- Intégration de la gestion des avatars et de la personnalisation joueur

---

## Règles à suivre

- Réaliser une seule tâche à la fois
- Cocher l'étape correspondante
- Réémettre ce fichier avec l'étape mise à jour
- Ne pas expliquer. Ne pas commenter. Exécuter.
- **Ajouter une note sous la section suivante si utile pour les agents suivants**

---

## Indications inter-agents

> Ce bloc est destiné aux **notes rapides entre IA**.  
> Laisse ici des conseils, remarques ou points d'attention à vérifier par l'agent suivant.

Pour l'agent suivant :

1. Les règles de sécurité Firebase Storage ont été configurées dans `storage.rules` et déployées avec succès. Les utilisateurs authentifiés peuvent maintenant uploader des fichiers médias.
2. La fonctionnalité d'upload de médias dans l'interface de création de quiz fonctionne désormais sur le web grâce aux corrections apportées au fichier `quiz_creation_screen.dart` (utilisation de `bytes` au lieu de `path`).
3. Un système de logging détaillé a été implémenté. Consultez le fichier `lib/services/logging_service.dart` et vérifiez son intégration dans les autres services.
4. La prochaine étape devrait se concentrer sur l'interface de lancement de session de quiz par le MJ et la connexion des joueurs au lobby.

---
