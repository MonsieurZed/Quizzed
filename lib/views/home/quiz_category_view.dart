// filepath: d:\GIT\quizzzed\lib\views\home\quiz_category_view.dart
/// Vue des quiz par catégorie
///
/// Affiche la liste des quiz d'une catégorie spécifique
/// Permet de filtrer les quiz par difficulté et de les trier
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/models/quiz/quiz_model.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:quizzzed/services/quiz/quiz_service.dart';
import 'package:quizzzed/widgets/home/quiz_card.dart';

class QuizCategoryView extends StatefulWidget {
  final String category;

  const QuizCategoryView({super.key, required this.category});

  @override
  State<QuizCategoryView> createState() => _QuizCategoryViewState();
}

class _QuizCategoryViewState extends State<QuizCategoryView> {
  String? _selectedDifficulty;
  String _sortBy = 'popularity';
  bool _isDescending = true;
  List<QuizModel> _quizzes = [];
  bool _isLoading = true;
  final logTag = 'QuizCategoryView';
  final logger = LoggerService();
  final List<String> _difficulties = ['Facile', 'Intermédiaire', 'Difficile'];
  final Map<String, String> _sortOptions = {
    'popularity': 'Popularité',
    'createdAt': 'Date de création',
    'title': 'Titre',
  };

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });

    final quizService = Provider.of<QuizService>(context, listen: false);

    try {
      // Récupérer les quiz de la catégorie
      List<QuizModel> quizzes = await quizService.getAllQuizzes(
        category: widget.category,
        orderBy: _sortBy,
        descending: _isDescending,
      );

      // Filtrer par difficulté si nécessaire
      if (_selectedDifficulty != null) {
        quizzes =
            quizzes
                .where(
                  (quiz) =>
                      quiz.difficulty.toLowerCase() ==
                      _selectedDifficulty!.toLowerCase(),
                )
                .toList();
      }

      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _quizzes = [];
        logger.error(
          'Erreur lors du chargement des quiz: $e',
          tag: logTag,
          data: stackTrace,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des quiz: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onQuizTap(QuizModel quiz) {
    // Navigation vers la page de détails du quiz
    // TODO: Implémenter la navigation vers la page de détails du quiz
    logger.error('Quiz tapped: ${quiz.title}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz ${widget.category}'),
        actions: [
          IconButton(
            icon: Icon(
              _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            onPressed: () {
              setState(() {
                _isDescending = !_isDescending;
                _loadQuizzes();
              });
            },
            tooltip: _isDescending ? 'Décroissant' : 'Croissant',
          ),
          PopupMenuButton<String>(
            tooltip: 'Trier par',
            icon: const Icon(Icons.sort),
            onSelected: (String value) {
              setState(() {
                _sortBy = value;
                _loadQuizzes();
              });
            },
            itemBuilder: (BuildContext context) {
              return _sortOptions.entries
                  .map(
                    (entry) => PopupMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filtres
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text('Difficulté:', style: theme.textTheme.titleSmall),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Tous'),
                          selected: _selectedDifficulty == null,
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() {
                                _selectedDifficulty = null;
                                _loadQuizzes();
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ..._difficulties.map((difficulty) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(difficulty),
                              selected: _selectedDifficulty == difficulty,
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedDifficulty =
                                      selected ? difficulty : null;
                                  _loadQuizzes();
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste des quiz
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _quizzes.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 64,
                            color: theme.colorScheme.secondary.withAlpha(
                              (255 * 0.5).toInt(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun quiz trouvé',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Réessayez avec d\'autres filtres',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadQuizzes,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _quizzes.length,
                        itemBuilder: (context, index) {
                          final quiz = _quizzes[index];
                          return QuizCard(
                            quiz: quiz,
                            onTap: () => _onQuizTap(quiz),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
