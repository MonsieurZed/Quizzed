# Architecture des Contrôleurs de Lobby

> **IMPORTANT**: Toute modification du fonctionnement du système de lobby doit être mise à jour dans ce document.

## Vue d'ensemble

Cette documentation explique l'architecture des contrôleurs de lobby suite à la refactorisation. L'objectif principal était de séparer les responsabilités et d'améliorer la maintenabilité tout en gardant une interface cohérente pour les vues existantes.

## Hiérarchie des interfaces

La refactorisation s'est basée sur une hiérarchie d'interfaces claire:

```
ILobbyController (interface de base)
├── ILobbyManagementController (gestion des lobbies)
├── ILobbyPlayerController (gestion des joueurs)
└── ILobbyActivityController (gestion de l'activité)
```

### ILobbyController

Interface commune implémentée par tous les contrôleurs de lobby. Elle définit:

- Gestion de l'état: `isLoading`, `error`
- Manipulation du lobby courant: `currentLobby`, `setCurrentLobby()`
- Gestion des erreurs: `handleError()`, `clearErrors()`
- Opérations de base: `loadLobby()`, `joinLobbyStream()`, `leaveLobbyStream()`

### ILobbyManagementController

Interface spécialisée pour la création et la gestion des lobbies:

- Opérations CRUD: `createLobby()`, `updateLobbySettings()`, `deleteLobby()`
- Chargement des lobbies: `loadPublicLobbies()`, `userHasExistingLobby()`

### ILobbyPlayerController

Interface spécialisée pour la gestion des joueurs dans les lobbies:

- Rejoindre/quitter: `joinLobby()`, `joinPrivateLobby()`, `joinLobbyByCode()`, `leaveLobby()`
- Gestion des joueurs: `kickPlayer()`, `transferOwnership()`, `togglePlayerStatus()`
- Activité des joueurs: `updatePlayerActivity()`

### ILobbyActivityController

Interface spécialisée pour la gestion de l'activité et de l'inactivité:

- Timers: `startInactivityTimer()`, `stopInactivityTimer()`
- Vérifications: `checkInactivePlayers()`, `checkInactiveLobbies()`
- Activité: `updatePlayerActivity()`

## Hiérarchie des implémentations

L'implémentation suit une structure hiérarchique avec délégation:

```
LobbyBaseController (classe abstraite de base)
├── LobbyManagementController
├── LobbyPlayerController
├── LobbyActivityController
└── LobbyController (façade qui délègue aux 3 contrôleurs spécialisés)
```

### LobbyBaseController

Classe abstraite de base qui:

- Implémente les méthodes communes de `ILobbyController`
- Fournit des utilitaires partagés comme `verifyUserAuthenticated()` et `generateAccessCode()`
- Standardise la gestion des erreurs et de l'état de chargement

### LobbyManagementController, LobbyPlayerController, LobbyActivityController

Implémentations spécialisées qui:

- Héritent de `LobbyBaseController` pour les fonctionnalités partagées
- Implémentent leurs interfaces respectives
- Se concentrent sur un seul aspect de la gestion des lobbies

### LobbyController

Façade qui:

- Présente une interface unifiée pour les vues existantes
- Délègue les opérations aux contrôleurs spécialisés
- Synchronise l'état entre les différents contrôleurs
- Garantit la compatibilité avec le code client existant

## Pattern de conception appliqués

1. **Façade**: Le `LobbyController` agit comme une façade pour simplifier l'usage des contrôleurs spécialisés.
2. **Délégation**: Les opérations sont déléguées aux contrôleurs spécialisés appropriés.
3. **Interface-Implémentation**: Séparation claire entre l'interface (contrat) et l'implémentation.
4. **Héritage**: Les contrôleurs partagent du code commun via le `LobbyBaseController`.

## Avantages de l'architecture

1. **Séparation des responsabilités**: Chaque contrôleur a un rôle bien défini.
2. **Testabilité**: Les contrôleurs peuvent être testés individuellement.
3. **Extensibilité**: De nouvelles fonctionnalités peuvent être ajoutées sans modifier l'existant.
4. **Maintenabilité**: Les fichiers sont plus courts et plus ciblés.
5. **Compatibilité**: L'ancien code client continue de fonctionner via la façade.

## Utilisation

### Pour le code client existant

Continuez à utiliser `LobbyController` comme avant:

```dart
final lobbyController = LobbyController(
  firebaseService: injector<FirebaseService>(),
  authService: injector<AuthService>(),
);

// Utilisation pour créer un lobby
final lobbyId = await lobbyController.createLobby(
  name: 'Mon lobby',
  description: 'Description du lobby',
  maxPlayers: 10,
  visibility: LobbyVisibility.public,
  joinPolicy: LobbyJoinPolicy.open,
);
```

### Pour le nouveau code

Vous pouvez injecter directement les contrôleurs spécialisés si nécessaire:

```dart
final managementController = LobbyManagementController(
  firebaseService: injector<FirebaseService>(),
  authService: injector<AuthService>(),
);

// Utilisation directe
final publicLobbies = await managementController.fetchPublicLobbies();
```

## Bonnes pratiques

1. Préférez injecter `LobbyController` pour le code client général.
2. Injectez les contrôleurs spécialisés seulement si leur fonction spécifique est nécessaire.
3. Conservez la séparation des responsabilités lors des évolutions futures.
