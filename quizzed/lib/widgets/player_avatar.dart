import 'package:flutter/material.dart';

class PlayerAvatar extends StatelessWidget {
  final String avatarName;
  final Color backgroundColor;
  final double size;
  final bool isSelected;
  final bool allowOverflow;
  final Function()? onTap;

  const PlayerAvatar({
    super.key,
    required this.avatarName,
    required this.backgroundColor,
    this.size = 60,
    this.isSelected = false,
    this.allowOverflow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border:
            isSelected
                ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                )
                : null,
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Image.asset(
              'assets/images/avatars/$avatarName.png',
              fit:
                  BoxFit
                      .cover, // Cover au lieu de contain pour un meilleur remplissage
              filterQuality:
                  FilterQuality.high, // Améliorer la qualité du filtre
              isAntiAlias: true, // Activer l'anti-aliasing
              errorBuilder: (context, error, stackTrace) {
                // Fallback en cas d'erreur de chargement de l'image
                return Icon(
                  Icons.person,
                  color: Colors.white,
                  size: size * 0.6,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
