/// Chat Message Model
///
/// Modèle de données pour représenter un message dans le tchat
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Type de canal de chat
enum ChatChannel {
  /// Canal général accessible à tous les utilisateurs
  general,

  /// Canal spécifique à un lobby
  lobby,
}

/// Extension pour convertir l'enum en string et vice-versa
extension ChatChannelExtension on ChatChannel {
  /// Convertir l'enum en string pour Firestore
  String get name {
    switch (this) {
      case ChatChannel.general:
        return 'general';
      case ChatChannel.lobby:
        return 'lobby';
    }
  }

  /// Convertir une string en enum depuis Firestore
  static ChatChannel fromString(String value) {
    switch (value) {
      case 'general':
        return ChatChannel.general;
      case 'lobby':
        return ChatChannel.lobby;
      default:
        return ChatChannel.general;
    }
  }
}

/// Classe représentant un message dans le tchat
class ChatMessageModel {
  /// Identifiant unique du message
  final String id;

  /// Identifiant du lobby auquel appartient ce message
  final String lobbyId;

  /// Canal de chat (général ou lobby)
  final ChatChannel channel;

  /// Identifiant de l'utilisateur qui a envoyé le message
  final String userId;

  /// Nom d'affichage de l'utilisateur qui a envoyé le message
  final String userName;

  /// URL de l'avatar de l'utilisateur qui a envoyé le message
  final String? avatar;

  /// Nom de la couleur du profil de l'utilisateur
  final String? color;

  /// Contenu textuel du message
  final String text;

  /// Horodatage de l'envoi du message
  final DateTime timestamp;

  /// Constructeur
  ChatMessageModel({
    required this.id,
    required this.lobbyId,
    this.channel = ChatChannel.lobby,
    required this.userId,
    required this.userName,
    this.avatar,
    this.color,
    required this.text,
    required this.timestamp,
  });

  /// Crée un modèle à partir des données Firestore
  factory ChatMessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    return ChatMessageModel(
      id: snapshot.id,
      lobbyId: data['lobbyId'] as String,
      channel:
          data['channel'] != null
              ? ChatChannelExtension.fromString(data['channel'] as String)
              : ChatChannel
                  .lobby, // Par défaut pour la compatibilité avec les anciens messages
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      avatar: data['avatar'] as String?,
      color: data['color'] as String?,
      text: data['text'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  /// Convertit le modèle en données pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'lobbyId': lobbyId,
      'channel': channel.name,
      'userId': userId,
      'userName': userName,
      if (avatar != null) 'userAvatarUrl': avatar,
      if (color != null) 'userColorName': color,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
