/// Lobby Card
///
/// Widget qui affiche un lobby dans la liste des lobbys disponibles
/// Contient les informations essentielles et un bouton pour le rejoindre
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/models/quiz/lobby_model.dart';

class LobbyCard extends StatelessWidget {
  final LobbyModel lobby;
  final VoidCallback onJoin;
  final bool canJoin;
  final bool isHost;

  const LobbyCard({
    super.key,
    required this.lobby,
    required this.onJoin,
    this.canJoin = true,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onJoin,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icône de catégorie
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(lobby.category),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nom et détails
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lobby.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Catégorie: ${lobby.category}',
                          style: TextStyle(color: theme.hintColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Indicateur de visibilité
                  if (lobby.visibility == LobbyVisibility.private)
                    Tooltip(
                      message: 'Lobby privé',
                      child: Icon(Icons.lock, size: 16, color: theme.hintColor),
                    ),
                ],
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
                      child: const Text('Reprendre'),
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
