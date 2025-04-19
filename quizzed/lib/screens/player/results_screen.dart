import 'package:flutter/material.dart';
import 'package:quizzed/routes/app_routes.dart';
import 'package:quizzed/services/logging_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  final LoggingService _logger = LoggingService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Mock data for the results demo
  final List<Map<String, dynamic>> leaderboard = [
    {
      'name': 'Alice',
      'avatar': 'amazone',
      'color': Colors.blue,
      'score': 8500,
      'correctAnswers': 9,
      'totalQuestions': 10,
      'responseTime': 2.4, // temps moyen de réponse en secondes
    },
    {
      'name': 'Bob',
      'avatar': 'pirate',
      'color': Colors.red,
      'score': 7200,
      'correctAnswers': 8,
      'totalQuestions': 10,
      'responseTime': 3.1,
    },
    {
      'name': 'Charlie',
      'avatar': 'ninja',
      'color': Colors.green,
      'score': 6000,
      'correctAnswers': 6,
      'totalQuestions': 10,
      'responseTime': 3.8,
    },
    {
      'name': 'David',
      'avatar': 'chevalier',
      'color': Colors.purple,
      'score': 5400,
      'correctAnswers': 6,
      'totalQuestions': 10,
      'responseTime': 4.2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _logger.logInfo(
      'Results screen initialized with ${leaderboard.length} players',
      'ResultsScreen.initState',
    );

    // Log the winner
    if (leaderboard.isNotEmpty) {
      _logger.logInfo(
        'Quiz winner: ${leaderboard[0]['name']} with score: ${leaderboard[0]['score']}',
        'ResultsScreen.initState',
      );
    }

    // Mise en place de l'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    // Démarrer l'animation après construction de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logger.logInfo('Results screen disposed', 'ResultsScreen.dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Trier par score
    leaderboard.sort((a, b) => b['score'].compareTo(a['score']));

    // Taille de l'écran pour adapter l'interface
    final screenSize = MediaQuery.of(context).size;
    final ratio = screenSize.width / screenSize.height;

    // Optimiser pour les écrans PC (ratio proche de 16:9 ~ 1.77)
    final isDesktop = ratio >= 1.6 && screenSize.width > 1200;
    final isTablet = screenSize.width > 900 && !isDesktop;

    return Scaffold(
      appBar:
          isDesktop
              ? null
              : AppBar(
                title: const Text('Résultats du quiz'),
                automaticallyImplyLeading: false,
              ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(isTablet),
    );
  }

  Widget _buildDesktopLayout() {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Arrière-plan avec confettis et célébration
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorScheme.primaryContainer, colorScheme.surface],
            ),
          ),
        ),

        // Illustration de confettis (simulation)
        Positioned.fill(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Opacity(
              opacity: 0.3,
              child: Image.network(
                'https://www.transparentpng.com/thumb/confetti/0Wcyv3-confetti-transparent.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // Contenu principal
        Column(
          children: [
            // En-tête avec titre et logo
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: colorScheme.surfaceTint.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      Icon(Icons.quiz, size: 32, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      const Text(
                        'QUIZZED',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      _logger.logInfo(
                        'Player selected "New Game" from results screen',
                        'ResultsScreen.newGame',
                      );
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.quizLobby,
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Nouvelle partie'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      _logger.logInfo(
                        'Player selected "Home" from results screen',
                        'ResultsScreen.goHome',
                      );
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Accueil'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      side: BorderSide(color: colorScheme.outline),
                    ),
                  ),
                ],
              ),
            ),

            // Zone principale avec podium et classement
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        '🏆 Fin du Quiz - Résultats 🏆',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.tertiary,
                          shadows: [
                            Shadow(
                              color: colorScheme.shadow,
                              blurRadius: 10,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Zone principale avec podium et classement
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Podium (partie gauche)
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: SizedBox(
                              width: 500,
                              child: Center(
                                child:
                                    leaderboard.length >= 3
                                        ? _buildFancyPodium()
                                        : _buildWinnerCard(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 60),

                          // Classement détaillé (partie droite)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Classement détaillé',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // En-têtes du tableau
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 50),
                                      const SizedBox(
                                        width: 240,
                                        child: Text('Joueur'),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  'Score',
                                                  style: TextStyle(
                                                    color: colorScheme.tertiary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  'Bonnes réponses',
                                                  style: TextStyle(
                                                    color:
                                                        colorScheme.secondary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Text(
                                                  'Temps moyen',
                                                  style: TextStyle(
                                                    color: colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Divider(
                                  color: colorScheme.outline.withOpacity(0.2),
                                ),

                                // Liste des joueurs avec leurs statistiques
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: leaderboard.length,
                                    itemBuilder: (context, index) {
                                      final player = leaderboard[index];
                                      final isWinner = index == 0;
                                      final isRunnerUp = index == 1;
                                      final isThird = index == 2;

                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isWinner
                                                  ? colorScheme.tertiary
                                                      .withOpacity(0.15)
                                                  : isRunnerUp
                                                  ? colorScheme.secondary
                                                      .withOpacity(0.1)
                                                  : isThird
                                                  ? colorScheme.primaryContainer
                                                      .withOpacity(0.1)
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              // Position
                                              SizedBox(
                                                width: 50,
                                                child: Text(
                                                  '#${index + 1}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color:
                                                        isWinner
                                                            ? colorScheme
                                                                .tertiary
                                                            : isRunnerUp
                                                            ? colorScheme
                                                                .secondary
                                                            : isThird
                                                            ? colorScheme
                                                                .primaryContainer
                                                            : colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                  ),
                                                ),
                                              ),

                                              // Infos du joueur
                                              SizedBox(
                                                width: 240,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 44,
                                                      height: 44,
                                                      decoration: BoxDecoration(
                                                        color: player['color'],
                                                        shape: BoxShape.circle,
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        player['name']
                                                            .substring(0, 1)
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          player['name'],
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18,
                                                              ),
                                                        ),
                                                        if (isWinner)
                                                          const Text(
                                                            '🏆 Vainqueur!',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.amber,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Statistiques du joueur
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    // Score
                                                    Expanded(
                                                      child: Center(
                                                        child: Text(
                                                          '${player['score']}',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20,
                                                            color:
                                                                isWinner
                                                                    ? colorScheme
                                                                        .tertiary
                                                                    : colorScheme
                                                                        .onSurface,
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    // Bonnes réponses
                                                    Expanded(
                                                      child: Center(
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              '${player['correctAnswers']}/${player['totalQuestions']}',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18,
                                                                color:
                                                                    colorScheme
                                                                        .secondary,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${(player['correctAnswers'] / player['totalQuestions'] * 100).round()}%',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: colorScheme
                                                                    .onSurface
                                                                    .withOpacity(
                                                                      0.7,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    // Temps moyen
                                                    Expanded(
                                                      child: Center(
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.timer,
                                                              color:
                                                                  colorScheme
                                                                      .primary,
                                                              size: 20,
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Text(
                                                              '${player['responseTime']} sec',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    colorScheme
                                                                        .primary,
                                                              ),
                                                            ),
                                                          ],
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFancyPodium() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'PODIUM',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 24),

        // Plateforme du podium avec animation
        SizedBox(
          height: 380,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Secondes place
              Positioned(
                bottom: 40,
                left: 60,
                child: _buildPodiumPlace(
                  leaderboard[1],
                  2,
                  160,
                  colorScheme.secondary,
                ),
              ),

              // Premier place (au centre et plus haut)
              Positioned(
                bottom: 40,
                child: _buildPodiumPlace(
                  leaderboard[0],
                  1,
                  200,
                  colorScheme.tertiary,
                ),
              ),

              // Troisième place
              Positioned(
                bottom: 40,
                right: 60,
                child: _buildPodiumPlace(
                  leaderboard[2],
                  3,
                  120,
                  colorScheme.primaryContainer,
                ),
              ),

              // Socles du podium
              Positioned(
                bottom: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Socle 2e place
                    Container(
                      width: 120,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        border: Border(
                          top: BorderSide(
                            color: colorScheme.secondary,
                            width: 4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                    ),

                    // Socle 1ère place
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        border: Border(
                          top: BorderSide(
                            color: colorScheme.tertiary,
                            width: 4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                    ),

                    // Socle 3e place
                    Container(
                      width: 120,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        border: Border(
                          top: BorderSide(
                            color: colorScheme.primaryContainer,
                            width: 4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumPlace(
    Map<String, dynamic> player,
    int place,
    double height,
    Color medalColor,
  ) {
    String medal;
    String trophy;

    switch (place) {
      case 1:
        medal = '🥇';
        trophy = '🏆';
        break;
      case 2:
        medal = '🥈';
        trophy = '🎖️';
        break;
      default:
        medal = '🥉';
        trophy = '🏅';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Trophée animé
        FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Text(
              place == 1 ? '$trophy\n$medal' : medal,
              style: TextStyle(fontSize: place == 1 ? 48 : 36),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Avatar du joueur
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: medalColor, width: 3),
          ),
          child: CircleAvatar(
            radius: place == 1 ? 44 : 36,
            backgroundColor: player['color'],
            child: Text(
              player['name'].substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: place == 1 ? 24 : 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Nom du joueur
        Text(
          player['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: place == 1 ? 20 : 16,
          ),
        ),

        // Score
        Text(
          '${player['score']} pts',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: place == 1 ? 16 : 14,
            color: medalColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final winner = leaderboard.isNotEmpty ? leaderboard[0] : null;
    if (winner == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 20,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.tertiary, width: 2),
        ),
        color: colorScheme.surfaceVariant,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🏆 VAINQUEUR 🏆',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.tertiary, width: 4),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: winner['color'],
                  child: Text(
                    winner['name'].substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                winner['name'],
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Score: ${winner['score']} pts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${winner['correctAnswers']}/${winner['totalQuestions']} réponses correctes',
                style: TextStyle(
                  fontSize: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;

    // Sort by score
    leaderboard.sort((a, b) => b['score'].compareTo(a['score']));

    return Padding(
      padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      child: Column(
        children: [
          Text(
            '🏆 Classement final 🏆',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Top 3 podium
          if (leaderboard.length >= 3)
            SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd place
                  _buildSimplePodiumPlace(leaderboard[1], '2', 140),
                  const SizedBox(width: 8),

                  // 1st place
                  _buildSimplePodiumPlace(leaderboard[0], '1', 180),
                  const SizedBox(width: 8),

                  // 3rd place
                  _buildSimplePodiumPlace(leaderboard[2], '3', 120),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Full leaderboard
          Expanded(
            child: Card(
              elevation: 4,
              child: ListView.separated(
                itemCount: leaderboard.length,
                separatorBuilder:
                    (context, index) => Divider(
                      height: 1,
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                itemBuilder: (context, index) {
                  final player = leaderboard[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: player['color'],
                      child: Text(
                        player['name'].substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      player['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${player['correctAnswers']}/${player['totalQuestions']} réponses correctes',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${player['score']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: index == 0 ? colorScheme.tertiary : null,
                          ),
                        ),
                        const Text('points'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _logger.logInfo(
                      'Player selected "New Game" from results screen',
                      'ResultsScreen.newGame',
                    );
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.quizLobby,
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Nouvelle partie'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _logger.logInfo(
                      'Player selected "Home" from results screen',
                      'ResultsScreen.goHome',
                    );
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Accueil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.surfaceVariant,
                    foregroundColor: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimplePodiumPlace(
    Map<String, dynamic> player,
    String place,
    double height,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    String medal;
    Color medalColor;

    switch (place) {
      case '1':
        medal = '🥇';
        medalColor = colorScheme.tertiary;
        break;
      case '2':
        medal = '🥈';
        medalColor = colorScheme.secondary;
        break;
      default:
        medal = '🥉';
        medalColor = colorScheme.primaryContainer;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: player['color'],
          child: Text(
            player['name'].substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          player['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '${player['score']} pts',
          style: TextStyle(
            fontSize: 12,
            color: place == '1' ? colorScheme.tertiary : null,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: height - 100, // Adjust for avatar size
          decoration: BoxDecoration(
            color: medalColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          alignment: Alignment.center,
          child: Text(medal, style: const TextStyle(fontSize: 24)),
        ),
      ],
    );
  }
}
