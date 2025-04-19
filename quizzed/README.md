# Quizzed

Une plateforme de quiz multijoueur pour une LAN entre amis.

## Description du projet

Quizzed est une application Flutter Web qui permet d'organiser des sessions de quiz interactifs pendant des LAN parties entre amis:

- **Interface visuelle**: Thème vert fluo (#39FF14) sur fond noir
- **Rôles**: Un MJ (admin) gère les questions, les joueurs participent de façon anonyme avec un pseudo
- **Fonctionnement**: Un lobby unique pouvant accueillir plusieurs sessions de quiz

### Types de quiz supportés

- QCM
- Image
- Son
- Vidéo
- Réponse libre (type Petit Bac) avec validation communautaire

## Technologies utilisées

- **Frontend**: Flutter Web
- **Backend**: Firebase
  - Authentication: Pour le compte admin
  - Firestore/Realtime Database: Pour les données des quiz et sessions
  - Storage: Pour les médias (images, sons, vidéos)
  - Hosting: Pour le déploiement

## Fonctionnalités prévues

### Pour le MJ (admin)

- Interface d'administration sécurisée
- Création et gestion des quiz avec médias
- Lancement de sessions multiples
- Contrôle du pourcentage de validation des réponses libres

### Pour les joueurs

- Connexion avec pseudo simple
- Personnalisation (avatar, couleur)
- Interface de réponse aux questions avec timer
- Système de vote pour la validation des réponses libres
- Affichage des scores en temps réel

## Statut du développement

Le projet est actuellement en cours de développement. Consultez le fichier ia.md pour suivre la progression détaillée.

## Pour commencer

Ce projet utilise Flutter. Pour exécuter l'application:

```
flutter pub get
flutter run -d chrome
```

Pour plus d'informations sur Flutter, consultez la [documentation officielle](https://docs.flutter.dev/).
