/// Vue principale de l'accueil
///
/// Page d'accueil affichée après l'authentification
/// Contient les différentes sections et fonctionnalités principales
/// Utilise un menu latéral à gauche pour la navigation

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/models/quiz/quiz_model.dart';
import 'package:quizzzed/models/user/user_model.dart';
import 'package:quizzzed/routes/app_routes.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:quizzzed/services/quiz/quiz_service.dart';
import 'package:quizzzed/widgets/auth/auth_button.dart';
import 'package:quizzzed/widgets/auth/auth_text_field.dart';
import 'package:quizzzed/widgets/home/quiz_category_card.dart';
import 'package:quizzzed/widgets/home/recent_activity_card.dart';
import 'package:quizzzed/widgets/home/stats_card.dart';
import 'package:quizzzed/widgets/profile/avatar_preview.dart';
import 'package:quizzzed/widgets/profile/avatar_selector.dart';
import 'package:quizzzed/widgets/profile/color_selector.dart';
import 'package:quizzzed/controllers/lobby_controller.dart';
import 'package:quizzzed/views/home/lobbies_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  List<String> _categories = [];
  List<QuizModel> _popularQuizzes = [];
  bool _isLoadingCategories = true;
  bool _isLoadingQuizzes = true;
  bool _isDrawerExpanded = true; // État d'expansion du menu latéral
  bool _isProfileExpanded = false; // État d'expansion de la section profil
  final logTag = 'HomeView';
  final logger = LoggerService();

  // Controllers pour l'édition du profil
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedAvatar;
  String? _selectedColor;
  String? _errorMessage;

  bool _isPasswordChangeVisible = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadPopularQuizzes();
    _initUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Initialisation des données utilisateur pour l'édition du profil
  void _initUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;

    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      _selectedAvatar = user.photoUrl;
      _selectedColor = user.avatarBackgroundColor;

      logger.debug(
        'Profil utilisateur chargé: ${user.displayName}',
        tag: logTag,
      );
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final quizService = Provider.of<QuizService>(context, listen: false);
      final categories = await quizService.getCategories();

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoadingCategories = false;
      });
      logger.error(
        'Erreur lors du chargement des catégories: $e',
        tag: logTag,
        data: stackTrace,
      );
    }
  }

  Future<void> _loadPopularQuizzes() async {
    setState(() {
      _isLoadingQuizzes = true;
    });

    try {
      final quizService = Provider.of<QuizService>(context, listen: false);
      final quizzes = await quizService.getPopularQuizzes(limit: 5);

      setState(() {
        _popularQuizzes = quizzes;
        _isLoadingQuizzes = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoadingQuizzes = false;
      });
      logger.error(
        'Erreur lors du chargement des quiz populaires: $e',
        tag: logTag,
        data: stackTrace,
      );
    }
  }

  // Sauvegarde des modifications du profil
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Préparation des paramètres de mise à jour
      final String? displayName = _displayNameController.text.trim();
      final String? photoUrl = _selectedAvatar;
      final String? backgroundColor = _selectedColor;

      // Si la section de changement de mot de passe est ouverte et les champs remplis
      String? currentPassword;
      String? newPassword;

      if (_isPasswordChangeVisible &&
          _currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty) {
        // Vérifier que les mots de passe correspondent
        if (_newPasswordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = 'Les nouveaux mots de passe ne correspondent pas';
          });
          return;
        }

        currentPassword = _currentPasswordController.text;
        newPassword = _newPasswordController.text;
      }

      // Appel au service de mise à jour
      await authService.updateUserProfile(
        displayName: displayName,
        photoUrl: photoUrl,
        avatarBackgroundColor: backgroundColor,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );

        // Réinitialiser les champs de mot de passe
        if (_isPasswordChangeVisible) {
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          setState(() {
            _isPasswordChangeVisible = false;
          });
        }
      }

      logger.info('Profil utilisateur mis à jour avec succès', tag: logTag);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la mise à jour du profil: $e';
      });
      logger.error('Erreur lors de la mise à jour du profil: $e', tag: logTag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final UserModel? user = authService.currentUserModel;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Déterminer si le menu doit être replié par défaut sur les petits écrans
    final bool isSmallScreen = screenWidth < 600;

    // Si l'utilisateur n'est pas chargé, afficher un indicateur de chargement
    if (user == null && authService.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Row(
        children: [
          // Menu latéral
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width:
                isSmallScreen
                    ? (_isDrawerExpanded ? 250 : 70)
                    : (_isDrawerExpanded ? 250 : 70),
            child: _buildSideNav(theme, user, isSmallScreen),
          ),

          // Ligne de séparation
          VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),

          // Contenu principal
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // Page d'accueil
                _buildHomeContent(context, user),

                // Page des lobbys
                const LobbiesView(),

                // Page de classement
                _buildLeaderboardContent(context),

                // Page de création
                _buildCreateContent(context),

                // Page de paramètres
                _buildSettingsContent(context, authService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construction du menu latéral
  Widget _buildSideNav(ThemeData theme, UserModel? user, bool isSmallScreen) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Accueil',
        'index': 0,
      },
      {
        'icon': Icons.groups_outlined,
        'activeIcon': Icons.groups,
        'label': 'Lobbys',
        'index': 1,
      },
      {
        'icon': Icons.leaderboard_outlined,
        'activeIcon': Icons.leaderboard,
        'label': 'Classement',
        'index': 2,
      },
      {
        'icon': Icons.add_circle_outline,
        'activeIcon': Icons.add_circle,
        'label': 'Créer',
        'index': 3,
      },
      {
        'icon': Icons.settings_outlined,
        'activeIcon': Icons.settings,
        'label': 'Paramètres',
        'index': 4,
      },
    ];

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // En-tête du menu avec avatar et nom de l'utilisateur
          if (_isDrawerExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AvatarPreview(
                    avatarUrl:
                        user?.photoUrl ?? 'assets/images/avatars/logo.png',
                    backgroundColor: user?.avatarBackgroundColor,
                    size: 80,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.displayName ?? 'Utilisateur',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          if (!_isDrawerExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: AvatarPreview(
                avatarUrl: user?.photoUrl ?? 'assets/images/avatars/logo.png',
                backgroundColor: user?.avatarBackgroundColor,
                size: 40,
              ),
            ),

          const Divider(),

          // Options de menu
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = _currentIndex == item['index'];

                return ListTile(
                  leading: Icon(
                    isSelected ? item['activeIcon'] : item['icon'],
                    color:
                        isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                  ),
                  title:
                      _isDrawerExpanded
                          ? Text(
                            item['label'],
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          )
                          : null,
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _currentIndex = item['index'];
                      // Sur petit écran, refermer le menu après sélection
                      if (isSmallScreen && _isDrawerExpanded) {
                        _isDrawerExpanded = false;
                      }
                    });
                  },
                );
              },
            ),
          ),

          // Bouton pour replier/déplier le menu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(
                _isDrawerExpanded ? Icons.chevron_left : Icons.chevron_right,
              ),
              onPressed: () {
                setState(() {
                  _isDrawerExpanded = !_isDrawerExpanded;
                });
              },
              tooltip: _isDrawerExpanded ? 'Replier' : 'Déplier',
            ),
          ),
        ],
      ),
    );
  }

  // Construction du contenu de la page d'accueil
  Widget _buildHomeContent(BuildContext context, UserModel? user) {
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
                          logger.error('Quiz tapped: ${quiz.title}');
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

  // Construction du contenu de la page de classement
  Widget _buildLeaderboardContent(BuildContext context) {
    return const Center(child: Text('Classement - À implémenter'));
  }

  // Construction du contenu de la page de création
  Widget _buildCreateContent(BuildContext context) {
    return const Center(child: Text('Créer un quiz - À implémenter'));
  }

  // Construction du contenu de la page de paramètres
  Widget _buildSettingsContent(BuildContext context, AuthService authService) {
    final user = authService.currentUserModel;
    final isLoading = authService.isLoading;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Section profil avec expansion
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // En-tête de la section profil (toujours visible)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Mon profil'),
                    trailing: IconButton(
                      icon: Icon(
                        _isProfileExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                      onPressed: () {
                        setState(() {
                          _isProfileExpanded = !_isProfileExpanded;

                          // Réinitialiser les valeurs si on ouvre la section
                          if (_isProfileExpanded) {
                            _initUserData();
                          }
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _isProfileExpanded = !_isProfileExpanded;

                        // Réinitialiser les valeurs si on ouvre la section
                        if (_isProfileExpanded) {
                          _initUserData();
                        }
                      });
                    },
                  ),

                  // Contenu expansible de l'édition du profil
                  if (_isProfileExpanded)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant
                            .withAlpha((255 * 0.3).toInt()),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Aperçu de l'avatar avec la couleur sélectionnée
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: AvatarPreview(
                                avatarUrl: _selectedAvatar,
                                backgroundColor: _selectedColor,
                                size: 120,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Sélection d'avatar
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Choisir un avatar',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                    ),
                                    AvatarSelector(
                                      currentAvatar: _selectedAvatar,
                                      onAvatarSelected: (avatar) {
                                        setState(() {
                                          _selectedAvatar = avatar;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Sélection de couleur de fond
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Couleur de fond',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                    ),
                                    ColorSelector(
                                      currentColor: _selectedColor,
                                      onColorSelected: (color) {
                                        setState(() {
                                          _selectedColor = color;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Champ pseudo
                            AuthTextField(
                              controller: _displayNameController,
                              labelText: 'Pseudo',
                              hintText: 'Entrez votre pseudo',
                              prefixIcon: const Icon(Icons.person),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un pseudo';
                                }
                                if (value.length < 3) {
                                  return 'Le pseudo doit contenir au moins 3 caractères';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Section changement de mot de passe
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Changer de mot de passe',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                        ),
                                        Switch(
                                          value: _isPasswordChangeVisible,
                                          onChanged: (value) {
                                            setState(() {
                                              _isPasswordChangeVisible = value;
                                            });
                                          },
                                        ),
                                      ],
                                    ),

                                    if (_isPasswordChangeVisible) ...[
                                      const SizedBox(height: 16),

                                      AuthTextField(
                                        controller: _currentPasswordController,
                                        labelText: 'Mot de passe actuel',
                                        hintText:
                                            'Entrez votre mot de passe actuel',
                                        obscureText: _obscureCurrentPassword,
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureCurrentPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureCurrentPassword =
                                                  !_obscureCurrentPassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (_isPasswordChangeVisible &&
                                              (value == null ||
                                                  value.isEmpty)) {
                                            return 'Veuillez entrer votre mot de passe actuel';
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 16),

                                      AuthTextField(
                                        controller: _newPasswordController,
                                        labelText: 'Nouveau mot de passe',
                                        hintText:
                                            'Entrez votre nouveau mot de passe',
                                        obscureText: _obscureNewPassword,
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureNewPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureNewPassword =
                                                  !_obscureNewPassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (_isPasswordChangeVisible &&
                                              (value == null ||
                                                  value.isEmpty)) {
                                            return 'Veuillez entrer un nouveau mot de passe';
                                          }
                                          if (_isPasswordChangeVisible &&
                                              value != null &&
                                              value.length < 6) {
                                            return 'Le mot de passe doit contenir au moins 6 caractères';
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 16),

                                      AuthTextField(
                                        controller: _confirmPasswordController,
                                        labelText:
                                            'Confirmer le nouveau mot de passe',
                                        hintText:
                                            'Confirmez votre nouveau mot de passe',
                                        obscureText: _obscureConfirmPassword,
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (_isPasswordChangeVisible &&
                                              (value == null ||
                                                  value.isEmpty)) {
                                            return 'Veuillez confirmer votre nouveau mot de passe';
                                          }
                                          if (_isPasswordChangeVisible &&
                                              value !=
                                                  _newPasswordController.text) {
                                            return 'Les mots de passe ne correspondent pas';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // Message d'erreur si présent
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(
                                    (255 * 0.1).toInt(),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Bouton de sauvegarde
                            AuthButton(
                              text: 'Sauvegarder les modifications',
                              isLoading: isLoading,
                              onPressed: _saveProfile,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 32),

            // Autres options de paramètres
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Mode sombre'),
              trailing: Switch(
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (value) {
                  // TODO: Toggle dark mode
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Open notifications settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Aide'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Open help center
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('À propos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Open about page
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Déconnexion',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Déconnexion'),
                        content: const Text(
                          'Êtes-vous sûr de vouloir vous déconnecter ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Déconnexion',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                );

                if (confirm == true) {
                  await authService.signOut();
                  // La redirection est gérée automatiquement par le RouterGuard
                }
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
