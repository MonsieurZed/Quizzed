import 'package:flutter/material.dart';
import 'package:quizzed/routes/app_routes.dart';
import 'package:quizzed/widgets/player_avatar.dart';

class QuizLobbyScreen extends StatefulWidget {
  const QuizLobbyScreen({super.key});

  @override
  State<QuizLobbyScreen> createState() => _QuizLobbyScreenState();
}

class _QuizLobbyScreenState extends State<QuizLobbyScreen> {
  // Mock data for demo
  final List<Map<String, dynamic>> _players = [
    {
      'name': 'Alice',
      'avatar': 'amazone',
      'color': const Color(0xFFFF39FF),
      'ready': true,
    },
    {
      'name': 'Bob',
      'avatar': 'pirate',
      'color': const Color(0xFF39FFFF),
      'ready': true,
    },
    {
      'name': 'Charlie',
      'avatar': 'ninja',
      'color': const Color(0xFF39FF14),
      'ready': false,
    },
  ];

  bool _isReady = false;
  String _quizStatus = "En attente du lancement par le MJ";

  @override
  Widget build(BuildContext context) {
    // Get arguments from navigation (player name, avatar and color)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Utilise la taille d'écran pour détecter l'environnement PC
    final screenSize = MediaQuery.of(context).size;
    final ratio = screenSize.width / screenSize.height;

    // Optimiser pour les écrans PC (ratio proche de 16:9 ~ 1.77)
    final isDesktop = ratio >= 1.6 && screenSize.width > 1200;
    final isTablet = screenSize.width > 900 && !isDesktop;

    if (args != null) {
      // In a real app, this would update a database entry
      // For now we just set local state and mock data
      if (!_players.any((player) => player['name'] == args['nickname'])) {
        _players.add({
          'name': args['nickname'],
          'avatar': args['avatar'],
          'color': args['color'],
          'ready': false,
        });
      }
    }

    return Scaffold(
      appBar:
          isDesktop
              ? null // Pas d'AppBar sur desktop pour une expérience plein écran
              : AppBar(
                title: const Text('Lobby de quiz'),
                actions: [_buildInfoButton()],
              ),
      body: Center(
        // Center all content
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo and title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Salle d\'attente',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            isDesktop
                ? _buildDesktopLayout()
                : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? screenSize.width * 0.1 : 16.0,
                    vertical: 16.0,
                  ),
                  child:
                      isTablet
                          ? _buildWideScreenLayout()
                          : _buildMobileLayout(),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoButton() {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      onPressed: () {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('À propos du quiz'),
                content: const Text(
                  'Attendez que tous les joueurs soient prêts et que le MJ lance la partie.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Compris'),
                  ),
                ],
              ),
        );
      },
    );
  }

  // Nouvelle méthode pour layout desktop optimisé pour 16:9
  Widget _buildDesktopLayout() {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Fond avec bannière et logo (simulé ici)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primaryContainer, colorScheme.surface],
            ),
          ),
        ),

        // Contenu principal
        Row(
          children: [
            // Panneau latéral gauche - Statut du quiz et informations
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.1),
                border: Border(
                  right: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo et titre du jeu
                  Row(
                    children: [
                      Icon(
                        Icons.quiz,
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'QUIZZED',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Statut de la session
                  _buildDesktopSessionStatus(),

                  const Spacer(),

                  // Bouton pour se déclarer prêt
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isReady = !_isReady;
                          // Update the current player's ready status
                          final args =
                              ModalRoute.of(context)?.settings.arguments
                                  as Map<String, dynamic>?;
                          if (args != null) {
                            final playerIndex = _players.indexWhere(
                              (player) => player['name'] == args['nickname'],
                            );
                            if (playerIndex >= 0) {
                              _players[playerIndex]['ready'] = _isReady;
                            }
                          }
                        });

                        // Simulate quiz starting when all players are ready
                        if (_players.every(
                          (player) => player['ready'] == true,
                        )) {
                          Future.delayed(const Duration(seconds: 2), () {
                            Navigator.pushNamed(context, AppRoutes.quizSession);
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isReady ? colorScheme.error : colorScheme.tertiary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isReady ? 'Annuler' : 'Je suis prêt',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              _isReady
                                  ? colorScheme.onError
                                  : colorScheme.onTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Zone principale - Liste des joueurs
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre supérieure
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Joueurs dans le lobby',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildInfoButton(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bannière d'information
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Attendez que tous les joueurs soient prêts et que le MJ lance la partie.',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Liste des joueurs en grille responsive
                    Expanded(child: _buildPlayersDesktopGrid()),
                  ],
                ),
              ),
            ),

            // Panneau latéral droit avec chat ou informations complémentaires (optionnel)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.1),
                border: Border(
                  left: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'À propos du quiz',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Informations sur le quiz
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceVariant.withOpacity(0.2),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer, size: 20),
                              SizedBox(width: 8),
                              Text('Durée estimée: 15 min'),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.quiz, size: 20),
                              SizedBox(width: 8),
                              Text('10 questions'),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.stars, size: 20),
                              SizedBox(width: 8),
                              Text('Difficulté: Moyenne'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Règles du jeu
                  const Text(
                    'Règles du jeu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    '• Répondez aux questions dans le temps imparti\n'
                    '• Les réponses rapides rapportent plus de points\n'
                    '• Le joueur avec le plus de points gagne',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget optimisé pour afficher l'état de la session sur desktop
  Widget _buildDesktopSessionStatus() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'État de la session',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Status avec icône animée
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color:
                      _quizStatus.contains('lancement')
                          ? colorScheme.error
                          : colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_quizStatus, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Compteur de joueurs
        Row(
          children: [
            const Icon(Icons.group, size: 20),
            const SizedBox(width: 12),
            const Text('Joueurs: ', style: TextStyle(fontSize: 16)),
            Text(
              '${_players.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Compteur de joueurs prêts
        Row(
          children: [
            const Icon(Icons.check_circle, size: 20),
            const SizedBox(width: 12),
            const Text('Joueurs prêts: ', style: TextStyle(fontSize: 16)),
            Text(
              '${_players.where((p) => p['ready'] == true).length}/${_players.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  // Grille de joueurs optimisée pour desktop
  Widget _buildPlayersDesktopGrid() {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 cartes par ligne
        childAspectRatio: 2.2, // Ratio adapté pour les écrans 16:9
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  player['ready']
                      ? colorScheme.tertiary.withOpacity(0.5)
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar avec badge de statut
                Stack(
                  children: [
                    PlayerAvatar(
                      avatarName: player['avatar'],
                      backgroundColor: player['color'],
                      size: 80,
                      allowOverflow: true,
                    ),
                    if (player['ready'])
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: colorScheme.onTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        player['name'],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              player['ready']
                                  ? colorScheme.tertiary.withOpacity(0.2)
                                  : colorScheme.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          player['ready'] ? 'Prêt' : 'En attente',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                player['ready']
                                    ? colorScheme.tertiary
                                    : colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Méthodes existantes pour la compatibilité avec les autres appareils
  Widget _buildWideScreenLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne de gauche pour l'état de la session
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSessionStatusCard(),
              const SizedBox(height: 24),
              _buildReadyButton(),
            ],
          ),
        ),

        const SizedBox(width: 24),

        // Colonne de droite pour les joueurs
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Joueurs dans le lobby',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildPlayersGrid(
                  4,
                ), // 4 joueurs par ligne pour un écran large
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSessionStatusCard(),
        const SizedBox(height: 16),
        const Text(
          'Joueurs dans le lobby',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildPlayersGrid(
            3,
          ), // 3 joueurs par ligne pour un écran mobile
        ),
        const SizedBox(height: 16),
        _buildReadyButton(),
      ],
    );
  }

  Widget _buildSessionStatusCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'État de la session',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color:
                        _quizStatus.contains('lancement')
                            ? colorScheme.tertiary
                            : colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(_quizStatus, style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Joueurs prêts: ', style: TextStyle(fontSize: 16)),
                Text(
                  '${_players.where((p) => p['ready'] == true).length}/${_players.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersGrid(int crossAxisCount) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                PlayerAvatar(
                  avatarName: player['avatar'],
                  backgroundColor: player['color'],
                  size: 60,
                  allowOverflow: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        player['name'],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            player['ready']
                                ? Icons.check_circle
                                : Icons.hourglass_empty,
                            color:
                                player['ready']
                                    ? colorScheme.tertiary
                                    : colorScheme.error,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            player['ready'] ? 'Prêt' : 'En attente',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  player['ready']
                                      ? colorScheme.tertiary
                                      : colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadyButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _isReady = !_isReady;
            // Update the current player's ready status
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            if (args != null) {
              final playerIndex = _players.indexWhere(
                (player) => player['name'] == args['nickname'],
              );
              if (playerIndex >= 0) {
                _players[playerIndex]['ready'] = _isReady;
              }
            }
          });

          // Simulate quiz starting when all players are ready
          // In a real app, this would come from a Firebase event
          if (_players.every((player) => player['ready'] == true)) {
            // Simulate delay before starting
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pushNamed(context, AppRoutes.quizSession);
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isReady ? colorScheme.error : colorScheme.tertiary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          _isReady ? 'Annuler' : 'Je suis prêt',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isReady ? colorScheme.onError : colorScheme.onTertiary,
          ),
        ),
      ),
    );
  }
}
