/// Modèle d'utilisateur
///
/// Classe qui représente un utilisateur de l'application
/// Utilisée pour la gestion des profils et de l'authentification
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final int score;
  final List<String> quizHistory;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isAdmin;
  final String? avatarBackgroundColor; // Couleur de fond de l'avatar

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.avatarBackgroundColor,
    this.score = 0,
    this.quizHistory = const [],
    required this.createdAt,
    required this.lastLoginAt,
    this.isAdmin = false,
  });

  /// Crée un UserModel à partir d'un Map (généralement depuis Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      avatarBackgroundColor: map['avatarBackgroundColor'],
      score: map['score'] ?? 0,
      quizHistory: List<String>.from(map['quizHistory'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp).toDate(),
      isAdmin: map['isAdmin'] ?? false,
    );
  }

  /// Convertit un UserModel en Map pour le stockage dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'avatarBackgroundColor': avatarBackgroundColor,
      'score': score,
      'quizHistory': quizHistory,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isAdmin': isAdmin,
    };
  }

  /// Crée une copie du UserModel avec des valeurs modifiées
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? avatarBackgroundColor,
    int? score,
    List<String>? quizHistory,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isAdmin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarBackgroundColor:
          avatarBackgroundColor ?? this.avatarBackgroundColor,
      score: score ?? this.score,
      quizHistory: quizHistory ?? this.quizHistory,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
