/// Modèle de couleur de profil
///
/// Représente une couleur disponible pour le fond du profil utilisateur
/// Utilisé dans la sélection de couleur pour l'avatar
library;

import 'package:flutter/material.dart';

class ProfileColor {
  final String name;
  final Color color;
  final Color textColor;

  ProfileColor({
    required this.name,
    required this.color,
    this.textColor = Colors.white,
  });

  /// Liste des couleurs disponibles pour le profil
  static List<ProfileColor> get availableColors => [
    ProfileColor(name: 'Rouge', color: Colors.red),
    ProfileColor(name: 'Rose', color: Colors.pink),
    ProfileColor(name: 'Violet', color: Colors.purple),
    ProfileColor(name: 'Indigo', color: Colors.indigo),
    ProfileColor(name: 'Bleu', color: Colors.blue),
    ProfileColor(name: 'Cyan', color: Colors.cyan),
    ProfileColor(name: 'Turquoise', color: Colors.teal),
    ProfileColor(name: 'Vert', color: Colors.green),
    ProfileColor(name: 'Lime', color: Colors.lime, textColor: Colors.black),
    ProfileColor(name: 'Jaune', color: Colors.yellow, textColor: Colors.black),
    ProfileColor(name: 'Ambre', color: Colors.amber, textColor: Colors.black),
    ProfileColor(name: 'Orange', color: Colors.orange),
    ProfileColor(name: 'Orangé', color: Colors.deepOrange),
    ProfileColor(name: 'Marron', color: Colors.brown),
    ProfileColor(name: 'Gris', color: Colors.grey),
    ProfileColor(name: 'Bleu-gris', color: Colors.blueGrey),
    ProfileColor(name: 'Noir', color: Colors.black),
    ProfileColor(name: 'Blanc', color: Colors.white, textColor: Colors.black),
  ];

  /// Obtient une couleur par son nom
  static ProfileColor? getByName(String name) {
    try {
      return availableColors.firstWhere((color) => color.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Obtient une couleur de profil à partir d'un code couleur
  static ProfileColor? fromColor(Color color) {
    try {
      return availableColors.firstWhere((c) => c.color == color);
    } catch (e) {
      return null;
    }
  }
}
