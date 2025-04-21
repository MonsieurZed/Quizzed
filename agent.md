# 🎯 Méga Prompt – Agent Flutter Web + Firebase

## 📘 Contexte du projet

Développement d’une application web de **quiz en temps réel**, pour ordinateur, en **Flutter Web** avec backend **Firebase**.

L'application permet :

- L’authentification des utilisateurs
- La création de profils personnalisés
- La gestion de lobbies publics/privés
- La création, l’édition et le jeu de quiz multijoueur
- Une synchronisation en temps réel
- Une interface desktop moderne et cohérente

---

## 🧱 Stack Technique

- **Flutter Web**
- **Firebase** : Auth, Firestore, Storage, Hosting, Functions
- **Architecture MVC**
- **ThemeService** pour la gestion des couleurs
- Desktop only (aucune optimisation mobile requise)

---

## ⚙️ Règles pour tous les agents

- Toujours **réutiliser le code existant**
- Suivre une **architecture MVC**
- Travailler en **itérations** (chaque agent prend un ou plusieurs blocs corrélés)
- **Documenter chaque fichier** en en-tête
- **Maintenir un fichier de documentation** contenant :
  - Arbre des fichiers
  - Description concise des services, modèles, providers
- **Interface homogène** via `ThemeService`
- Lancer `flutter run -d chrome` ou équivalent debug à la fin de chaque étape

---

## 📚 Fonctionnalités

### 🔐 Authentification & Profil

- Connexion / inscription / mot de passe oublié
- Persistance automatique de session après refresh
- Création & édition de profil :
  - Pseudo unique
  - Sélection avatar (exploration dynamique de `/assets/images/avatars`)
  - Couleur de fond (liste de ~20 prédéfinies)
  - Changement de mot de passe

### 🎮 Lobby multijoueur

- Liste des lobbys publics
- Rejoindre un lobby privé via code
- Création & édition de lobby avec paramètres
- Affichage des joueurs et statut (prêt / pas prêt)
- Le créateur (MJ) peut :
  - Lancer la partie
  - Supprimer des joueurs
  - Modifier les paramètres

### 🔄 Temps réel

- Realtime updates via Firestore streams
- Statut "en ligne / hors ligne"
- Reprise du jeu après reconnexion
- Suppression automatique après 1h d’inactivité

### ❓ Quiz

- Création & édition de quiz
- Types de questions :
  - Choix multiple (2 à 4)
  - Média (image, son, vidéo via Firebase Storage)
  - Réponse ouverte + votes (like/dislike)
- Timer configurable (30s par défaut)
- Points en fonction de la difficulté
- Affichage des résultats/votes
- Interface animée entre phases

### 🧠 Expérience joueur

- Déconnexion/reconnexion sans perte
- Affichage du score et pourcentages par question
- Classement en temps réel
- Bonus MJ

### ⚙️ Paramètres

- Thème clair/sombre
- Multi-langue (FR / EN min.)
- Préférences utilisateur (pseudo, thème...) sauvegardées localement
- Logs de debug

### 📊 Analytics

- Historique des parties
- Score global
- Quiz créés
- Rejouer un ancien quiz

### 🛡️ Sécurité & modération

- Auth obligatoire pour tout sauf accueil
- 1 vote par réponse, anti-spam (limite/sec)
- Nom unique dans un lobby
- Signalement quiz publics
- Lobbies ≠ Quiz (indépendants)

---

## 🔁 Étapes de développement

### ✅ Étape 1 – Initialisation

- Setup projet Flutter Web
- Setup Firebase + configuration base (Auth / Firestore / Storage)
- Architecture MVC + ThemeService
- Routing de base

### ✅ Étape 2 – Authentification

- Pages login / register / mot de passe oublié
- Persistance de session
- AuthGuard sur routes sécurisées

### ✅ Étape 3 – Gestion du profil

- Édition du profil :
  - Avatar via scan du dossier
  - Couleur de fond avatar
  - Pseudo + mot de passe
- Sauvegarde dans Firestore

### ✅ Étape 4 – Lobbys

- Interface création / rejoindre
- Liste des lobbys publics
- Formulaire de création (params)
- Affichage des joueurs + statut

### ✅ Étape 5 – Temps réel

- Mise à jour des lobbys et joueurs via stream
- Détection joueur offline
- Reconnexion automatique
- Auto-suppression lobby inactif

### ✅ Étape 6 – Création de quiz

- Interface ajout/modif quiz
- Ajout de question (texte + type)
- Upload média (Firebase Storage)
- Timer et difficulté

### ✅ Étape 7 – Partie en direct

- Démarrage quiz
- Timer question
- Envoi réponses
- Affichage des choix, scores
- Transition animée (si possible)

### ✅ Étape 8 – Réponses ouvertes

- Interface de réponse
- Interface de vote like/dislike
- Limitation des votes

### ✅ Étape 9 – Classement & fin

- Résultats entre chaque question
- Score final + classement
- Rejouer un quiz

### ✅ Étape 10 – Thèmes & langues

- Support FR/EN
- Thème clair/sombre via ThemeService
- Sauvegarde des préférences localement

### ✅ Étape 11 – Historique

- Liste des parties
- Stats persos (score cumulé, quiz créés)
- Rejouer quiz

### ✅ Étape 12 – Sécurité & modération

- Vérif droit MJ
- Signalement quiz
- Nettoyage automatique
- Logs de debug

---

**⚠️ À chaque étape, un agent doit :**

- Documenter les fichiers créés
- Décrire les modèles/services/providers
- Mettre à jour l’arbre du projet
- Lancer l’app en debug pour vérification

---
