/// Lobby Model
///
/// Modèle représentant un lobby de quiz
/// Contient les informations sur le lobby, ses paramètres et ses joueurs
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/models/lobby/lobby_player_model.dart';
import 'package:quizzzed/utils/color_utils.dart';

enum LobbyVisibility { public, private }

enum LobbyJoinPolicy { open, approval, inviteOnly }

enum LobbyStatus { waitingForPlayers, playing, finished, waiting }

class LobbyModel {
  final String id;
  final String name;
  final String hostId;
  final String category;
  final LobbyVisibility visibility;
  final String accessCode;
  final int maxPlayers;
  final int minPlayers;
  final bool allowLateJoin;
  final LobbyStatus status;
  final bool isInProgress;
  final String? quizId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LobbyPlayerModel> players;
  final Color? color;

  // Propriété pour faciliter l'accès au code d'accès dans les vues
  String? get code => accessCode.isNotEmpty ? accessCode : null;

  bool get isFull => players.length >= maxPlayers;
  bool get canStart =>
      players.length >= minPlayers &&
      players.where((p) => p.isReady).length >=
          (players.length - 1); // Tous sauf l'hôte

  LobbyModel({
    required this.id,
    required this.name,
    required this.hostId,
    required this.category,
    required this.visibility,
    this.accessCode = '',
    required this.maxPlayers,
    required this.minPlayers,
    this.allowLateJoin = false,
    this.status = LobbyStatus.waitingForPlayers,
    this.isInProgress = false,
    this.quizId,
    required this.createdAt,
    required this.updatedAt,
    required this.players,
    required this.color,
  });

  // Créer un nouveau lobby
  factory LobbyModel.create({
    required String hostId,
    required String name,
    String? quizId,
    LobbyVisibility visibility = LobbyVisibility.public,
    int maxPlayers = AppConfig.maxPlayersPerLobby,
    int minPlayers = AppConfig.minPlayersToStart,
    bool allowLateJoin = false,
  }) {
    return LobbyModel(
      id: '', // Sera défini après l'enregistrement dans Firestore
      name: name,
      hostId: hostId,
      category: 'Général', // Catégorie par défaut
      visibility: visibility,
      accessCode:
          visibility == LobbyVisibility.private ? _generateRandomCode() : '',
      maxPlayers: maxPlayers,
      minPlayers: minPlayers,
      allowLateJoin: allowLateJoin,
      status: LobbyStatus.waitingForPlayers,
      isInProgress: false,
      quizId: quizId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      players: [],
      color: AppConfig.defaultUserColor,
    );
  }

  // Créer à partir d'un document Firestore
  factory LobbyModel.fromMap(Map<String, dynamic> map, String id) {
    final List<dynamic> playersData = map['players'] ?? [];

    return LobbyModel(
      id: id,
      name: map['name'] ?? 'Nouveau lobby',
      hostId: map['hostId'] ?? '',
      category: map['category'] ?? 'Général',
      visibility:
          map['visibility'] == 'private'
              ? LobbyVisibility.private
              : LobbyVisibility.public,
      accessCode: map['accessCode'] ?? '',
      maxPlayers: map['maxPlayers'] ?? AppConfig.maxPlayersPerLobby,
      minPlayers: map['minPlayers'] ?? AppConfig.minPlayersToStart,
      allowLateJoin: map['allowLateJoin'] ?? false,
      status: _parseStatus(map['status']),
      isInProgress: map['isInProgress'] ?? false,
      color: ColorUtils.fromValue(map['color']) ?? AppConfig.defaultUserColor,
      quizId: map['quizId'],
      createdAt:
          map['createdAt'] != null
              ? (map['createdAt'] is Timestamp
                  ? (map['createdAt'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(map['createdAt']))
              : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null
              ? (map['updatedAt'] is Timestamp
                  ? (map['updatedAt'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(map['updatedAt']))
              : DateTime.now(),
      players:
          playersData
              .map((playerMap) => LobbyPlayerModel.fromMap(playerMap))
              .toList(),
    );
  }

  // Créer à partir d'un document Firestore
  factory LobbyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return LobbyModel.fromMap(map, doc.id);
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'hostId': hostId,
      'category': category,
      'visibility':
          visibility == LobbyVisibility.private ? 'private' : 'public',
      'accessCode': accessCode,
      'maxPlayers': maxPlayers,
      'minPlayers': minPlayers,
      'allowLateJoin': allowLateJoin,
      'status': status.toString(),
      'isInProgress': isInProgress,
      'quizId': quizId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'players': players.map((player) => player.toMap()).toList(),
      // Conversion de l'objet Color en chaîne numérique pour Firestore
      'color': ColorUtils.toStorageValue(color),
    };
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  // Vérifier si un joueur peut rejoindre ce lobby
  bool canJoin() {
    return !isFull &&
        (status == LobbyStatus.waitingForPlayers ||
            (status == LobbyStatus.playing && allowLateJoin));
  }

  // Créer une copie avec des modifications
  LobbyModel copyWith({
    String? id,
    String? name,
    String? hostId,
    String? category,
    LobbyVisibility? visibility,
    String? accessCode,
    int? maxPlayers,
    int? minPlayers,
    bool? allowLateJoin,
    LobbyStatus? status,
    bool? isInProgress,
    String? quizId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LobbyPlayerModel>? players,
    Color? color,
  }) {
    return LobbyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      hostId: hostId ?? this.hostId,
      category: category ?? this.category,
      visibility: visibility ?? this.visibility,
      accessCode: accessCode ?? this.accessCode,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minPlayers: minPlayers ?? this.minPlayers,
      allowLateJoin: allowLateJoin ?? this.allowLateJoin,
      status: status ?? this.status,
      isInProgress: isInProgress ?? this.isInProgress,
      quizId: quizId ?? this.quizId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      players: players ?? this.players,
      color: color ?? this.color,
    );
  }

  @override
  String toString() {
    return 'LobbyModel(id: $id, name: $name, category: $category, players: ${players.length}/$maxPlayers)';
  }

  // Méthode statique pour générer un code d'accès aléatoire
  static String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sans I, O, 0, 1
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    String code = '';

    for (int i = 0; i < 6; i++) {
      final index = (random.codeUnitAt(i % random.length) + i) % chars.length;
      code += chars[index];
    }

    return code;
  }

  // Analyser le statut depuis une chaîne
  static LobbyStatus _parseStatus(String? statusStr) {
    if (statusStr == LobbyStatus.playing.toString()) {
      return LobbyStatus.playing;
    } else if (statusStr == LobbyStatus.finished.toString()) {
      return LobbyStatus.finished;
    }
    return LobbyStatus.waitingForPlayers;
  }
}
