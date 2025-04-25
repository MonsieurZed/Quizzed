# Documentation du système de chat

**IMPORTANT**: Toute modification du fonctionnement du système de chat doit être mise à jour dans ce document.

## Vue d'ensemble

Le système de chat de l'application Quizzed permet aux joueurs de communiquer entre eux dans différents contextes: dans le lobby avant le début d'une partie, pendant une partie, et dans un contexte global.

## Canaux de communication

Le système de chat est organisé en plusieurs canaux:

- **Global**: Communication ouverte à tous les utilisateurs de l'application
- **Lobby**: Communication limitée aux joueurs présents dans un lobby spécifique
- **Partie**: Communication limitée aux joueurs participant à une partie en cours
- **Privé**: Messages échangés entre deux utilisateurs spécifiques

## Fonctionnalités

### Envoi et réception de messages

Les utilisateurs peuvent:

- Envoyer des messages textuels
- Voir l'historique des messages d'un canal
- Voir qui a envoyé chaque message avec leur avatar et nom d'utilisateur
- Voir l'horodatage de chaque message

### Notifications

Le système prévoit des notifications pour:

- Les messages non lus
- Les mentions spéciales (@utilisateur)
- Les événements importants du système (joueur qui rejoint/quitte, début de partie, etc.)

### Modération

- Les messages inappropriés peuvent être signalés
- L'hôte d'un lobby peut modérer les messages dans son lobby
- Les administrateurs ont des capacités de modération étendues

## Implémentation technique

### Architecture

Le système de chat est implémenté avec:

- Firebase Firestore pour le stockage des messages
- Streams temps-réel pour la mise à jour instantanée des interfaces
- Système de pagination pour charger l'historique par blocs

### Classes principales

- `ChatService`: Service principal gérant les opérations de chat
- `ChatMessage`: Modèle de données pour les messages
- `ChatChannel`: Enumération des différents canaux disponibles

## Interface utilisateur

L'interface utilisateur du chat comprend:

- Zone de saisie de texte avec bouton d'envoi
- Affichage des messages avec avatar, nom d'utilisateur et horodatage
- Indicateurs de statut (message envoyé, lu, etc.)
- Options de formatage de texte basique
