/// Lobby Card
///
/// Widget qui affiche un lobby dans la liste des lobbys disponibles
/// Contient les informations essentielles et un bouton pour le rejoindre
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';
import 'package:quizzzed/models/lobby/lobby_player_model.dart';
import 'package:quizzzed/widgets/profile/avatar_preview.dart';

class LobbyCard extends StatelessWidget {
  final LobbyModel lobby;
  final VoidCallback onJoin;
  final bool canJoin;
  final bool isHost;
  final bool isCurrentLobby;

  const LobbyCard({
    super.key,
    required this.lobby,
    required this.onJoin,
    this.canJoin = true,
    this.isHost = false,
    this.isCurrentLobby = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Trouver le joueur hôte et son avatar/couleur
    final hostPlayer = lobby.players.firstWhere(
      (player) => player.userId == lobby.hostId,
      orElse: () => lobby.players.first,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: isCurrentLobby ? 4 : null,
      shape:
          isCurrentLobby
              ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: theme.colorScheme.primary, width: 2),
              )
              : null,
      child: InkWell(
        onTap: onJoin,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar de l'hôte avec sa couleur de profil
                  AvatarDisplay(
                    avatar: hostPlayer.avatar,
                    size: 50,
                    color: hostPlayer.color,
                  ),
                  const SizedBox(width: 12),

                  // Nom et détails
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lobby.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentLobby)
                              Tooltip(
                                message: 'Vous êtes dans ce lobby',
                                child: Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getCategoryIcon(lobby.category),
                              size: 14,
                              color: theme.hintColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lobby.category,
                              style: TextStyle(color: theme.hintColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 8),
                            // Indicateur de visibilité
                            if (lobby.visibility == LobbyVisibility.private)
                              Tooltip(
                                message: 'Lobby privé',
                                child: Icon(
                                  Icons.lock,
                                  size: 14,
                                  color: theme.hintColor,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hôte: ${hostPlayer.displayName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.hintColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Liste des joueurs présents
              if (lobby.players.length >
                  1) // Afficher seulement s'il y a plus que l'hôte
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Joueurs:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildPlayersList(context, lobby.players),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Informations supplémentaires et actions
              Row(
                children: [
                  // Nombre de joueurs
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 16, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Text(
                          '${lobby.players.length}/${lobby.maxPlayers} joueurs',
                          style: TextStyle(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),

                  // Bouton de participation
                  if (isHost)
                    OutlinedButton(
                      onPressed: onJoin,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Rejoindre'),
                    )
                  else if (isCurrentLobby)
                    ElevatedButton(
                      onPressed: onJoin,
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: const Text('Continuer'),
                    )
                  else if (canJoin && !lobby.isFull)
                    ElevatedButton(
                      onPressed: onJoin,
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Rejoindre'),
                    )
                  else if (lobby.isFull)
                    OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Complet'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthode pour construire la liste des joueurs avec leurs avatars
  Widget _buildPlayersList(
    BuildContext context,
    List<LobbyPlayerModel> players,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          final isHost = player.userId == lobby.hostId;

          // On pourrait filtrer pour ne pas répéter l'hôte, mais on montre tous les joueurs
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Tooltip(
              message:
                  '${player.displayName}${isHost ? ' (Hôte)' : ''}${player.isReady ? ' ✓' : ''}',
              child: Stack(
                children: [
                  // Avatar du joueur
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isHost
                                ? theme.colorScheme.primary
                                : player.isReady
                                ? Colors.green
                                : theme.hintColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: AvatarDisplay(
                      avatar: player.avatar,
                      size: 36,
                      color: player.color,
                    ),
                  ),

                  // Indicateur de statut (prêt/hôte)
                  if (isHost || player.isReady)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color:
                              isHost ? theme.colorScheme.primary : Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.cardColor,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isHost ? Icons.star : Icons.check,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'science':
        return Icons.science;
      case 'histoire':
        return Icons.history_edu;
      case 'géographie':
      case 'geographie':
        return Icons.public;
      case 'sport':
        return Icons.sports;
      case 'musique':
        return Icons.music_note;
      case 'cinéma':
      case 'cinema':
        return Icons.movie;
      case 'littérature':
      case 'litterature':
        return Icons.book;
      case 'art':
        return Icons.palette;
      case 'technologie':
        return Icons.computer;
      case 'cuisine':
        return Icons.restaurant;
      default:
        return Icons.quiz;
    }
  }
}
