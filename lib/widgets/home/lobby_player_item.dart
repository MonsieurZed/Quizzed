/// Lobby Player Item
///
/// Widget qui affiche un joueur dans la liste des joueurs d'un lobby
/// Indique le statut de préparation du joueur et s'il est l'hôte

import 'package:flutter/material.dart';
import 'package:quizzzed/models/quiz/lobby_model.dart';

class LobbyPlayerItem extends StatelessWidget {
  final LobbyPlayerModel player;
  final bool isHost;
  final bool isCurrentUser;
  final VoidCallback? onKick;

  const LobbyPlayerItem({
    Key? key,
    required this.player,
    this.isHost = false,
    this.isCurrentUser = false,
    this.onKick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isCurrentUser
                ? theme.colorScheme.primaryContainer.withAlpha(
                  (255 * 0.2).toInt(),
                )
                : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isCurrentUser
                  ? theme.colorScheme.primary.withAlpha((255 * 0.3).toInt())
                  : theme.dividerColor,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundImage:
              player.avatarUrl.isNotEmpty
                  ? NetworkImage(player.avatarUrl)
                  : null,
          child: player.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                player.displayName,
                style: TextStyle(
                  fontWeight:
                      isHost || player.isHost
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (player.isHost || isHost)
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
          'A rejoint ${_getTimeAgo(player.joinedAt)}',
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur de statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    player.isReady
                        ? theme.colorScheme.primaryContainer
                        : theme.disabledColor.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                player.isReady ? 'Prêt' : 'En attente',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      player.isReady
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Bouton d'expulsion (visible pour l'hôte uniquement)
            if (isHost && !player.isHost && onKick != null)
              IconButton(
                onPressed: onKick,
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
