/// Modèle d'utilisateur
///
/// Classe qui représente un utilisateur de l'application
/// Utilisée pour la gestion des profils et de l'authentification
library;

import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizzzed/utils/color_utils.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? avatar;
  final Color? color;
  final int score;
  final List<String> quizHistory;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isAdmin;
  final String? currentLobbyId; // ID du lobby actuel de l'utilisateur
  final bool isDarkMode; // Préférence de thème de l'utilisateur

  /// Getter pour l'ID de l'utilisateur (alias pour uid)
  String get id => uid;
  String? get colorString => ColorUtils.toStorageValue(color);

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.avatar,
    this.color,
    this.score = 0,
    this.quizHistory = const [],
    required this.createdAt,
    required this.lastLoginAt,
    this.isAdmin = false,
    this.currentLobbyId,
    this.isDarkMode = false,
  });

  /// Crée un UserModel à partir d'un Map (généralement depuis Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      avatar: map['avatar'],
      color: ColorUtils.fromValue(map['color']),
      score: map['score'] ?? 0,
      quizHistory: List<String>.from(map['quizHistory'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp).toDate(),
      isAdmin: map['isAdmin'] ?? false,
      currentLobbyId: map['currentLobbyId'],
      isDarkMode: map['isDarkMode'] ?? false,
    );
  }

  /// Convertit un UserModel en Map pour le stockage dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatar': avatar,
      'color': ColorUtils.toStorageValue(color),
      'score': score,
      'quizHistory': quizHistory,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isAdmin': isAdmin,
      'currentLobbyId': currentLobbyId,
      'isDarkMode': isDarkMode,
    };
  }

  /// Crée une copie du UserModel avec des valeurs modifiées
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? userColor,
    int? score,
    List<String>? quizHistory,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isAdmin,
    String? currentLobbyId,
    String? avatar,
    Color? color,
    bool? isDarkMode,
  }) {
    Color? finalColor = color;

    // Conversion de userColor (chaîne) en Color si nécessaire
    if (userColor != null) {
      finalColor = ColorUtils.fromValue(userColor);
    }

    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? photoUrl ?? this.avatar,
      color: finalColor ?? this.color,
      score: score ?? this.score,
      quizHistory: quizHistory ?? this.quizHistory,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isAdmin: isAdmin ?? this.isAdmin,
      currentLobbyId: currentLobbyId ?? this.currentLobbyId,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}
