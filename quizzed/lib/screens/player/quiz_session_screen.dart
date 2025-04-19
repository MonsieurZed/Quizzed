import 'package:flutter/material.dart';
import 'package:quizzed/routes/app_routes.dart';
import 'package:quizzed/services/logging_service.dart';

class QuizSessionScreen extends StatefulWidget {
  const QuizSessionScreen({super.key});

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  final LoggingService _logger = LoggingService();

  // Mock question data for the UI demo
  final Map<String, dynamic> _currentQuestion = {
    'question': 'Quelle est la capitale de la France?',
    'type': 'qcm',
    'choices': ['Paris', 'Londres', 'Berlin', 'Madrid'],
    'correct': 0,
    'difficulty': 'facile',
    'timer': 30,
    'image': null, // Simuler une question sans image
    'points': 100,
  };

  int? _selectedAnswer;
  bool _hasAnswered = false;
  int _timer = 30;
  final int _totalQuestions = 10;
  final int _currentQuestionIndex = 1;
  int _score = 0;

  // Liste des joueurs dans la session avec leur score
  final List<Map<String, dynamic>> _players = [
    {
      'name': 'Alice',
      'avatar': 'amazone',
      'color': const Color(0xFFFF39FF),
      'score': 250,
    },
    {
      'name': 'Bob',
      'avatar': 'pirate',
      'color': const Color(0xFF39FFFF),
      'score': 180,
    },
    {
      'name': 'Charlie',
      'avatar': 'ninja',
      'color': const Color(0xFF39FF14),
      'score': 150,
    },
    {
      'name': 'Joueur',
      'avatar': 'chevalier',
      'color': const Color(0xFFFFFF39),
      'score': 100,
    },
  ];

  @override
  void initState() {
    super.initState();
    _logger.logInfo(
      'Quiz session screen initialized - Question $_currentQuestionIndex/$_totalQuestions',
      'QuizSessionScreen.initState',
    );
    _startTimer();
  }

  @override
  void dispose() {
    _logger.logInfo(
      'Quiz session screen disposed',
      'QuizSessionScreen.dispose',
    );
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_hasAnswered && _timer > 0) {
        setState(() {
          _timer--;
        });
        _startTimer();
      } else if (_timer == 0 && !_hasAnswered) {
        _logger.logInfo(
          'Question time expired - Question $_currentQuestionIndex/$_totalQuestions',
          'QuizSessionScreen._startTimer',
        );
        _submitAnswer(null);
      }
    });
  }

  void _submitAnswer(int? answer) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
    });

    if (answer == null) {
      _logger.logInfo(
        'Player did not answer in time - Question $_currentQuestionIndex/$_totalQuestions',
        'QuizSessionScreen._submitAnswer',
      );
    } else {
      final isCorrect = answer == _currentQuestion['correct'];
      _logger.logInfo(
        'Player submitted answer: $answer, Correct: $isCorrect - Question $_currentQuestionIndex/$_totalQuestions',
        'QuizSessionScreen._submitAnswer',
      );
    }

    // In a real app, this would send the answer to Firebase
    // For now, we just wait 2 seconds and then go to the next question or results
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentQuestionIndex == _totalQuestions) {
        _logger.logInfo(
          'Quiz completed - Navigating to results screen',
          'QuizSessionScreen._submitAnswer',
        );
        Navigator.pushReplacementNamed(context, AppRoutes.results);
      } else {
        _logger.logInfo(
          'Advancing to next question - Question ${_currentQuestionIndex + 1}/$_totalQuestions',
          'QuizSessionScreen._submitAnswer',
        );
        // Pour la démo, ajoutons des points si la réponse est correcte
        if (answer == _currentQuestion['correct']) {
          final timeBonus =
              (_timer / 30 * 50).round(); // Bonus pour réponse rapide
          final earnedPoints = _currentQuestion['points'] + timeBonus;

          setState(() {
            _score += earnedPoints as int;
            // Mettre à jour le score du joueur actuel dans la liste
            final currentPlayerIndex = _players.indexWhere(
              (p) => p['name'] == 'Joueur',
            );
            if (currentPlayerIndex >= 0) {
              _players[currentPlayerIndex]['score'] = _score;
            }

            // Trier les joueurs par score
            _players.sort(
              (a, b) => (b['score'] as int).compareTo(a['score'] as int),
            );
          });
        }

        setState(() {
          _selectedAnswer = null;
          _hasAnswered = false;
          _timer = 30;
        });

        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Taille de l'écran pour adapter l'interface
    final screenSize = MediaQuery.of(context).size;
    final ratio = screenSize.width / screenSize.height;

    // Optimisé pour les grands écrans de PC (ratio proche de 16:9 ~ 1.77)
    final isDesktop = ratio >= 1.6 && screenSize.width > 1200;

    return Scaffold(
      appBar:
          isDesktop
              ? null
              : AppBar(
                title: Text('Question $_currentQuestionIndex/$_totalQuestions'),
                automaticallyImplyLeading: false,
              ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Fond avec gradient
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
        Column(
          children: [
            // Barre supérieure avec progression et score
            _buildDesktopHeader(),

            // Zone principale avec question et réponses
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panneau de gauche avec classement des joueurs
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.05),
                      border: Border(
                        right: BorderSide(
                          color: colorScheme.outline.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: _buildLeaderboard(),
                  ),

                  // Zone centrale avec la question et les réponses
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Carte de question
                          _buildDesktopQuestionCard(),
                          const SizedBox(height: 32),

                          // Réponses
                          Expanded(
                            child:
                                _currentQuestion['type'] == 'qcm'
                                    ? _buildDesktopMultipleChoiceAnswers()
                                    : _buildDesktopOpenEndedAnswer(),
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
      ],
    );
  }

  Widget _buildDesktopHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo et titre du quiz
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

          // Progression du quiz
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Question $_currentQuestionIndex/$_totalQuestions',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _currentQuestionIndex / _totalQuestions,
                  backgroundColor: colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                  minHeight: 8,
                ),
              ),
              SizedBox(width: 200),
            ],
          ),

          // Timer et difficulté
          Row(
            children: [
              // Difficulté
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      _currentQuestion['difficulty'] == 'facile'
                          ? colorScheme.tertiary
                          : _currentQuestion['difficulty'] == 'moyen'
                          ? colorScheme.error
                          : colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _currentQuestion['difficulty'].toUpperCase(),
                  style: TextStyle(
                    color:
                        _currentQuestion['difficulty'] == 'facile'
                            ? colorScheme.onTertiary
                            : colorScheme.onError,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Timer avec animation
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: _timer / 30,
                      backgroundColor: colorScheme.surfaceVariant.withOpacity(
                        0.3,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _timer < 10 ? colorScheme.error : colorScheme.secondary,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  Text(
                    '$_timer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color:
                          _timer < 10
                              ? colorScheme.error
                              : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CLASSEMENT',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // Tableau des scores
        Expanded(
          child: ListView.separated(
            itemCount: _players.length,
            separatorBuilder:
                (context, index) => Divider(
                  color: colorScheme.outline.withOpacity(0.2),
                  height: 16,
                ),
            itemBuilder: (context, index) {
              final player = _players[index];
              final isCurrentPlayer = player['name'] == 'Joueur';

              return Container(
                decoration:
                    isCurrentPlayer
                        ? BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        )
                        : null,
                padding:
                    isCurrentPlayer
                        ? const EdgeInsets.all(8)
                        : const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Position dans le classement
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color:
                            index == 0
                                ? colorScheme
                                    .tertiary // Or
                                : index == 1
                                ? colorScheme
                                    .secondary // Argent
                                : index == 2
                                ? colorScheme
                                    .primaryContainer // Bronze
                                : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              index <= 2
                                  ? colorScheme.onTertiary
                                  : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Nom du joueur
                    Expanded(
                      child: Text(
                        player['name'],
                        style: TextStyle(
                          fontWeight:
                              isCurrentPlayer
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              isCurrentPlayer
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                        ),
                      ),
                    ),

                    // Score du joueur
                    Text(
                      '${player['score']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Points potentiels pour la question actuelle
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Points de la question',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Base:'),
                  Text(
                    '${_currentQuestion['points']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bonus temps:'),
                  Text(
                    '+${(_timer / 30 * 50).round()}',
                    style: TextStyle(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(color: colorScheme.outline.withOpacity(0.2)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_currentQuestion['points'] + (_timer / 30 * 50).round()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopQuestionCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Question:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Texte de la question
            Text(
              _currentQuestion['question'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            // Si la question a une image ou un média
            if (_currentQuestion['image'] != null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Center(child: Text('Image de question ici')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopMultipleChoiceAnswers() {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: (_currentQuestion['choices'] as List).length,
      itemBuilder: (context, index) {
        final choice = _currentQuestion['choices'][index];
        final bool isSelected = _selectedAnswer == index;
        final bool isCorrect =
            _hasAnswered && index == _currentQuestion['correct'];
        final bool isWrong =
            _hasAnswered && isSelected && index != _currentQuestion['correct'];

        Color cardColor = colorScheme.surface;
        if (isSelected) {
          cardColor =
              isWrong
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer;
        }
        if (isCorrect && _hasAnswered) {
          cardColor = colorScheme.tertiaryContainer;
        }

        return Card(
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  isSelected
                      ? (isWrong ? colorScheme.error : colorScheme.primary)
                      : (isCorrect && _hasAnswered)
                      ? colorScheme.tertiary
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: _hasAnswered ? null : () => _submitAnswer(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  // Index de réponse (A, B, C, D)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? (isWrong
                                  ? colorScheme.error
                                  : colorScheme.primary)
                              : (isCorrect && _hasAnswered)
                              ? colorScheme.tertiary
                              : colorScheme.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D...
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected || (isCorrect && _hasAnswered)
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Texte de la réponse
                  Expanded(
                    child: Text(
                      choice,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            isSelected || isCorrect
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ),

                  // Icône de résultat
                  if (_hasAnswered)
                    Icon(
                      isCorrect
                          ? Icons.check_circle
                          : isWrong
                          ? Icons.cancel
                          : null,
                      color:
                          isCorrect
                              ? colorScheme.tertiary
                              : (isWrong ? colorScheme.error : null),
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopOpenEndedAnswer() {
    final TextEditingController controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Votre réponse:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Zone de texte pour la réponse
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Tapez votre réponse ici...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          enabled: !_hasAnswered,
          maxLines: 5,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),

        // Bouton de soumission
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _hasAnswered ? null : () => _submitAnswer(0),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Soumettre ma réponse',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // Pour les appareils non-desktop
  Widget _buildMobileLayout() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer and difficulty section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer, color: colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text(
                    'Temps: $_timer s',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      _currentQuestion['difficulty'] == 'facile'
                          ? colorScheme.tertiary
                          : _currentQuestion['difficulty'] == 'moyen'
                          ? colorScheme.error
                          : colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _currentQuestion['difficulty'],
                  style: TextStyle(
                    color:
                        _currentQuestion['difficulty'] == 'facile'
                            ? colorScheme.onTertiary
                            : colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question text
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentQuestion['question'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Here we would display media if question has any
                  if (_currentQuestion['image'] != null)
                    const SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Center(child: Text('Media would appear here')),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Answer section
          Expanded(
            child:
                _currentQuestion['type'] == 'qcm'
                    ? _buildMultipleChoiceAnswers()
                    : _buildOpenEndedAnswer(),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceAnswers() {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      itemCount: (_currentQuestion['choices'] as List).length,
      itemBuilder: (context, index) {
        final choice = _currentQuestion['choices'][index];
        final bool isSelected = _selectedAnswer == index;
        final bool isCorrect =
            _hasAnswered && index == _currentQuestion['correct'];
        final bool isWrong =
            _hasAnswered && isSelected && index != _currentQuestion['correct'];

        Color cardColor = colorScheme.surface;
        if (isSelected) {
          cardColor =
              isWrong
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer;
        }
        if (isCorrect && _hasAnswered) {
          cardColor = colorScheme.tertiaryContainer;
        }

        return Card(
          color: cardColor,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              choice,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    isSelected || isCorrect
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
            trailing:
                _hasAnswered
                    ? Icon(
                      isCorrect
                          ? Icons.check_circle
                          : isWrong
                          ? Icons.cancel
                          : null,
                      color:
                          isCorrect
                              ? colorScheme.tertiary
                              : isWrong
                              ? colorScheme.error
                              : null,
                    )
                    : Icon(
                      index == _selectedAnswer
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color:
                          index == _selectedAnswer ? colorScheme.primary : null,
                    ),
            onTap: _hasAnswered ? null : () => _submitAnswer(index),
          ),
        );
      },
    );
  }

  Widget _buildOpenEndedAnswer() {
    final TextEditingController controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Votre réponse:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Tapez votre réponse ici...',
            border: OutlineInputBorder(),
          ),
          enabled: !_hasAnswered,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed:
              _hasAnswered
                  ? null
                  : () {
                    // In a real app, this would send the text response to Firebase
                    _submitAnswer(0);
                  },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            'Soumettre ma réponse',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
