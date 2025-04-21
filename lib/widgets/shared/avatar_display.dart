// filepath: d:\GIT\quizzzed\lib\widgets\shared\avatar_display.dart
/// Avatar Display
///
/// Widget pour afficher l'avatar d'un utilisateur avec différentes options
/// de présentation et de taille
library;

import 'package:flutter/material.dart';

class AvatarDisplay extends StatelessWidget {
  final String? avatarUrl;
  final Color? backgroundColor;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final bool isOnline;
  final bool isMuted;

  const AvatarDisplay({
    super.key,
    this.avatarUrl,
    this.backgroundColor,
    this.size = 40.0,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
    this.isOnline = false,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorderColor = borderColor ?? theme.colorScheme.primary;
    final defaultBackgroundColor = backgroundColor ?? theme.colorScheme.surface;

    return Stack(
      children: [
        // Avatar container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: defaultBackgroundColor,
            border:
                showBorder
                    ? Border.all(color: defaultBorderColor, width: borderWidth)
                    : null,
          ),
          child:
              avatarUrl != null && avatarUrl!.isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(size / 2),
                    child:
                        avatarUrl!.startsWith('http')
                            ? Image.network(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              width: size,
                              height: size,
                              errorBuilder:
                                  (_, __, ___) => _buildFallbackAvatar(),
                              loadingBuilder: (_, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildLoadingAvatar();
                              },
                            )
                            : Image.asset(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              width: size,
                              height: size,
                              errorBuilder:
                                  (_, __, ___) => _buildFallbackAvatar(),
                            ),
                  )
                  : _buildFallbackAvatar(),
        ),

        // Online status indicator
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size / 3.5,
              height: size / 3.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
            ),
          ),

        // Muted indicator
        if (isMuted)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size / 3,
              height: size / 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.error,
                border: Border.all(color: theme.colorScheme.surface, width: 1),
              ),
              child: Center(
                child: Icon(
                  Icons.mic_off,
                  size: size / 6,
                  color: theme.colorScheme.onError,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return Center(
      child: Icon(Icons.person, size: size * 0.6, color: Colors.white54),
    );
  }

  Widget _buildLoadingAvatar() {
    return Center(
      child: SizedBox(
        width: size * 0.5,
        height: size * 0.5,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
