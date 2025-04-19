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
- [ ] Configurer Firebase Auth (compte admin uniquement)
- [ ] Configurer Firestore ou Realtime Database
- [ ] Configurer Firebase Storage pour les médias
- [ ] Déployer l’app sur Firebase Hosting
- [ ] Créer un **thème visuel comfy/creamy** avec la palette suivante :
  - `#F2F2F2` : fond général
  - `#5A86E7`, `#6494E9` : boutons, hover, surbrillances
  - `#4266B2` : accent ou texte principal
- [ ] Créer l’architecture Flutter avec les pages principales
- [ ] Appliquer le thème visuel à la navigation et à la page d’accueil
- [ ] Ajouter un favicon personnalisé au site
- [ ] Créer une vraie page d’accueil (titre, description, bouton "Rejoindre la partie")

## Étape 2 — Créer les modèles de quiz

- [ ] Définir le modèle de données des quiz  
       Champs :

  - `question`
  - `type` (qcm, image, son, vidéo, open)
  - `media` (URL ou Storage)
  - `choices`, `correct` (si QCM)
  - `order` (ordre dans la session)
  - `difficulty` (facile, moyen, difficile)

- [ ] Stocker les quiz dans Firestore, organisés par sessions
- [ ] Lier les médias à Firebase Storage (upload et URL)

## Étape 3 — Développer l’interface MJ (admin)

- [ ] Écran de connexion admin via Firebase Auth
- [ ] Interface de création de quiz (texte, type, média, ordre, difficulté)
- [ ] Sauvegarde des quiz et sessions dans Firestore
- [ ] Interface de lancement de session de quiz par le MJ
- [ ] Réglage du pourcentage de validation des réponses libres (par défaut : 50%)
- [ ] Ajouter une interface permettant à l’**admin d’attribuer des points manuellement** à un ou plusieurs joueurs
- [ ] Possibilité de créer/lancer plusieurs sessions dans le même lobby

## Étape 4 — Développer l’interface Joueur

- [ ] Connexion joueur avec pseudo simple
- [ ] Affichage des joueurs existants pour reprise de session
- [ ] Personnalisation joueur :

  - Avatar (dans `/assets/avatar`)
  - Couleur de fond personnalisée

- [ ] Affichage du lobby unique avec tous les joueurs
- [ ] Affichage des joueurs avec avatar, pseudo, couleur

- [ ] Affichage d’une question avec :

  - Texte
  - Média (optionnel)
  - Niveau de difficulté

- [ ] Timer + réponse du joueur (saisie + validation)
- [ ] Affichage des joueurs en direct (grisé si pas encore répondu)

- [ ] Interface de validation communautaire :

  - Affichage des réponses libres
  - Vote par les joueurs
  - Acceptation auto si seuil atteint

- [ ] Calcul des scores en temps réel
- [ ] Page de résultats en fin de session
- [ ] Reconnexion du joueur avec récupération complète
- [ ] Tests multi-utilisateurs en LAN

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

## Besoins architecturaux futurs

- Configuration concrète de Firebase avec les valeurs du projet réel (apiKey, authDomain, etc.)
- Mise en place de la navigation entre les pages (routes)
- Développement de services d'authentification pour administrateur et joueurs
- Structure de modèles de données pour les quiz et les sessions

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

---
