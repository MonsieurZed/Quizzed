/// Widget de prévisualisation d'avatar
///
/// Affiche l'avatar de l'utilisateur avec la couleur de fond sélectionnée
/// Utilisé pour prévisualiser les changements dans l'édition de profil
/// L'image peut déborder légèrement du cercle pour un effet visuel plus dynamique
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/config/app_config.dart';

class AvatarDisplay extends StatelessWidget {
  final String? avatar;
  final Color? color;
  final double size;
  final bool showBorder;
  final bool allowOverflow;
  final double? opacityOverride;

  const AvatarDisplay({
    super.key,
    this.avatar,
    this.color,
    this.size = 80.0,
    this.showBorder = true,
    this.allowOverflow = true,
    this.opacityOverride,
  });

  @override
  Widget build(BuildContext context) {
    // Utiliser l'avatar par défaut si aucun n'est fourni
    final avatarUrl =
        'assets/images/avatars/${avatar ?? AppConfig.defaultUserAvatar}.png';

    // Obtenir la couleur à partir du nom et appliquer l'opacité configurable
    final Color originalColor = color ?? Colors.blue;
    final double opacity = opacityOverride ?? AppConfig.colorOpacity;

    // Appliquer l'opacité à la couleur
    final Color bgColor = originalColor.withOpacity(opacity);

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
                  ).colorScheme.onSurface.withAlpha((255 * 0.2).toInt()),
                  width: 2,
                )
                : null,
        boxShadow:
            showBorder
                ? [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.2).toInt()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      // Suppression du padding pour maximiser la taille de l'image
      child:
          allowOverflow
              ? _buildOverflowAvatar(avatarUrl) // Avatar avec débordement
              : ClipOval(
                child: Image.asset(avatarUrl, fit: BoxFit.cover),
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
