/// Utilitaires pour la manipulation des couleurs
///
/// Fournit des méthodes standardisées pour la conversion et la manipulation
/// des objets Color dans l'application
library;

import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:quizzzed/config/app_config.dart';

class ColorUtils {
  /// Convertit une valeur (chaîne, int) en Color
  ///
  /// Accepte plusieurs formats d'entrée:
  /// - Un entier représentant la valeur de la couleur
  /// - Une chaîne numérique représentant la valeur de la couleur
  /// - Une chaîne hexadécimale (avec ou sans #)
  ///
  /// Retourne null si la conversion échoue.
  static Color? fromValue(dynamic value) {
    if (value == null) return null;

    try {
      if (value is int) {
        // Convertir directement un int en Color
        return Color(value);
      } else if (value is String) {
        // Cas 1: La chaîne est numérique
        if (value.startsWith('0x') || RegExp(r'^[0-9]+$').hasMatch(value)) {
          return Color(int.parse(value));
        }
        // Cas 2: La chaîne est un code hexadécimal (ex: "#FF0000" ou "FF0000")
        else if (RegExp(r'^#?[0-9A-Fa-f]{6,8}$').hasMatch(value)) {
          final hexCode = value.startsWith('#') ? value.substring(1) : value;
          final hexValue = int.parse(
            '0xFF${hexCode.padRight(8, 'F').substring(0, 8)}',
          );
          return Color(hexValue);
        }
        // Cas 3: La chaîne est un nom de couleur prédéfini
        else {
          final namedColor = getProfileColorByName(value);
          if (namedColor != null) {
            return namedColor.color;
          }
        }
      }
    } catch (e) {
      developer.log(
        'Erreur lors de la conversion de la couleur: $e',
        name: 'ColorUtils',
      );
    }

    return null;
  }

  /// Convertit un objet Color en valeur pour le stockage
  ///
  /// Convertit une couleur en chaîne représentant sa valeur numérique,
  /// format optimal pour le stockage dans Firestore.
  ///
  /// Retourne null si la couleur est null.
  static String? toStorageValue(Color? color) {
    return color != null ? color.value.toString() : null;
  }

  /// Convertit une couleur en format hexadécimal lisible
  ///
  /// Format: #RRGGBB ou #AARRGGBB si includeAlpha est true
  static String? toHexString(Color? color, {bool includeAlpha = false}) {
    if (color == null) return null;

    if (includeAlpha) {
      return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    } else {
      return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    }
  }

  /// Détermine si une couleur est claire ou foncée
  ///
  /// Utile pour choisir une couleur de texte contrastée
  static bool isLightColor(Color color) {
    // Formule de luminosité perçue (perceptual brightness)
    // https://www.w3.org/TR/AERT/#color-contrast
    final luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5;
  }

  /// Renvoie une couleur appropriée pour le texte en fonction de la couleur de fond
  ///
  /// Noir pour les couleurs claires, blanc pour les couleurs foncées
  static Color getTextColorForBackground(Color backgroundColor) {
    return isLightColor(backgroundColor) ? Colors.black : Colors.white;
  }

  /// Obtient une couleur de profil à partir de son nom
  ///
  /// Renvoie null si le nom ne correspond à aucune couleur disponible
  static ProfileColor? getProfileColorByName(String name) {
    try {
      return AppConfig.availableProfileColors.firstWhere(
        (color) => color.name == name,
      );
    } catch (e) {
      developer.log(
        'Couleur de profil non trouvée pour le nom: $name',
        name: 'ColorUtils',
      );
      return null;
    }
  }

  /// Obtient une couleur de profil à partir d'un objet Color
  ///
  /// Renvoie null si aucune couleur de profil ne correspond à cette couleur
  static ProfileColor? getProfileColorFromColor(Color color) {
    try {
      return AppConfig.availableProfileColors.firstWhere(
        (profileColor) => profileColor.color.value == color.value,
      );
    } catch (e) {
      developer.log(
        'Aucune couleur de profil ne correspond à cette couleur',
        name: 'ColorUtils',
      );
      return null;
    }
  }

  /// Obtient la couleur de texte appropriée pour une couleur de profil donnée
  ///
  /// Utilise la couleur de texte définie dans le profil ou calcule une par défaut
  static Color getTextColorForProfileColor(ProfileColor profileColor) {
    return profileColor.textColor;
  }

  /// Renvoie la couleur de profil par défaut
  static ProfileColor getDefaultProfileColor() {
    // La couleur Bleu est utilisée comme couleur par défaut
    return AppConfig.availableProfileColors.firstWhere(
      (c) => c.color.value == AppConfig.defaultUserColor.value,
      orElse:
          () => AppConfig.availableProfileColors.firstWhere(
            (c) => c.name == 'Bleu',
            orElse: () => AppConfig.availableProfileColors.first,
          ),
    );
  }
}
