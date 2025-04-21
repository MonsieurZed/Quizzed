/// Lobby Player Model
///
/// Modèle représentant un joueur dans un lobby de quiz
/// Contient les informations sur le joueur et son statut

import 'package:flutter/material.dart';

enum LobbyPlayerStatus { waiting, ready }

class LobbyPlayerModel {
  final String id;
  final String displayName;
  final String photoUrl;
  final Color? avatarBackgroundColor;
  final LobbyPlayerStatus status;

  LobbyPlayerModel({
    required this.id,
    required this.displayName,
    required this.photoUrl,
    this.avatarBackgroundColor,
    this.status = LobbyPlayerStatus.waiting,
  });

  // Créer à partir d'un document Firestore
  factory LobbyPlayerModel.fromMap(Map<String, dynamic> map) {
    return LobbyPlayerModel(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? 'Joueur',
      photoUrl: map['photoUrl'] ?? '',
      avatarBackgroundColor:
          map['avatarBackgroundColor'] != null
              ? Color(map['avatarBackgroundColor'])
              : null,
      status:
          map['status'] == 'ready'
              ? LobbyPlayerStatus.ready
              : LobbyPlayerStatus.waiting,
    );
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'avatarBackgroundColor':
          avatarBackgroundColor != null ? avatarBackgroundColor!.value : null,
      'status': status == LobbyPlayerStatus.ready ? 'ready' : 'waiting',
    };
  }

  // Créer une copie avec des modifications
  LobbyPlayerModel copyWith({
    String? id,
    String? displayName,
    String? photoUrl,
    Color? avatarBackgroundColor,
    LobbyPlayerStatus? status,
  }) {
    return LobbyPlayerModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarBackgroundColor:
          avatarBackgroundColor ?? this.avatarBackgroundColor,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'LobbyPlayerModel(id: $id, displayName: $displayName, status: $status)';
  }
}
