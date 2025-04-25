# Journal d'activité - Développement du système de jeux

<!--

# NE PAS SUPPRIMER CE HEADER - DOCUMENTATION DU PROJET QUIZZED

## Liste des fichiers de documentation MD et leur utilité

- **files.md** : Contient l'arborescence complète du projet avec une description de chaque fichier et ses fonctions
- **firestore.md** : Documentation de la structure de base de données Firebase/Firestore
- **information.md** : Spécifications détaillées du système de jeux (architecture, types de jeux, fonctionnalités)
- **lobby.md** : Documentation du système de lobby (création, gestion, interactions)
- **memory.md** : Ce fichier - Journal d'activité chronologique pour suivre la progression du développement
- **process.md** : Description du processus de développement et documentation à suivre pour ce projet
- **readme.md** : Vue d'ensemble du projet Quizzed et informations générales
- **tchat.md** : Documentation du système de chat intégré aux lobbies
- **todo.md** : Checklist détaillée des tâches à réaliser, organisée par phase

## Comment utiliser ce journal

Ce journal chronologique permet de suivre l'évolution du projet et facilite la reprise du travail en cas d'interruption.
Pour chaque étape de travail, ajoutez une entrée avec la date et l'heure et décrivez les actions réalisées, les décisions prises et les problèmes rencontrés.

## En cas de crash ou d'interruption

Si vous reprenez le travail après un crash ou une interruption, suivez ces étapes :

1. **Consultez ce journal (memory.md)** d'abord pour voir où l'agent précédent s'est arrêté
2. **Vérifiez todo.md** pour identifier les tâches déjà accomplies (cochées) et celles qui restent à faire
3. **Lisez information.md** pour comprendre les spécifications du système de jeux à implémenter
4. **Consultez process.md** pour rappel du processus de développement à suivre
5. **Examinez files.md** pour comprendre l'architecture actuelle du projet
6. Reprenez le travail à la dernière tâche non terminée dans todo.md

N'oubliez pas de mettre à jour ce journal avec vos propres actions pour maintenir la continuité.

======================================================================================
-->

## 2024-04-25

### Phase d'initialisation

- Mise en place du processus de développement et documentation dans `process.md`
- Création du document `information.md` détaillant les spécifications du système de jeux
- Création de ce journal d'activité pour suivre la progression
- Mise à jour de `todo.md` avec les étapes détaillées pour la refactorisation
- Ajout d'un header explicatif dans `memory.md` pour documenter les fichiers MD existants et leur utilité

### Début de la résolution des fonctionnalités dupliquées

- Décision de commencer par la résolution des fonctionnalités dupliquées avant la refactorisation complète du système de quiz
- Analyse des duplications à aborder en priorité
- Plan d'action : commencer par les contrôleurs de lobby et leurs fonctions dupliquées

### Analyse des duplications dans les contrôleurs de lobby

- Examen des fichiers `lobby_operation_helper.dart`, `lobby_management_controller.dart` et `lobby_player_controller.dart`
- Identification des principales fonctions dupliquées :
  1. `fetchLobbyById` présente dans helper et contrôleurs
  2. Vérifications de type `verifyUserIsHost` et `verifyPlayerInLobby` dupliquées
  3. Gestion des joueurs (ajout/suppression) implémentée de multiples façons
  4. Stream management dupliqué entre les contrôleurs

### Plan de refactorisation pour résoudre les duplications

1. **Phase 1**: Renforcer le rôle de `LobbyOperationHelper`

   - S'assurer que tous les contrôleurs utilisent l'helper via une composition explicite
   - Déplacer toutes les fonctions utilitaires communes vers l'helper
   - Standardiser les signatures de méthodes et les types de retour

2. **Phase 2**: Consolider les fonctions de streaming de lobby

   - Créer une fonction de streaming unifiée dans l'helper
   - Simplifier les implémentations dans les contrôleurs pour réutiliser cette fonction

3. **Phase 3**: Améliorer la gestion des joueurs

   - Centraliser la logique d'ajout/suppression/modification des joueurs
   - Utiliser des transactions Firestore pour éviter les conflits d'écriture

4. **Phase 4**: Nettoyer les contrôleurs
   - Supprimer le code dupliqué dans les contrôleurs
   - Mettre à jour les contrôleurs pour utiliser l'helper de manière cohérente
   - Ajouter des tests pour vérifier le bon fonctionnement
