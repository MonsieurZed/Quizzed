import 'dart:convert';

import 'package:flutter/services.dart';

class AssetService {
  /// Returns a list of all available avatar names by extracting them from asset paths
  ///
  /// This reads the list of assets from the AssetManifest.json file at runtime
  /// and filters for avatars in the assets/images/avatars directory.
  /// It then extracts the base name of each avatar (without extension or path).
  static Future<List<String>> getAvatarNames() async {
    try {
      // Load the asset manifest file which contains all bundled assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap =
          manifestContent.isEmpty
              ? {}
              : Map<String, dynamic>.from(jsonDecode(manifestContent));

      // Filter for avatar assets and extract their names
      final List<String> avatarNames = [];

      // Get all .png files from the avatars directory
      final avatarPaths =
          manifestMap.keys
              .where(
                (String key) =>
                    key.contains('assets/images/avatars/') &&
                    key.endsWith('.png'),
              )
              .toList();

      // Si aucun avatar n'est trouvé, utiliser une liste par défaut
      if (avatarPaths.isEmpty) {
        return [
          'pirate',
          'ninja',
          'robot',
          'alien',
          'amazone',
          'astronaut',
          'chef',
          'clown',
          'cowboy',
          'king',
          'knight',
          'scientist',
          'viking',
          'witch',
          'zombie',
        ];
      }

      // Extract just the filename without extension for each avatar
      for (final path in avatarPaths) {
        // Get filename without extension from the path
        final filename = path.split('/').last.split('.').first;
        avatarNames.add(filename);
      }

      return avatarNames;
    } catch (e) {
      // En cas d'erreur, retourner une liste par défaut d'avatars
      return [
        'pirate',
        'ninja',
        'robot',
        'alien',
        'amazone',
        'astronaut',
        'chef',
        'clown',
        'cowboy',
        'king',
        'knight',
        'scientist',
        'viking',
        'witch',
        'zombie',
      ];
    }
  }
}
