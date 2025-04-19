import 'package:cloud_firestore/cloud_firestore.dart';

class Player {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final String? colorHex;
  final int score;
  final String? currentSessionId;
  final List<String>? sessionHistory;
  final Map<String, dynamic>? answers; // questionId: answerValue

  Player({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    this.colorHex = '#39FF14', // Default green
    this.score = 0,
    this.currentSessionId,
    this.sessionHistory,
    this.answers,
  });

  // Convert a Firestore document to a Player object
  factory Player.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Player(
      id: doc.id,
      nickname: data['nickname'] ?? 'Anonymous',
      avatarUrl: data['avatarUrl'],
      colorHex: data['colorHex'] ?? '#39FF14',
      score: data['score'] ?? 0,
      currentSessionId: data['currentSessionId'],
      sessionHistory:
          data['sessionHistory'] != null
              ? List<String>.from(data['sessionHistory'])
              : null,
      answers: data['answers'],
    );
  }

  // Convert a Player object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'colorHex': colorHex,
      'score': score,
      'currentSessionId': currentSessionId,
      'sessionHistory': sessionHistory,
      'answers': answers,
      'lastActive': FieldValue.serverTimestamp(),
    };
  }

  // Create a copy of this player with updated fields
  Player copyWith({
    String? nickname,
    String? avatarUrl,
    String? colorHex,
    int? score,
    String? currentSessionId,
    List<String>? sessionHistory,
    Map<String, dynamic>? answers,
  }) {
    return Player(
      id: this.id,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      colorHex: colorHex ?? this.colorHex,
      score: score ?? this.score,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      answers: answers ?? this.answers,
    );
  }
}
