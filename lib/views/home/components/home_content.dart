/// Vue du contenu principal de la page d'accueil
///
/// Affiche les statistiques de l'utilisateur, les catégories de quiz et les quiz populaires
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/models/quiz/quiz_model.dart';
import 'package:quizzzed/models/user/user_model.dart';
import 'package:quizzzed/routes/app_routes.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:quizzzed/services/quiz/game_service.dart';
import 'package:quizzzed/widgets/home/quiz_category_card.dart';
import 'package:quizzzed/widgets/home/recent_activity_card.dart';
import 'package:quizzzed/widgets/home/stats_card.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<String> _categories = [];
  List<QuizModel> _popularQuizzes = [];
  bool _isLoadingCategories = true;
  bool _isLoadingQuizzes = true;
  final logTag = 'HomeContent';
  final logger = LoggerService();

  @override
  void initState() {
    super.initState();
    // Nous reportons le chargement après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
      _loadPopularQuizzes();
    });
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final quizService = Provider.of<GameService>(context, listen: false);
      final categories = await quizService.getCategories();

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
      logger.error(
        'Erreur lors du chargement des catégories: $e',
        tag: logTag,
        data: stackTrace,
      );
    }
  }

  Future<void> _loadPopularQuizzes() async {
    if (!mounted) return;

    setState(() {
      _isLoadingQuizzes = true;
    });

    try {
      final quizService = Provider.of<GameService>(context, listen: false);
      final quizzes = await quizService.getPopularQuizzes(limit: 5);

      if (mounted) {
        setState(() {
          _popularQuizzes = quizzes;
          _isLoadingQuizzes = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoadingQuizzes = false;
        });
      }
      logger.error(
        'Erreur lors du chargement des quiz populaires: $e',
        tag: logTag,
        data: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final UserModel? user = authService.currentUserModel;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_loadCategories(), _loadPopularQuizzes()]);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de bienvenue
            Text(
              'Bonjour, ${user?.displayName ?? 'utilisateur'} 👋',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Que souhaitez-vous apprendre aujourd\'hui ?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((255 * 0.7).toInt()),
              ),
            ),
            const SizedBox(height: 24),

            // Section: Statistiques personnelles
            StatsCard(
              score: user?.score ?? 0,
              quizCompleted: user?.quizHistory.length ?? 0,
            ),
            const SizedBox(height: 24),

            // Section: Catégories de quiz
            _buildSectionHeader(context, 'Catégories de Quiz', () {
              // Navigation vers toutes les catégories
              context.pushNamed(AppRoutes.quizCategories);
            }),
            const SizedBox(height: 12),
            _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                ? const Center(child: Text('Aucune catégorie disponible'))
                : SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length > 5 ? 5 : _categories.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == _categories.length - 1 ? 0 : 8.0,
                        ),
                        child: QuizCategoryCard(
                          category: _categories[index],
                          onTap: () {
                            context.pushNamed(
                              AppRoutes.quizCategoryDetail,
                              pathParameters: {'category': _categories[index]},
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            const SizedBox(height: 24),

            // Section: Quiz populaires
            _buildSectionHeader(context, 'Quiz Populaires', () {
              // Navigation vers les quiz populaires
              // Pour l'instant, redirigez vers les catégories
              context.pushNamed(AppRoutes.quizCategories);
            }),
            const SizedBox(height: 12),
            _isLoadingQuizzes
                ? const Center(child: CircularProgressIndicator())
                : _popularQuizzes.isEmpty
                ? const Center(child: Text('Aucun quiz disponible'))
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      _popularQuizzes.length > 3 ? 3 : _popularQuizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _popularQuizzes[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _popularQuizzes.length - 1 ? 0 : 12.0,
                      ),
                      child: RecentActivityCard(
                        title: quiz.title,
                        category: quiz.category,
                        participants: quiz.questionCount,
                        difficulty:
                            quiz.difficulty == 'Facile'
                                ? 1
                                : quiz.difficulty == 'Intermédiaire'
                                ? 2
                                : 3,
                        onTap: () {
                          // TODO: Navigation vers la page de détails du quiz
                          logger.debug(
                            'Quiz tapped: ${quiz.title}',
                            tag: logTag,
                          );
                        },
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  // Construction d'un en-tête de section avec bouton "Voir tout"
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onSeeAll,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('Voir tout')),
      ],
    );
  }
}
