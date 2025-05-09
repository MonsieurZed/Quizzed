/// Lobby Player Item
///
/// Widget qui affiche un joueur dans la liste des joueurs d'un lobby
/// Indique le statut de préparation du joueur et s'il est l'hôte
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/models/lobby/lobby_player_model.dart';
import 'package:quizzzed/widgets/profile/avatar_preview.dart';

class LobbyPlayerItem extends StatefulWidget {
  final LobbyPlayerModel player;
  final bool isHost;
  final bool isCurrentUser;
  final VoidCallback? onKick;

  const LobbyPlayerItem({
    super.key,
    required this.player,
    this.isHost = false,
    this.isCurrentUser = false,
    this.onKick,
  });

  @override
  State<LobbyPlayerItem> createState() => _LobbyPlayerItemState();
}

class _LobbyPlayerItemState extends State<LobbyPlayerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Ne démarrer l'animation que si le joueur est en attente
    if (!widget.player.isReady) {
      _animationController.forward();
    } else {
      _animationController.stop();
    }
  }

  @override
  void didUpdateWidget(LobbyPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Gérer les changements d'état
    if (widget.player.isReady != oldWidget.player.isReady) {
      if (widget.player.isReady) {
        _animationController.stop();
      } else {
        _animationController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastActive =
        widget.player.lastActive != null &&
        DateTime.now().difference(widget.player.lastActive!).inMinutes <= 3;

    // Déterminer la couleur d'arrière-plan de l'avatar à partir de la couleur de profil
    Color? playerColor = widget.player.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            widget.isCurrentUser
                ? theme.colorScheme.primaryContainer.withAlpha(
                  (255 * 0.2).toInt(),
                )
                : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              widget.isCurrentUser
                  ? theme.colorScheme.primary.withAlpha((255 * 0.3).toInt())
                  : theme.dividerColor,
          width: 1,
        ),
        boxShadow:
            widget.player.isReady
                ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(
                      (255 * 0.3).toInt(),
                    ),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            // Utiliser AvatarDisplay avec la couleur de profil de l'utilisateur
            AvatarDisplay(
              avatar: widget.player.avatar,
              size: 40,
              color: playerColor,
            ),
            if (isLastActive)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.player.displayName,
                style: TextStyle(
                  fontWeight:
                      widget.isHost || widget.player.isHost
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.player.isHost || widget.isHost)
              Tooltip(
                message: 'Hôte',
                child: Icon(
                  Icons.star,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
              ),
          ],
        ),
        subtitle: Text(
          'A rejoint ${_getTimeAgo(widget.player.joinedAt)}',
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur de statut
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                // Définir les variables pour le statut et les couleurs
                final bool isReady = widget.player.isReady;
                final IconData statusIcon =
                    isReady ? Icons.check_circle : Icons.hourglass_empty;
                final String statusText = isReady ? 'Prêt' : 'En attente';
                final Color statusColor =
                    isReady ? theme.colorScheme.primary : theme.disabledColor;
                final Color containerColor =
                    isReady
                        ? theme.colorScheme.primaryContainer
                        : theme.disabledColor.withAlpha((255 * 0.1).toInt());

                return Transform.scale(
                  scale: isReady ? 1.0 : _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Bouton d'expulsion (visible pour l'hôte uniquement)
            if (widget.isHost && !widget.player.isHost && widget.onKick != null)
              IconButton(
                onPressed: widget.onKick,
                icon: Icon(
                  Icons.person_remove,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Expulser',
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  // Calcule et formate le temps écoulé depuis que le joueur a rejoint le lobby
  String _getTimeAgo(DateTime joinTime) {
    final now = DateTime.now();
    final difference = now.difference(joinTime);

    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} ${difference.inDays == 1 ? 'jour' : 'jours'}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours} ${difference.inHours == 1 ? 'heure' : 'heures'}';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return 'à l\'instant';
    }
  }
}
