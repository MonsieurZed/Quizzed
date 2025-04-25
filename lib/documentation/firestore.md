# Documentation Firebase du projet Quizzed

**IMPORTANT**: Toute modification de la structure Firebase ou des règles de sécurité doit être mise à jour dans ce document.

## Structure de la base de données Firestore

Le projet Quizzed utilise Firebase Firestore comme base de données principale. Les collections suivantes sont définies:

### Collection `users`

Stocke les informations des utilisateurs:

- ID du document = ID de l'utilisateur Firebase Auth
- Données: informations de profil, préférences, statistiques

### Collection `quizzes`

Contient tous les quiz disponibles:

- ID du document = ID unique du quiz
- Données: titre, description, catégorie, questions, réponses, créateur

### Collection `lobbies` (et `lobbys` comme alias)

Gère les salles d'attente pour les parties:

- ID du document = ID unique du lobby
- Données: nom, description, statut, hôte, joueurs, paramètres, visibilité

### Collection `chat_messages`

Stocke les messages de chat:

- ID du document = ID unique du message
- Données: contenu, expéditeur, timestamp, contexte (lobbyId)

### Collection `questions`

Stocke les questions individuelles (peut être utilisée séparément des quiz):

- ID du document = ID unique de la question
- Données: texte, type, difficulté, options, réponse correcte

### Collection `scores`

Enregistre les scores des joueurs:

- ID du document = ID unique du score
- Données: utilisateur, quiz, points, date, classement

### Collection `messages`

Messages privés ou contextuels:

- ID du document = ID unique du message
- Données: contenu, expéditeur, destinataire, timestamp, roomId

### Collection `chatRooms`

Salles de chat distinctes des lobbies:

- ID du document = ID unique de la salle
- Données: participants, créateur, paramètres

## Règles de sécurité Firestore

### Principes généraux

- Authentification requise pour la plupart des opérations
- Vérification des autorisations basée sur l'ID utilisateur
- Protection contre les modifications non autorisées

### Fonctions utilitaires

- `isAdmin()`: Vérifie si l'utilisateur fait partie des administrateurs
- `isLobbyHost()`: Vérifie si l'utilisateur est l'hôte d'un lobby spécifique
- `isRoomParticipant()`: Vérifie si l'utilisateur est membre d'une salle de chat

### Permissions par collection

1. **users**: Lecture/écriture limitée à l'utilisateur lui-même
2. **quizzes**:

   - Lecture: tous les utilisateurs authentifiés
   - Création: tous les utilisateurs authentifiés
   - Modification: uniquement par le créateur
   - Suppression: uniquement par le créateur

3. **lobbies/lobbys**:

   - Lecture: tous les utilisateurs authentifiés
   - Création: tous les utilisateurs authentifiés
   - Modification: tous les utilisateurs authentifiés (pour permettre de rejoindre)
   - Suppression: uniquement par l'hôte du lobby

4. **chat_messages**:

   - Lecture: tous les utilisateurs authentifiés
   - Création: uniquement avec l'ID de l'utilisateur authentifié
   - Modification: interdite
   - Suppression: par l'expéditeur, l'hôte du lobby ou un administrateur

5. **questions**, **scores**, **messages**, **chatRooms**:
   - Règles spécifiques selon les besoins de l'application
   - En général, lecture limitée aux utilisateurs concernés
   - Écriture limitée selon le rôle et les permissions

## Configuration Firebase

Le projet utilise les services Firebase suivants:

- Firebase Authentication pour la gestion des utilisateurs
- Cloud Firestore pour la base de données
- Firebase Storage pour le stockage des fichiers (avatars, etc.)
- Firebase Hosting pour le déploiement web

La configuration est définie dans:

- `web/firebase/firebase_config.js` pour la configuration côté client
- `firebase.json` pour la configuration de déploiement
- `firestore.rules` pour les règles de sécurité Firestore
- `storage.rules` pour les règles de sécurité Storage
- `firestore.indexes.json` pour les index Firestore
