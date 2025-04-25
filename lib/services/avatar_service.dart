/// Service de gestion des avatars
///
/// Ce service permet de récupérer la liste des avatars disponibles
/// et de gérer la sélection des avatars pour les utilisateurs
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class AvatarService {
  static const String avatarPath = 'assets/images/avatars/';
  static List<String> _cachedAvatarList = [];

  /// Récupère la liste des avatars disponibles dans les assets
  static Future<List<String>> getAvailableAvatars() async {
    if (_cachedAvatarList.isNotEmpty) {
      return _cachedAvatarList;
    }

    try {
      // En Flutter Web, on doit explorer les avatars manuellement
      // car AssetManifest ne fonctionne pas comme sur mobile
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifestMap = Map<String, dynamic>.from(
        json.decode(manifestContent) as Map,
      );

      final avatarPaths =
          manifestMap.keys
              .where(
                (String key) =>
                    key.startsWith(avatarPath) && key.endsWith('.png'),
              )
              .toList();

      _cachedAvatarList = avatarPaths;

      // Trier les avatars par nom
      _cachedAvatarList.sort();

      if (kDebugMode) {
        print("Avatars trouvés: ${_cachedAvatarList.length}");
      }

      return _cachedAvatarList;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors du chargement des avatars: $e");
      }
      // Retourner une liste vide en cas d'erreur
      return [];
    }
  }
}
