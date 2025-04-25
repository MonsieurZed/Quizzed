/// Service de validation centralisé
///
/// Ce service fournit des méthodes standardisées pour valider les données
/// à travers toute l'application. Il utilise le pattern singleton pour assurer
/// une validation cohérente.
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/models/error_code.dart';

/// Service pour la validation des données utilisateur et des formulaires
class ValidationService {
  /// Instance singleton
  static final ValidationService _instance = ValidationService._internal();

  /// Constructeur factory pour implémenter le pattern singleton
  factory ValidationService() {
    return _instance;
  }

  /// Constructeur privé pour le singleton
  ValidationService._internal();

  // ===== VALIDATION DES UTILISATEURS =====

  /// Valide un nom d'utilisateur
  ///
  /// Règles:
  /// - Au moins 3 caractères
  /// - Pas plus de 20 caractères
  /// - Uniquement lettres, chiffres, tirets et underscores
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom d\'utilisateur est requis';
    }

    if (value.length < 3) {
      return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
    }

    if (value.length > 20) {
      return 'Le nom d\'utilisateur ne doit pas dépasser 20 caractères';
    }

    // Autoriser uniquement lettres, chiffres, tirets et underscores
    final RegExp regex = RegExp(r'^[a-zA-Z0-9_\-]+$');
    if (!regex.hasMatch(value)) {
      return 'Le nom d\'utilisateur ne peut contenir que des lettres, chiffres, tirets ou underscores';
    }

    return null; // Validation réussie
  }

  /// Valide une adresse email
  ///
  /// Vérifie le format basique d'un email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'adresse email est requise';
    }

    // Validation de base pour le format email
    final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer une adresse email valide';
    }

    return null; // Validation réussie
  }

  /// Valide un mot de passe
  ///
  /// Règles:
  /// - Au moins 6 caractères
  /// - Optionnellement: vérifier la présence de chiffres, majuscules, etc.
  static String? validatePassword(String? value, {bool isStrict = false}) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }

    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }

    // Validation plus stricte optionnelle
    if (isStrict) {
      bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
      bool hasDigits = value.contains(RegExp(r'[0-9]'));
      bool hasSpecialChars = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      if (!hasUppercase || !hasDigits || !hasSpecialChars) {
        return 'Le mot de passe doit contenir au moins une majuscule, un chiffre et un caractère spécial';
      }
    }

    return null; // Validation réussie
  }

  /// Valide la confirmation d'un mot de passe
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }

    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }

    return null; // Validation réussie
  }

  // ===== VALIDATION DES LOBBIES =====

  /// Valide le nom d'un lobby
  static String? validateLobbyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom du lobby est requis';
    }

    if (value.length < 3) {
      return 'Le nom du lobby doit contenir au moins 3 caractères';
    }

    if (value.length > 30) {
      return 'Le nom du lobby ne doit pas dépasser 30 caractères';
    }

    return null; // Validation réussie
  }

  /// Valide la description d'un lobby
  static String? validateLobbyDescription(String? value) {
    // La description est optionnelle
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (value.length > 200) {
      return 'La description ne doit pas dépasser 200 caractères';
    }

    return null; // Validation réussie
  }

  /// Valide le nombre maximum de joueurs pour un lobby
  static String? validateMaxPlayers(int? value) {
    if (value == null) {
      return 'Le nombre maximum de joueurs est requis';
    }

    if (value < 2) {
      return 'Un minimum de 2 joueurs est requis';
    }

    if (value > 30) {
      return 'Le maximum autorisé est de 30 joueurs';
    }

    return null; // Validation réussie
  }

  /// Valide un code d'accès de lobby
  static String? validateAccessCode(String? value, {bool isRequired = false}) {
    // Si pas requis et vide, c'est valide
    if (!isRequired && (value == null || value.isEmpty)) {
      return null;
    }

    // Si requis et vide, c'est invalide
    if (isRequired && (value == null || value.isEmpty)) {
      return 'Le code d\'accès est requis';
    }

    // Le code doit être numérique et avoir exactement 6 chiffres
    if (value != null && value.isNotEmpty) {
      if (!RegExp(r'^\d{6}$').hasMatch(value)) {
        return 'Le code doit être composé de 6 chiffres';
      }
    }

    return null; // Validation réussie
  }

  // ===== VALIDATION DES QUIZ =====

  /// Valide le titre d'un quiz
  static String? validateQuizTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le titre du quiz est requis';
    }

    if (value.length < 3) {
      return 'Le titre doit contenir au moins 3 caractères';
    }

    if (value.length > 50) {
      return 'Le titre ne doit pas dépasser 50 caractères';
    }

    return null; // Validation réussie
  }

  /// Valide le texte d'une question
  static String? validateQuestionText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le texte de la question est requis';
    }

    if (value.length > 200) {
      return 'La question ne doit pas dépasser 200 caractères';
    }

    return null; // Validation réussie
  }

  /// Valide le texte d'une réponse
  static String? validateAnswerText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le texte de la réponse est requis';
    }

    if (value.length > 100) {
      return 'La réponse ne doit pas dépasser 100 caractères';
    }

    return null; // Validation réussie
  }

  /// Vérifie qu'au moins une réponse est marquée comme correcte
  static String? validateHasCorrectAnswer(List<bool> isCorrectList) {
    if (!isCorrectList.contains(true)) {
      return 'Au moins une réponse doit être correcte';
    }

    return null; // Validation réussie
  }

  // ===== VALIDATION DES MÉDIAS =====

  /// Valide une URL de média
  static String? validateMediaUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL optionnelle
    }

    try {
      final uri = Uri.parse(value);
      if (!uri.isAbsolute) {
        return 'URL invalide';
      }
    } catch (e) {
      return 'URL invalide';
    }

    return null; // Validation réussie
  }

  /// Valide la taille d'un fichier (en octets)
  static String? validateFileSize(int size, int maxSizeBytes) {
    if (size <= 0) {
      return 'Taille de fichier invalide';
    }

    if (size > maxSizeBytes) {
      final maxSizeMB = maxSizeBytes / (1024 * 1024);
      return 'Le fichier dépasse la taille maximale autorisée (${maxSizeMB.toStringAsFixed(1)} MB)';
    }

    return null; // Validation réussie
  }

  /// Valide le type de fichier par son extension
  static String? validateFileType(
    String fileName,
    List<String> allowedExtensions,
  ) {
    final extension = fileName.split('.').last.toLowerCase();

    if (!allowedExtensions.contains(extension)) {
      return 'Type de fichier non autorisé. Types acceptés: ${allowedExtensions.join(", ")}';
    }

    return null; // Validation réussie
  }

  // ===== VALIDATIONS GÉNÉRIQUES =====

  /// Valide qu'une valeur n'est pas vide (texte, liste, map, etc.)
  static String? validateRequired(dynamic value, String fieldName) {
    if (value == null) {
      return '$fieldName est requis';
    }

    if (value is String && value.trim().isEmpty) {
      return '$fieldName est requis';
    }

    if (value is List && value.isEmpty) {
      return '$fieldName est requis';
    }

    if (value is Map && value.isEmpty) {
      return '$fieldName est requis';
    }

    return null; // Validation réussie
  }

  /// Valide la longueur minimale d'une chaîne
  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null; // Géré par validateRequired si nécessaire
    }

    if (value.length < minLength) {
      return '$fieldName doit contenir au moins $minLength caractères';
    }

    return null; // Validation réussie
  }

  /// Valide la longueur maximale d'une chaîne
  static String? validateMaxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null; // Géré par validateRequired si nécessaire
    }

    if (value.length > maxLength) {
      return '$fieldName ne doit pas dépasser $maxLength caractères';
    }

    return null; // Validation réussie
  }

  /// Valide qu'un nombre est compris dans une plage donnée
  static String? validateNumberRange(
    num? value,
    num min,
    num max,
    String fieldName,
  ) {
    if (value == null) {
      return null; // Géré par validateRequired si nécessaire
    }

    if (value < min) {
      return '$fieldName doit être au moins $min';
    }

    if (value > max) {
      return '$fieldName doit être au maximum $max';
    }

    return null; // Validation réussie
  }

  /// Valide qu'une valeur correspond à un pattern regex
  static String? validatePattern(
    String? value,
    String pattern,
    String message,
  ) {
    if (value == null || value.isEmpty) {
      return null; // Géré par validateRequired si nécessaire
    }

    if (!RegExp(pattern).hasMatch(value)) {
      return message;
    }

    return null; // Validation réussie
  }

  /// Valide qu'une valeur est unique dans une liste
  static String? validateUnique(
    dynamic value,
    List<dynamic> list,
    String fieldName,
  ) {
    if (value == null) {
      return null; // Géré par validateRequired si nécessaire
    }

    if (list.contains(value)) {
      return '$fieldName existe déjà';
    }

    return null; // Validation réussie
  }

  /// Combine plusieurs validations et retourne la première erreur trouvée
  static String? validateMultiple(List<String?> validations) {
    for (final validation in validations) {
      if (validation != null) {
        return validation;
      }
    }

    return null; // Toutes les validations sont réussies
  }

  /// Convertit une erreur de validation en ErrorCode approprié
  static ErrorCode getErrorCodeForValidationError(String error) {
    if (error.contains('requis') || error.contains('vide')) {
      return ErrorCode.invalidInput;
    }

    if (error.contains('email')) {
      return ErrorCode.invalidEmail;
    }

    if (error.contains('mot de passe') || error.contains('password')) {
      return ErrorCode.invalidPassword;
    }

    if (error.contains('existe déjà') || error.contains('unique')) {
      return ErrorCode.duplicateEntry;
    }

    return ErrorCode.invalidInput; // Code par défaut
  }
}
