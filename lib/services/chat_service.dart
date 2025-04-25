/// Chat Service
///
/// Service gérant les fonctionnalités de tchat pour les lobbies
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizzzed/models/chat/chat_message_model.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/services/error_message_service.dart';
import 'package:quizzzed/services/logger_service.dart';

/// Classe fournissant des services pour les fonctionnalités de tchat
class ChatService {
  /// Instance de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Logger pour le service
  final LoggerService _logger = LoggerService();

  /// Service de messages d'erreur
  final ErrorMessageService _errorMessageService = ErrorMessageService();

  /// Tag pour les logs
  final String _logtag = 'ChatService';

  /// Collection des messages de tchat
  final CollectionReference _messagesCollection;

  /// Stream contenant les messages du lobby
  Stream<List<ChatMessageModel>>? _lobbyMessagesStream;

  /// Stream contenant les messages généraux
  Stream<List<ChatMessageModel>>? _generalMessagesStream;

  /// Dernier envoi de message (pour limiter la fréquence)
  DateTime _lastMessageSent = DateTime.now().subtract(
    const Duration(seconds: 2),
  );

  /// Getter pour accéder au stream de messages du lobby
  Stream<List<ChatMessageModel>>? get lobbyMessagesStream =>
      _lobbyMessagesStream;

  /// Getter pour accéder au stream de messages généraux
  Stream<List<ChatMessageModel>>? get generalMessagesStream =>
      _generalMessagesStream;

  /// Constructeur
  ChatService()
    : _messagesCollection = FirebaseFirestore.instance.collection(
        'chat_messages',
      );

  /// Rejoint un stream de chat pour un lobby spécifique
  Future<void> joinChatStreams(String lobbyId) async {
    try {
      // Initialiser les deux streams en même temps
      _lobbyMessagesStream = getMessagesForLobby(lobbyId, ChatChannel.lobby);
      _generalMessagesStream = getMessagesForLobby(
        'general',
        ChatChannel.general,
      );

      _logger.info(
        'Rejoint les streams de chat pour le lobby: $lobbyId et le canal général',
        tag: _logtag,
      );
    } catch (e, stackTrace) {
      final errorCode = ErrorCode.chatStreamConnectionFailed;
      final errorMessage =
          'Erreur lors de la connexion aux streams de chat: $e';
      _logger.error(errorMessage, stackTrace: stackTrace, tag: _logtag);
      _errorMessageService.handleError(
        errorCode: errorCode,
        operation: errorMessage,
        error: e,
        stackTrace: stackTrace,
        tag: _logtag,
      );
      throw errorCode;
    }
  }

  /// Quitte le stream de chat d'un lobby spécifique
  Future<void> leaveChatStreams() async {
    try {
      // Réinitialiser les streams
      _lobbyMessagesStream = null;
      _generalMessagesStream = null;

      _logger.info('Quitté les streams de chat pour le lobby', tag: _logtag);
    } catch (e, stackTrace) {
      final errorCode = ErrorCode.chatStreamDisconnectFailed;
      final errorMessage =
          'Erreur lors de la déconnexion des streams de chat: $e';
      _logger.error(errorMessage, stackTrace: stackTrace, tag: _logtag);
      _errorMessageService.handleError(
        errorCode: errorCode,
        operation: errorMessage,
        error: e,
        stackTrace: stackTrace,
        tag: _logtag,
      );
      throw errorCode;
    }
  }

  /// Récupère les messages d'un lobby spécifique ou du canal général
  Stream<List<ChatMessageModel>> getMessagesForLobby(
    String lobbyId,
    ChatChannel channel,
  ) {
    try {
      return _messagesCollection
          .where('lobbyId', isEqualTo: lobbyId)
          .where('channel', isEqualTo: channel.name)
          .orderBy('timestamp', descending: false)
          .limit(100) // Limite pour des raisons de performance
          .withConverter(
            fromFirestore:
                (snapshot, options) =>
                    ChatMessageModel.fromFirestore(snapshot, options),
            toFirestore: (ChatMessageModel msg, _) => msg.toFirestore(),
          )
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
          .handleError((error, stackTrace) {
            // Capture spécifiquement les erreurs d'index manquant
            if (error is FirebaseException &&
                error.code == 'failed-precondition') {
              // Erreur typique d'index manquant dans Firestore
              final errorMessage = error.message ?? '';
              final errorCode = ErrorCode.firestoreIndexMissing;
              _logger.critical(
                'ERREUR D\'INDEX MANQUANT: $errorMessage',
                tag: _logtag,
                data: error,
                stackTrace: stackTrace,
              );

              // Extraire l'URL de création d'index de l'erreur
              final urlRegExp = RegExp(
                r'https:\/\/console\.firebase\.google\.com\/[^\s]+',
              );
              final match = urlRegExp.firstMatch(errorMessage);
              if (match != null) {
                final indexUrl = match.group(0);
                _logger.critical(
                  'URL POUR CRÉER L\'INDEX MANQUANT: $indexUrl',
                  tag: _logtag,
                );
              }

              final throwingError = _errorMessageService.handleError(
                errorCode: errorCode,
                operation:
                    'Erreur d\'index manquant dans Firestore: $errorMessage',
                error: error,
                stackTrace: stackTrace,
                tag: _logtag,
              );
              throw throwingError;
            } else {
              final errorCode = ErrorCode.chatMessageRetrievalFailed;
              final errorMessage =
                  'Erreur lors de la récupération des messages: $error';
              _logger.error(errorMessage, stackTrace: stackTrace, tag: _logtag);
              final throwingError = _errorMessageService.handleError(
                errorCode: errorCode,
                operation: errorMessage,
                error: error,
                stackTrace: stackTrace,
                tag: _logtag,
              );
              throw throwingError;
            }
          });
    } catch (e, stackTrace) {
      final errorCode = ErrorCode.chatMessageRetrievalFailed;
      final errorMessage = 'Erreur lors de la récupération des messages: $e';
      _logger.error(errorMessage, stackTrace: stackTrace, tag: _logtag);
      _errorMessageService.handleError(
        errorCode: errorCode,
        operation: errorMessage,
        error: e,
        stackTrace: stackTrace,
        tag: _logtag,
      );
      throw errorCode;
    }
  }

  /// Vérifie si l'utilisateur peut envoyer un message (anti-spam)
  bool canSendMessage() {
    final now = DateTime.now();
    final difference = now.difference(_lastMessageSent).inMilliseconds;
    return difference > 1000; // 1 seconde minimum entre les messages
  }

  /// Envoie un nouveau message dans le chat
  Future<void> sendMessage({
    required String lobbyId,
    required String message,
    required String senderName,
    required String senderId,
    String? senderAvatar,
    required String senderColor,
    required ChatChannel channel,
  }) async {
    try {
      if (message.trim().isEmpty) {
        final errorCode = ErrorCode.chatMessageEmpty;
        final throwingError = _errorMessageService.handleError(
          errorCode: errorCode,
          operation: 'Le message ne peut pas être vide',
          tag: _logtag,
        );
        throw throwingError;
      }

      final newMessage = ChatMessageModel(
        id: '', // Sera généré par Firestore
        lobbyId: lobbyId,
        userId: senderId,
        userName: senderName,
        avatar: senderAvatar,
        color: senderColor,
        text: message.trim(),
        timestamp: DateTime.now(),
        channel: channel,
      );

      final docRef = await _messagesCollection.add(newMessage.toFirestore());

      _logger.info(
        'Message envoyé avec succès: ${docRef.id}',
        tag: _logtag,
        data: {
          'messageId': docRef.id,
          'lobbyId': lobbyId,
          'channel': channel.name,
        },
      );
    } catch (e, stackTrace) {
      final errorCode = ErrorCode.chatMessageSendFailed;
      final errorMessage = 'Erreur lors de l\'envoi du operation:  $e';
      _logger.error(
        errorMessage,
        stackTrace: stackTrace,
        tag: _logtag,
        data: {
          'lobbyId': lobbyId,
          'senderId': senderId,
          'channel': channel.name,
        },
      );
      _errorMessageService.handleError(
        errorCode: errorCode,
        operation: errorMessage,
        error: e,
        stackTrace: stackTrace,
        tag: _logtag,
      );
      throw errorCode;
    }
  }

  /// Supprime un message du chat
  Future<void> deleteMessage({
    required String messageId,
    required String lobbyId,
    required String userId,
    bool isAdmin = false,
  }) async {
    try {
      final messageDoc = await _messagesCollection.doc(messageId).get();

      if (!messageDoc.exists) {
        final errorCode = ErrorCode.chatMessageNotFound;
        final throwingError = _errorMessageService.handleError(
          errorCode: errorCode,
          operation: 'Message introuvable: $messageId',
          tag: _logtag,
        );
        throw throwingError;
      }

      // Convert messageDoc to the correct type and call fromFirestore with both required parameters
      final message = ChatMessageModel.fromFirestore(
        messageDoc as DocumentSnapshot<Map<String, dynamic>>,
        null,
      );

      // Vérification des permissions
      if (message.userId != userId && !isAdmin) {
        final errorCode = ErrorCode.chatMessagePermissionDenied;
        final throwingError = _errorMessageService.handleError(
          errorCode: errorCode,
          operation:
              'Permission refusée pour supprimer un message d\'un autre utilisateur',
          customMessage:
              "{'messageId': $messageId,'message': $message,'lobbyId': $lobbyId,'userId': $userId,'channel': ${message.channel.name},'timestamp': ${message.timestamp.toIso8601String()}",
          tag: _logtag,
        );
        throw throwingError;
      }

      await _messagesCollection.doc(messageId).delete();

      _logger.info(
        'Message supprimé avec succès: $messageId',
        tag: _logtag,
        data: {'messageId': messageId, 'lobbyId': lobbyId, 'userId': userId},
      );
    } catch (e, stackTrace) {
      final errorCode = ErrorCode.chatMessageDeleteFailed;
      final errorMessage = 'Erreur lors de la suppression du operation:  $e';
      _logger.error(
        errorMessage,
        stackTrace: stackTrace,
        tag: _logtag,
        data: {'messageId': messageId, 'lobbyId': lobbyId, 'userId': userId},
      );
      _errorMessageService.handleError(
        errorCode: errorCode,
        operation: errorMessage,
        error: e,
        stackTrace: stackTrace,
        tag: _logtag,
      );
      throw errorCode;
    }
  }

  /// Supprime tous les messages d'un lobby (par exemple lors de la suppression du lobby)
  Future<void> deleteAllMessagesInLobby(String lobbyId) async {
    try {
      final batch = _firestore.batch();
      final messages =
          await _messagesCollection.where('lobbyId', isEqualTo: lobbyId).get();

      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _logger.info(
        'Tous les messages du lobby ont été supprimés',
        tag: _logtag,
        data: {'lobbyId': lobbyId, 'messageCount': messages.docs.length},
      );
    } catch (e, stackTrace) {
      final errorCode = ErrorCode.chatMessageDeleteFailed;
      ;
      final errorMessage =
          'Erreur lors de la suppression des messages du lobby: $e';
      _logger.error(
        errorMessage,
        stackTrace: stackTrace,
        tag: _logtag,
        data: {'lobbyId': lobbyId},
      );
      _errorMessageService.handleError(
        errorCode: errorCode,
        operation: errorMessage,
        error: e,
        stackTrace: stackTrace,
        tag: _logtag,
      );
      throw errorCode;
    }
  }

  /// Envoie un message système dans un canal spécifique
  Future<void> sendSystemMessage({
    required String lobbyId,
    required String text,
    ChatChannel channel = ChatChannel.lobby,
  }) async {
    try {
      final message = ChatMessageModel(
        id: '',
        lobbyId: channel == ChatChannel.general ? 'general' : lobbyId,
        userId: 'system', // Corrected from senderId to userId
        userName: 'Système', // Corrected from senderName to userName
        text: text, // Corrected from message to text
        timestamp: DateTime.now(),
        channel: channel,
        color:
            '#FF0000', // Added required color parameter with system red color
      );

      await _messagesCollection.add(message.toFirestore());
      _logger.info(
        'Message système envoyé avec succès',
        tag: _logtag,
        data: {'lobbyId': lobbyId, 'channel': channel.name},
      );
    } catch (e, stackTrace) {
      final errorCode = ErrorCode.chatSystemMessageSendFailed;
      final errorMessage = 'Erreur lors de l\'envoi du message système: $e';
      _logger.error(
        errorMessage,
        stackTrace: stackTrace,
        tag: _logtag,
        data: {'lobbyId': lobbyId, 'channel': channel.name},
      );
      _errorMessageService.handleError(
        errorCode: errorCode,
        operation: errorMessage,
        error: e,
        stackTrace: stackTrace,
        tag: _logtag,
      );
      throw errorCode;
    }
  }

  /// Récupère les messages d'un lobby spécifique
  Future<List<ChatMessageModel>> getLobbyMessages(String lobbyId) async {
    try {
      final snapshot =
          await _messagesCollection
              .where('lobbyId', isEqualTo: lobbyId)
              .where('channel', isEqualTo: ChatChannel.lobby.name)
              .orderBy('timestamp', descending: false)
              .limit(100) // Limite pour des raisons de performance
              .withConverter(
                fromFirestore: ChatMessageModel.fromFirestore,
                toFirestore: (ChatMessageModel msg, _) => msg.toFirestore(),
              )
              .get();

      _logger.info(
        'Récupéré ${snapshot.docs.length} messages pour le lobby: $lobbyId',
        tag: _logtag,
      );

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e, stackTrace) {
      final errorCode = ErrorCode.chatMessageRetrievalFailed;
      final errorMessage =
          'Erreur lors de la récupération des messages du lobby: $e';
      _logger.error(
        errorMessage,
        stackTrace: stackTrace,
        tag: _logtag,
        data: {'lobbyId': lobbyId},
      );
      _errorMessageService.handleError(
        errorCode: errorCode,
        operation: errorMessage,
        error: e,
        stackTrace: stackTrace,
        tag: _logtag,
      );
      // En cas d'erreur, retourner une liste vide plutôt que de propager l'exception
      // Cette approche permet à l'UI de continuer à fonctionner même en cas d'erreur
      return [];
    }
  }

  /// Récupère un stream de messages pour un lobby spécifique
  Stream<List<ChatMessageModel>> getLobbyMessagesStream(String lobbyId) {
    return getMessagesForLobby(lobbyId, ChatChannel.lobby);
  }

  /// Envoie un message système dans un lobby spécifique
  Future<void> sendLobbySystemMessage({
    required String lobbyId,
    required String content,
  }) async {
    await sendSystemMessage(
      lobbyId: lobbyId,
      text: content,
      channel: ChatChannel.lobby,
    );
  }
}
