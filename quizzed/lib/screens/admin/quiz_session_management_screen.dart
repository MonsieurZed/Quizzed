import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quizzed/models/player.dart';
import 'package:quizzed/models/question.dart';
import 'package:quizzed/models/quiz_session.dart';
import 'package:quizzed/repositories/quiz_repository.dart';
import 'package:quizzed/services/database_service.dart';
import 'package:quizzed/services/logging_service.dart';
import 'package:quizzed/services/theme_service.dart';

class QuizSessionManagementScreen extends StatefulWidget {
  final String sessionId;

  const QuizSessionManagementScreen({super.key, required this.sessionId});

  @override
  State<QuizSessionManagementScreen> createState() =>
      _QuizSessionManagementScreenState();
}

class _QuizSessionManagementScreenState
    extends State<QuizSessionManagementScreen> {
  final QuizRepository _quizRepository = QuizRepository();
  final DatabaseService _databaseService = DatabaseService();
  final LoggingService _logger = LoggingService();

  late Stream<QuizSession?> _sessionStream;
  late Stream<List<Question>> _questionsStream;
  late Stream<List<Player>> _playersStream;

  bool _isLoading = false;
  QuizSession? _session;
  List<Question> _questions = [];
  List<Player> _players = [];
  Question? _activeQuestion;
  Player? _selectedPlayer;

  // Pour le suivi de la progression
  int _currentQuestionIndex = -1;
  bool _isQuestionActive = false;
  int _remainingTime = 0;

  // Pour la gestion des points manuels
  final _pointsController = TextEditingController(text: '10');
  Set<String> _selectedPlayerIds = {};

  @override
  void initState() {
    super.initState();
    _logger.logInfo(
      'Initializing quiz session management screen for session: ${widget.sessionId}',
      'QuizSessionManagementScreen.initState',
    );
    _sessionStream = _quizRepository.getQuizSession(widget.sessionId);
    _questionsStream = _quizRepository.getSessionQuestions(widget.sessionId);
    _playersStream = _databaseService
        .getSessionPlayers(widget.sessionId)
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Player.fromFirestore(doc)).toList(),
        );

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _logger.logInfo(
        'Loading data for session: ${widget.sessionId}',
        'QuizSessionManagementScreen._loadData',
      );
      final sessionData = await _sessionStream.first;
      final questionsData = await _questionsStream.first;

      setState(() {
        _session = sessionData;
        _questions = questionsData;
      });
      _logger.logInfo(
        'Data loaded for session: ${widget.sessionId}, found ${questionsData.length} questions',
        'QuizSessionManagementScreen._loadData',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error loading data for session: ${widget.sessionId}',
        e,
        stackTrace,
        'QuizSessionManagementScreen._loadData',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  Future<void> _toggleSessionActive() async {
    if (_session == null) return;

    setState(() => _isLoading = true);

    try {
      _logger.logInfo(
        'Toggling session active state. Current state: ${_session!.isActive ? 'active' : 'inactive'}',
        'QuizSessionManagementScreen._toggleSessionActive',
      );
      final updatedSession = QuizSession(
        id: _session!.id,
        title: _session!.title,
        description: _session!.description,
        createdAt: _session!.createdAt,
        isActive: !_session!.isActive,
        validationThreshold: _session!.validationThreshold,
      );

      await _quizRepository.updateQuizSession(_session!.id!, updatedSession);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Session ${_session!.isActive ? 'paused' : 'activated'}',
          ),
        ),
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error updating data for session: ${widget.sessionId}',
        e,
        stackTrace,
        'QuizSessionManagementScreen._toggleSessionActive',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating session: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setActiveQuestion(Question question) {
    setState(() {
      _activeQuestion = question;
      _currentQuestionIndex = _questions.indexOf(question);
    });

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Question Control'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.questionText),
                const SizedBox(height: 8),
                Text('Type: ${_getQuestionTypeLabel(question.type)}'),
                Text(
                  'Difficulty: ${_getQuestionDifficultyLabel(question.difficulty)}',
                ),
                Text('Points: ${question.points}'),
                Text('Time limit: ${question.timeLimit} seconds'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.qcm:
        return 'Multiple Choice';
      case QuestionType.image:
        return 'Image';
      case QuestionType.sound:
        return 'Sound';
      case QuestionType.video:
        return 'Video';
      case QuestionType.open:
        return 'Open-ended';
    }
  }

  String _getQuestionDifficultyLabel(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }

  Future<void> _awardPointsToSelectedPlayers() async {
    if (_selectedPlayerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one player')),
      );
      return;
    }

    try {
      int points = int.parse(_pointsController.text.trim());

      if (points <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Points must be a positive number')),
        );
        return;
      }

      setState(() => _isLoading = true);

      await _databaseService.awardPointsToPlayers(
        _selectedPlayerIds.toList(),
        points,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Awarded $points points to ${_selectedPlayerIds.length} players',
          ),
        ),
      );

      setState(() => _selectedPlayerIds = {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error awarding points: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Détecter si l'écran est au format PC
    final screenSize = MediaQuery.of(context).size;
    final ratio = screenSize.width / screenSize.height;
    final isDesktop = ratio >= 1.6 && screenSize.width > 1200;

    return Scaffold(
      appBar:
          isDesktop
              ? null
              : AppBar(title: Text(_session?.title ?? 'Session Management')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuizSession?>(
                stream: _sessionStream,
                builder: (context, sessionSnapshot) {
                  if (sessionSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      _session == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final session = sessionSnapshot.data ?? _session;

                  if (session == null) {
                    return const Center(child: Text('Session not found'));
                  }

                  return isDesktop
                      ? _buildDesktopLayout(session)
                      : _buildMobileLayout(session);
                },
              ),
    );
  }

  Widget _buildDesktopLayout(QuizSession session) {
    return Column(
      children: [
        // En-tête de la session avec titre et contrôles principaux
        _buildDesktopHeader(session),

        // Zone principale divisée en trois colonnes
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panneau de gauche : Questions
              Expanded(flex: 3, child: _buildQuestionsPanel()),

              // Panneau central : Question active et contrôles
              Expanded(flex: 5, child: _buildActiveQuestionPanel(session)),

              // Panneau de droite : Joueurs et classement
              Expanded(flex: 3, child: _buildPlayersPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(QuizSession session) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Titre et icône de la session
          Icon(Icons.quiz, size: 30, color: colorScheme.primary),
          const SizedBox(width: 16),
          Text(
            session.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const Spacer(),

          // Statut de la session avec indicateur
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  session.isActive
                      ? colorScheme.tertiary.withOpacity(0.1)
                      : colorScheme.outline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        session.isActive
                            ? colorScheme.tertiary
                            : colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  session.isActive ? 'Session Active' : 'Session Inactive',
                  style: TextStyle(
                    color:
                        session.isActive
                            ? colorScheme.tertiary
                            : colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Bouton de contrôle principal
          ElevatedButton.icon(
            onPressed: _toggleSessionActive,
            icon: Icon(session.isActive ? Icons.pause : Icons.play_arrow),
            label: Text(
              session.isActive ? 'Mettre en pause' : 'Activer la session',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  session.isActive
                      ? colorScheme.errorContainer
                      : colorScheme.tertiary,
              foregroundColor:
                  session.isActive
                      ? colorScheme.onErrorContainer
                      : colorScheme.onTertiary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(width: 8),

          // Menu d'options
          PopupMenuButton<String>(
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Modifier la session'),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Text('Exporter les résultats'),
                  ),
                  const PopupMenuItem(
                    value: 'close',
                    child: Text('Fermer la session'),
                  ),
                ],
            onSelected: (value) {
              // Logique pour gérer les options du menu
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsPanel() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du panneau
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Questions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_questions.length} questions',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Liste des questions
          Expanded(
            child: StreamBuilder<List<Question>>(
              stream: _questionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _questions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final questions = snapshot.data ?? _questions;

                if (questions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.help_outline,
                          size: 48,
                          color: colorScheme.surfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune question disponible',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    final isActive = _activeQuestion?.id == question.id;
                    final isPlayed = index < _currentQuestionIndex;
                    final isCurrent = index == _currentQuestionIndex;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color:
                              isActive
                                  ? Theme.of(context).primaryColor
                                  : isPlayed
                                  ? Colors.grey.shade300
                                  : Colors.transparent,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      color:
                          isActive
                              ? Theme.of(context).primaryColor.withOpacity(0.05)
                              : isCurrent
                              ? Colors.blue.shade50
                              : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isPlayed
                                  ? Colors.grey
                                  : isCurrent
                                  ? Colors.blue
                                  : Theme.of(context).primaryColor,
                          child:
                              isPlayed
                                  ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                  : Text(
                                    (index + 1).toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                        title: Text(
                          question.questionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            _buildQuestionTypeChip(question.type),
                            const SizedBox(width: 6),
                            Text('${question.points} pts'),
                          ],
                        ),
                        onTap: () => _setActiveQuestion(question),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuestionPanel(QuizSession session) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre du panneau
          const Text(
            'Question active',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Carte de la question active ou message d'information
          Expanded(
            child:
                _activeQuestion != null
                    ? _buildActiveQuestionCard()
                    : _buildNoActiveQuestionMessage(),
          ),

          const SizedBox(height: 16),

          // Contrôles de navigation entre questions
          _buildQuestionNavigationControls(),
        ],
      ),
    );
  }

  Widget _buildActiveQuestionCard() {
    final question = _activeQuestion!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec type et difficulté
            Row(
              children: [
                _buildQuestionTypeChip(question.type),
                const SizedBox(width: 12),
                _buildDifficultyChip(question.difficulty),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isQuestionActive
                            ? colorScheme.tertiary.withOpacity(0.1)
                            : colorScheme.outline.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _isQuestionActive
                                  ? colorScheme.tertiary
                                  : colorScheme.outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isQuestionActive ? 'Active' : 'En attente',
                        style: TextStyle(
                          color:
                              _isQuestionActive
                                  ? colorScheme.tertiary
                                  : colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Texte de la question
            Text(
              question.questionText,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            // Afficher les choix si c'est une question à choix multiples
            if (question.type == QuestionType.qcm && question.choices != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Options:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: question.choices!.length,
                        itemBuilder: (context, index) {
                          final choice = question.choices![index];
                          final isCorrect = question.correctAnswer == index;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            color:
                                isCorrect
                                    ? colorScheme.tertiaryContainer.withOpacity(
                                      0.5,
                                    )
                                    : colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color:
                                    isCorrect
                                        ? colorScheme.tertiary
                                        : colorScheme.outline.withOpacity(0.3),
                                width: isCorrect ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          isCorrect
                                              ? colorScheme.tertiary
                                              : colorScheme.surfaceVariant,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      String.fromCharCode(
                                        65 + index,
                                      ), // A, B, C, D...
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isCorrect
                                                ? colorScheme.onTertiary
                                                : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(choice)),
                                  if (isCorrect)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: colorScheme.tertiary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Réponse correcte',
                                          style: TextStyle(
                                            color: colorScheme.tertiary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
              )
            else
              const Expanded(
                child: Center(
                  child: Text('Cette question nécessite une réponse libre'),
                ),
              ),

            // Ligne d'informations supplémentaires
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    icon: Icons.timer,
                    label: 'Temps',
                    value: '${question.timeLimit} sec',
                  ),
                  _buildInfoItem(
                    icon: Icons.star,
                    label: 'Points',
                    value: '${question.points}',
                  ),
                  _buildInfoItem(
                    icon: Icons.people,
                    label: 'Réponses',
                    value:
                        '0/${_players.length}', // À remplacer par des données réelles
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Boutons de contrôle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Logique pour lancer/arrêter la question
                      setState(() {
                        _isQuestionActive = !_isQuestionActive;
                        if (_isQuestionActive) {
                          _currentQuestionIndex = _questions.indexOf(
                            _activeQuestion!,
                          );
                          _remainingTime = question.timeLimit;
                          // Démarrer le timer ici
                        }
                      });
                    },
                    icon: Icon(
                      _isQuestionActive ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(
                      _isQuestionActive ? 'Terminer' : 'Lancer la question',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isQuestionActive
                              ? colorScheme.errorContainer
                              : colorScheme.tertiary,
                      foregroundColor:
                          _isQuestionActive
                              ? colorScheme.onErrorContainer
                              : colorScheme.onTertiary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Bouton pour révéler la réponse
                if (!_isQuestionActive)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Logique pour révéler la réponse
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Révéler la réponse'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveQuestionMessage() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline, size: 80, color: colorScheme.surfaceVariant),
          const SizedBox(height: 24),
          Text(
            'Aucune question active',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sélectionnez une question dans la liste pour commencer',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Sélectionner automatiquement la première question
              if (_questions.isNotEmpty) {
                _setActiveQuestion(_questions[0]);
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Commencer avec la première question'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigationControls() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed:
              _currentQuestionIndex > 0
                  ? () {
                    if (_questions.isNotEmpty && _currentQuestionIndex > 0) {
                      _setActiveQuestion(_questions[_currentQuestionIndex - 1]);
                      setState(() {
                        _currentQuestionIndex--;
                        _isQuestionActive = false;
                      });
                    }
                  }
                  : null,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Question précédente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceVariant,
            foregroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed:
              _currentQuestionIndex < _questions.length - 1
                  ? () {
                    if (_questions.isNotEmpty &&
                        _currentQuestionIndex < _questions.length - 1) {
                      _setActiveQuestion(_questions[_currentQuestionIndex + 1]);
                      setState(() {
                        _currentQuestionIndex++;
                        _isQuestionActive = false;
                      });
                    }
                  }
                  : null,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Question suivante'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceVariant,
            foregroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersPanel() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du panneau
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Joueurs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                StreamBuilder<List<Player>>(
                  stream: _playersStream,
                  builder: (context, snapshot) {
                    final playerCount =
                        snapshot.data?.length ?? _players.length;
                    return Badge(
                      label: Text('$playerCount'),
                      child: const Icon(Icons.people),
                    );
                  },
                ),
              ],
            ),
          ),

          // Zone d'attribution de points
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              color: colorScheme.secondaryContainer.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: colorScheme.secondary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_circle, color: colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'Attribution de points',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pointsController,
                            decoration: const InputDecoration(
                              labelText: 'Points',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _awardPointsToSelectedPlayers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Attribuer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Joueurs sélectionnés: ${_selectedPlayerIds.length}',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Recherche de joueurs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un joueur...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Liste des joueurs
          Expanded(
            child: StreamBuilder<List<Player>>(
              stream: _playersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _players.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final players = snapshot.data ?? _players;

                // Triez les joueurs par score
                final sortedPlayers = List<Player>.from(players)
                  ..sort((a, b) => b.score.compareTo(a.score));

                if (players.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 48,
                          color: colorScheme.surfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun joueur connecté',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedPlayers.length,
                  itemBuilder: (context, index) {
                    final player = sortedPlayers[index];
                    final isSelected = _selectedPlayerIds.contains(player.id);
                    final isDetailSelected = _selectedPlayer?.id == player.id;

                    // Calculer la médaille pour le top 3
                    Widget? medal;
                    if (index == 0) {
                      medal = const Text('🥇', style: TextStyle(fontSize: 20));
                    } else if (index == 1) {
                      medal = const Text('🥈', style: TextStyle(fontSize: 20));
                    } else if (index == 2) {
                      medal = const Text('🥉', style: TextStyle(fontSize: 20));
                    }

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color:
                              isDetailSelected
                                  ? colorScheme.primary
                                  : isSelected
                                  ? colorScheme.secondary
                                  : Colors.transparent,
                          width: isDetailSelected || isSelected ? 2 : 0,
                        ),
                      ),
                      color:
                          isDetailSelected
                              ? colorScheme.primary.withOpacity(0.05)
                              : isSelected
                              ? colorScheme.secondary.withOpacity(0.05)
                              : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedPlayerIds.add(player.id);
                              } else {
                                _selectedPlayerIds.remove(player.id);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              Text(
                                player.nickname,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (medal != null) ...[
                                const SizedBox(width: 4),
                                medal,
                              ],
                            ],
                          ),
                          subtitle: Text('Score: ${player.score} pts'),
                          secondary: CircleAvatar(
                            backgroundImage:
                                player.avatarUrl != null
                                    ? NetworkImage(player.avatarUrl!)
                                    : null,
                            child:
                                player.avatarUrl == null
                                    ? Text(player.nickname[0].toUpperCase())
                                    : null,
                          ),
                          dense: true,
                          activeColor: colorScheme.secondary,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildQuestionTypeChip(QuestionType type) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    IconData icon;
    String label;

    switch (type) {
      case QuestionType.qcm:
        color = colorScheme.primary;
        icon = Icons.quiz;
        label = 'QCM';
        break;
      case QuestionType.image:
        color = colorScheme.tertiary;
        icon = Icons.image;
        label = 'Image';
        break;
      case QuestionType.sound:
        color = colorScheme.secondary;
        icon = Icons.music_note;
        label = 'Son';
        break;
      case QuestionType.video:
        color = colorScheme.error;
        icon = Icons.videocam;
        label = 'Vidéo';
        break;
      case QuestionType.open:
        color = colorScheme.errorContainer;
        icon = Icons.text_fields;
        label = 'Texte';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(QuestionDifficulty difficulty) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    String label;

    switch (difficulty) {
      case QuestionDifficulty.easy:
        color = colorScheme.tertiary;
        label = 'Facile';
        break;
      case QuestionDifficulty.medium:
        color = colorScheme.errorContainer;
        label = 'Moyen';
        break;
      case QuestionDifficulty.hard:
        color = colorScheme.error;
        label = 'Difficile';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMobileLayout(QuizSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSessionControls(session),
        const SizedBox(height: 16),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TabBar(
                  tabs: [Tab(text: 'Questions'), Tab(text: 'Players')],
                ),
                Expanded(
                  child: TabBarView(
                    children: [_buildQuestionsTab(), _buildPlayersTab()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionControls(QuizSession session) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        session.isActive
                            ? colorScheme.tertiary
                            : colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  session.isActive ? 'Active' : 'Inactive',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _toggleSessionActive,
                  icon: Icon(session.isActive ? Icons.pause : Icons.play_arrow),
                  label: Text(
                    session.isActive ? 'Pause Session' : 'Activate Session',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        session.isActive
                            ? colorScheme.errorContainer
                            : colorScheme.tertiary,
                    foregroundColor:
                        session.isActive
                            ? colorScheme.onErrorContainer
                            : colorScheme.onTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Validation threshold: ${session.validationThreshold}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsTab() {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<Question>>(
      stream: _questionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _questions.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        final questions = snapshot.data ?? _questions;

        return Padding(
          padding: const EdgeInsets.all(16),
          child:
              questions.isEmpty
                  ? Center(
                    child: Text(
                      'No questions in this session',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                  : ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      final isActive = _activeQuestion?.id == question.id;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isActive ? colorScheme.primaryContainer : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            child: Text((index + 1).toString()),
                          ),
                          title: Text(question.questionText),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_getQuestionTypeLabel(question.type)),
                              Text(
                                'Difficulty: ${_getQuestionDifficultyLabel(question.difficulty)}',
                              ),
                              Text('Points: ${question.points}'),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          onTap: () => _setActiveQuestion(question),
                        ),
                      );
                    },
                  ),
        );
      },
    );
  }

  Widget _buildPlayersTab() {
    return StreamBuilder<List<Player>>(
      stream: _playersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _players.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final players = snapshot.data ?? _players;

        if (players.isEmpty) {
          return const Center(child: Text('No players have joined yet'));
        }

        return Column(
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Award Points',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pointsController,
                            decoration: const InputDecoration(
                              labelText: 'Points',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _awardPointsToSelectedPlayers,
                          child: const Text('Award Points'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selected players: ${_selectedPlayerIds.length}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  final isSelected = _selectedPlayerIds.contains(player.id);

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedPlayerIds.add(player.id);
                          } else {
                            _selectedPlayerIds.remove(player.id);
                          }
                        });
                      },
                      title: Text(player.nickname),
                      subtitle: Text('Score: ${player.score} points'),
                      secondary: CircleAvatar(
                        backgroundImage:
                            player.avatarUrl != null
                                ? NetworkImage(player.avatarUrl!)
                                : null,
                        child:
                            player.avatarUrl == null
                                ? Text(player.nickname[0].toUpperCase())
                                : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
