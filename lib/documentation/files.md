# Documentation des fichiers du projet Quizzed

**IMPORTANT**: Toute modification ou ajout de fichiers doit être répertorié dans ce document.

## Structure générale

Le projet Quizzed est organisé selon l'architecture suivante:

```
lib/
  ├── main.dart              # Point d'entrée de l'application
  ├── private_key.dart       # Clés privées (ne pas committer)
  ├── config/                # Configurations globales
  ├── controllers/           # Logique métier (contrôleurs)
  ├── documentation/         # Documentation interne du projet
  ├── examples/              # Exemples de code
  ├── models/                # Modèles de données
  ├── routes/                # Configuration des routes
  ├── services/              # Services (accès aux données, auth, etc.)
  ├── theme/                 # Gestion des thèmes
  ├── utils/                 # Utilitaires génériques
  ├── views/                 # Interfaces utilisateur
  └── widgets/               # Composants réutilisables
```

## Fichiers principaux

### Configuration

- `lib/config/app_config.dart` - Constantes et paramètres globaux

### Contrôleurs

- `lib/controllers/lobby/...` - Contrôleurs pour la gestion des lobbies
- (Continuer de documenter les autres contrôleurs...)

### Documentation

- `lib/documentation/tchat.md` - Documentation du système de chat
- `lib/documentation/lobby.md` - Documentation du système de lobby
- `lib/documentation/files.md` - Ce fichier (liste des fichiers)
- `lib/documentation/firestore.md` - Documentation de la structure Firebase

### Modèles

- `lib/models/error_code.dart` - Codes d'erreur standardisés
- `lib/models/chat/...` - Modèles liés au chat
- `lib/models/lobby/...` - Modèles liés aux lobbies
- `lib/models/user/...` - Modèles liés aux utilisateurs
- `lib/models/quiz/...` - Modèles liés aux quiz

### Services

- `lib/services/auth_service.dart` - Service d'authentification
- `lib/services/avatar_service.dart` - Service de gestion des avatars
- `lib/services/chat_service.dart` - Service de gestion du chat
- `lib/services/firebase_service.dart` - Service d'accès à Firebase
- `lib/services/logger_service.dart` - Service de journalisation
- `lib/services/validation_service.dart` - Service de validation des données

(Ajouter d'autres fichiers au fur et à mesure de la documentation complète du projet...)
