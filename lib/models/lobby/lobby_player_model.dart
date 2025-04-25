import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizzzed/models/user/user_model.dart';
import 'package:quizzzed/utils/color_utils.dart';

class LobbyPlayerModel {
  final String userId;
  final String displayName;
  final String avatar;
  final Color? color;
  final bool isHost;
  final bool isReady;
  final DateTime joinedAt;
  final DateTime? lastActive;

  LobbyPlayerModel({
    required this.userId,
    required this.displayName,
    required this.avatar,
    this.color, // Couleur de fond optionnelle
    required this.isHost,
    required this.isReady,
    required this.joinedAt,
    this.lastActive,
  });

  factory LobbyPlayerModel.fromUser(UserModel user, {bool isHost = false}) {
    return LobbyPlayerModel(
      userId: user.uid,
      displayName: user.displayName!,
      avatar: user.avatar!,
      color:
          user.color, // Récupération de la couleur depuis le modèle utilisateur
      isHost: isHost,
      isReady: isHost, // L'hôte est automatiquement prêt
      joinedAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
  }

  factory LobbyPlayerModel.fromMap(Map<String, dynamic> data) {
    return LobbyPlayerModel(
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      avatar: data['avatarUrl'] ?? '',
      color: ColorUtils.fromValue(data['color']),
      isHost: data['isHost'] ?? false,
      isReady: data['isReady'] ?? false,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      lastActive:
          data['lastActive'] != null
              ? (data['lastActive'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatar,
      'color': ColorUtils.toStorageValue(color), // Utiliser ColorUtils
      'isHost': isHost,
      'isReady': isReady,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
    };
  }

  LobbyPlayerModel copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    Color? userColor, // Couleur au copyWith
    bool? isHost,
    bool? isReady,
    DateTime? joinedAt,
    DateTime? lastActive,
  }) {
    return LobbyPlayerModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatar: avatarUrl ?? this.avatar,
      color: userColor ?? this.color,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
