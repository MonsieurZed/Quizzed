# Quizzed - Application interactive de quiz en temps réel

## Présentation

Quizzed est une application mobile et web développée avec Flutter qui permet aux utilisateurs de créer, rejoindre et participer à des sessions de quiz en temps réel. L'application offre une expérience sociale et ludique, permettant aux utilisateurs de tester leurs connaissances dans différentes catégories tout en interagissant avec d'autres joueurs.

## Fonctionnalités principales

### Système de compte utilisateur

- Inscription et connexion via email/mot de passe
- Personnalisation du profil avec avatar et couleur
- Suivi des statistiques et de l'historique des parties

### Système de lobby

- Création de lobbies publics ou privés
- Rejoindre un lobby via liste ou code d'accès
- Chat intégré dans les lobbies
- Gestion des joueurs (expulsion, transfert d'hôte)
- Système de statut "prêt" pour les joueurs

### Système de jeux (en cours de refactorisation)

- Architecture modulaire permettant différents types de jeux
- Persistance des sessions en cas de déconnexion
- Affichage des résultats et classements

### Quiz (premier jeu implémenté)

- Questions avec texte, images, son et vidéo
- Types de réponses variés (choix multiples, réponse libre, slider, date)
- Validation automatique ou collective des réponses
- Statistiques de réponses globales et par session

## Architecture technique

### Frontend

- Framework Flutter pour une application cross-platform (iOS, Android, Web)
- Architecture basée sur les providers pour la gestion d'état
- Composants modulaires et réutilisables

### Backend

- Firebase pour l'authentification, la base de données et le stockage
- Firestore comme base de données NoSQL en temps réel
- Firebase Storage pour les médias des questions

### Structure du projet

- Organisation par fonctionnalités et responsabilités
- Séparation claire entre modèles, vues, services et contrôleurs
- Documentation intégrée et tests

## Évolutions prévues

Le projet est actuellement en phase de refactorisation majeure pour transformer le système de quiz en un système de jeux plus générique. Cette architecture permettra d'implémenter facilement de nouveaux types de jeux tout en conservant les fonctionnalités sociales et temps réel de l'application.

## Documentation

Pour plus de détails sur la mise en œuvre technique, consultez les fichiers de documentation spécifiques :

- [Structure des fichiers](files.md)
- [Structure Firestore](firestore.md)
- [Système de lobby](lobby.md)
- [Système de chat](tchat.md)
- [Tâches à réaliser](todo.md)

## Installation et configuration

1. Cloner le dépôt
2. Installer les dépendances avec `flutter pub get`
3. Configurer Firebase selon les instructions dans `firebase.json`
4. Lancer l'application avec `flutter run`

## Contribution

Les contributions sont les bienvenues ! Veuillez consulter les tâches dans le fichier [todo.md](todo.md) pour voir les fonctionnalités et améliorations planifiées.
