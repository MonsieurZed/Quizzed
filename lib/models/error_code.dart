/// Enumération des codes d'erreur utilisés dans l'application
///
/// Cette énumération permet de standardiser et catégoriser les erreurs
/// pour faciliter leur gestion et leur affichage cohérent à l'utilisateur.
library;

/// Codes d'erreur utilisés dans l'application
enum ErrorCode {
  // Erreurs d'authentification

  notAuthenticated('AUTH_001', 'Utilisateur non authentifié'),
  authenticationFailed('AUTH_002', 'Échec de l\'authentification'),
  notAuthorized('AUTH_003', 'Accès non autorisé'),
  invalidInput('AUTH_004', 'Entrée invalide'),
  invalidEmail('AUTH_005', 'Adresse e-mail invalide'),
  invalidPassword('AUTH_006', 'Mot de passe invalide'),
  duplicateEntry('AUTH_007', 'Entrée en double'),
  authUserDisabled('AUTH_008', 'Utilisateur désactivé'),
  authUserNotFound('AUTH_009', 'Utilisateur introuvable'),
  authWrongPassword('AUTH_010', 'Mot de passe incorrect'),
  authEmailAlreadyInUse(
    'AUTH_011',
    'L\'adresse e-mail est déjà utilisée par un autre compte',
  ),
  authWeakPassword(
    'AUTH_012',
    'Le mot de passe est trop faible. Il doit contenir au moins 6 caractères.',
  ),
  authOperationNotAllowed('AUTH_012', 'L\'opération n\'est pas autorisée'),
  authTooManyRequests(
    'AUTH_013',
    'Trop de tentatives échouées. Veuillez réessayer plus tard.',
  ),
  authUnknown(
    'AUTH_014',
    'Erreur inconnue lors de l\'authentification. Veuillez réessayer.',
  ),
  userCancelled(
    'AUTH_015',
    'L\'utilisateur a annulé l\'opération d\'authentification.',
  ),
  // Erreurs de lobby
  lobbyNotFound('LOBBY_001', 'Lobby introuvable'),
  lobbyFull('LOBBY_002', 'Le lobby est complet'),
  lobbyNameRequired('LOBBY_003', 'Nom du lobby requis'),
  lobbyInProgress('LOBBY_004', 'Le lobby est en cours de partie'),
  lobbyClosed('LOBBY_005', 'Le lobby est fermé'),
  invalidAccessCode('LOBBY_006', 'Code d\'accès invalide'),

  chatMessageEmpty('CHAT_001', 'Le message de chat est vide'),
  chatStreamConnectionFailed(
    'CHAT_002',
    'Échec de la connexion au flux de chat',
  ),
  chatStreamDisconnectFailed(
    'CHAT_003',
    'Échec de la déconnexion du flux de chat',
  ),
  chatMessageTooLong('CHAT_003', 'Le message de chat est trop long'),
  chatMessageRetrievalFailed(
    'CHAT_004',
    'Échec de la récupération des messages de chat',
  ),
  chatMessageNotFound('CHAT_005', 'Message de chat introuvable'),
  chatMessageSendFailed('CHAT_006', 'Échec de l\'envoi du message de chat'),
  chatMessagePermissionDenied(
    'CHAT_007',
    'Permission refusée pour envoyer un message de chat',
  ),
  chatMessageDeleteFailed(
    'CHAT_008',
    'Échec de la suppression du message de chat',
  ),
  chatSystemMessageSendFailed(
    'CHAT_009',
    'Échec de l\'envoi du message système de chat',
  ),
  // Erreurs de joueur
  playerNotFound('PLAYER_001', 'Joueur introuvable'),
  playerAlreadyInLobby('PLAYER_002', 'Le joueur est déjà dans un lobby'),
  playerNotInLobby('PLAYER_003', 'Le joueur n\'est pas dans ce lobby'),
  kickSelfNotAllowed(
    'PLAYER_004',
    'Vous ne pouvez pas vous expulser vous-même',
  ),

  // Erreurs de quiz
  quizNotFound('QUIZ_001', 'Quiz introuvable'),
  noQuestionsInQuiz('QUIZ_002', 'Aucune question dans ce quiz'),
  questionNotFound('QUIZ_003', 'Question introuvable'),
  answerNotFound('QUIZ_004', 'Réponse introuvable'),

  // Erreurs de jeu
  gameNotStarted('GAME_001', 'La partie n\'a pas commencé'),
  gameAlreadyStarted('GAME_002', 'La partie a déjà commencé'),
  notEnoughPlayers('GAME_003', 'Pas assez de joueurs pour démarrer la partie'),

  // Erreurs de réseau
  networkError('NET_001', 'Erreur de connexion'),
  timeoutError('NET_002', 'Délai d\'attente dépassé'),
  serverError('NET_003', 'Erreur serveur'),

  // Erreurs Firebase
  firebaseError('FB_001', 'Erreur Firebase'),
  firebasePermissionDenied('FB_002', 'Permission Firestore refusée'),
  firestoreIndexMissing(
    'FB_003',
    'Index Firestore manquant. Veuillez vérifier la console Firebase.',
  ),
  configurationMissing(
    'FB_004',
    'Configuration manquante. Veuillez vérifier la configuration de Firebase.',
  ),
  firebaseInitError(
    'FB_005',
    'Erreur d\'initialisation de Firebase. Veuillez vérifier la configuration.',
  ),

  dataParsingError('DATA_001', 'Erreur de parsing des données'),
  databaseError('DATA_002', 'Erreur de base de données'),
  storageError('DATA_003', 'Erreur de stockage'),
  // Erreurs génériques
  unknown('ERR_001', 'Erreur inconnue'),
  invalidParameter('ERR_002', 'Paramètre invalide'),
  operationFailed('ERR_003', 'L\'opération a échoué'),
  notImplemented('ERR_004', 'Fonctionnalité non implémentée');

  /// Code technique de l'erreur (pour journalisation)
  final String code;

  /// Message par défaut associé à ce code d'erreur
  final String defaultMessage;

  /// Constructeur
  const ErrorCode(this.code, this.defaultMessage);

  /// Retourne le code d'erreur sous forme de chaîne
  @override
  String toString() => code;
}
