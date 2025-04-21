/// Widget de prévisualisation d'avatar
///
/// Affiche l'avatar de l'utilisateur avec la couleur de fond sélectionnée
/// Utilisé pour prévisualiser les changements dans l'édition de profil
/// L'image peut déborder légèrement du cercle pour un effet visuel plus dynamique

import 'package:flutter/material.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/models/user/profile_color.dart';

class AvatarPreview extends StatelessWidget {
  final String? avatarUrl;
  final String? backgroundColor;
  final double size;
  final bool showBorder;
  final bool allowOverflow;

  const AvatarPreview({
    Key? key,
    this.avatarUrl,
    this.backgroundColor,
    this.size = 80.0,
    this.showBorder = true,
    this.allowOverflow =
        true, // Nouvelle propriété pour contrôler le débordement
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Utiliser l'avatar par défaut si aucun n'est fourni
    final String avatar = avatarUrl ?? AppConfig.defaultAvatarUrl;

    // Obtenir la couleur à partir du nom
    final Color bgColor =
        backgroundColor != null
            ? ProfileColor.getByName(backgroundColor!)?.color ?? Colors.blue
            : Colors.blue;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border:
            showBorder
                ? Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withAlpha((255 * 0.2).toInt()),
                  width: 2,
                )
                : null,
        boxShadow:
            showBorder
                ? [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.2).toInt()),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
                : null,
      ),
      // Suppression du padding pour maximiser la taille de l'image
      child:
          allowOverflow
              ? _buildOverflowAvatar(avatar) // Avatar avec débordement
              : ClipOval(
                child: Image.asset(avatar, fit: BoxFit.cover),
              ), // Avatar sans débordement
    );
  }

  // Construit un avatar qui peut déborder légèrement du cercle
  Widget _buildOverflowAvatar(String avatar) {
    // Calculer la taille de l'image avec débordement (110% de la taille du cercle)
    final double imageSize = size * 1.1;

    return Center(
      child: SizedBox(
        width: imageSize,
        height: imageSize,
        child: Image.asset(avatar, fit: BoxFit.cover),
      ),
    );
  }
}
