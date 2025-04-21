/// Create Lobby View
///
/// Vue permettant de créer un nouveau lobby de quiz
/// L'utilisateur peut configurer les paramètres du lobby comme le nom,
/// la visibilité (public/privé), le nombre de joueurs, etc.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/controllers/lobby_controller.dart';
import 'package:quizzzed/models/quiz/lobby_model.dart';
import 'package:quizzzed/models/user/user_model.dart';
import 'package:quizzzed/routes/app_routes.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/widgets/profile/avatar_preview.dart';
import 'package:quizzzed/widgets/shared/section_header.dart';

class CreateLobbyView extends StatefulWidget {
  const CreateLobbyView({Key? key}) : super(key: key);

  @override
  State<CreateLobbyView> createState() => _CreateLobbyViewState();
}

class _CreateLobbyViewState extends State<CreateLobbyView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  LobbyVisibility _visibility = LobbyVisibility.public;
  String _category = 'Général';
  int _maxPlayers = AppConfig.maxPlayersPerLobby;
  int _minPlayers = AppConfig.minPlayersToStart;
  bool _isCreating = false;
  bool _isDrawerExpanded = true; // État d'expansion du menu latéral

  final List<String> _categories = [
    'Général',
    'Science',
    'Histoire',
    'Sport',
    'Géographie',
    'Musique',
    'Cinéma',
    'Jeux vidéo',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createLobby() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );
      final lobbyId = await lobbyController.createLobby(
        name: _nameController.text.trim(),
        visibility: _visibility,
        maxPlayers: _maxPlayers,
        minPlayers: _minPlayers,
        category: _category,
      );

      if (lobbyId != null && mounted) {
        // Rediriger vers le lobby créé
        context.pushReplacementNamed(
          AppRoutes.lobbyDetail,
          pathParameters: {'id': lobbyId},
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création du lobby')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  // Construction du menu latéral
  Widget _buildSideNav(ThemeData theme, UserModel? user, bool isSmallScreen) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Accueil',
        'route': AppRoutes.home,
      },
      {
        'icon': Icons.groups_outlined,
        'activeIcon': Icons.groups,
        'label': 'Lobbys',
        'route': AppRoutes.lobbies,
      },
      {
        'icon': Icons.leaderboard_outlined,
        'activeIcon': Icons.leaderboard,
        'label': 'Classement',
        'route': null, // Non implémenté
      },
      {
        'icon': Icons.add_circle_outlined,
        'activeIcon': Icons.add_circle,
        'label': 'Créer',
        'route': AppRoutes.createLobby,
        'isSelected': true,
      },
      {
        'icon': Icons.settings_outlined,
        'activeIcon': Icons.settings,
        'label': 'Paramètres',
        'route': null, // Non implémenté
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
                final isSelected = item['isSelected'] ?? false;

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
                    if (item['route'] != null) {
                      context.goNamed(item['route']);
                    }
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final UserModel? user = authService.currentUserModel;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Déterminer si le menu doit être replié par défaut sur les petits écrans
    final bool isSmallScreen = screenWidth < 600;

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
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const SectionHeader(title: 'Informations du lobby'),
                  const SizedBox(height: 16),

                  // Nom du lobby
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du lobby',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    maxLength: 30,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un nom de lobby';
                      }
                      if (value.trim().length < 3) {
                        return 'Le nom doit contenir au moins 3 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Catégorie
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    value: _category,
                    items:
                        _categories.map((String category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _category = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Visibilité du lobby
                  const SectionHeader(title: 'Visibilité'),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<LobbyVisibility>(
                          title: const Text('Public'),
                          subtitle: const Text('Visible par tous les joueurs'),
                          value: LobbyVisibility.public,
                          groupValue: _visibility,
                          onChanged: (LobbyVisibility? value) {
                            if (value != null) {
                              setState(() {
                                _visibility = value;
                              });
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<LobbyVisibility>(
                          title: const Text('Privé'),
                          subtitle: const Text(
                            'Accessible par code uniquement',
                          ),
                          value: LobbyVisibility.private,
                          groupValue: _visibility,
                          onChanged: (LobbyVisibility? value) {
                            if (value != null) {
                              setState(() {
                                _visibility = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nombre de joueurs
                  const SectionHeader(title: 'Joueurs'),
                  const SizedBox(height: 16),

                  ListTile(
                    title: const Text('Nombre maximum de joueurs'),
                    subtitle: Slider(
                      value: _maxPlayers.toDouble(),
                      min:
                          AppConfig.minPlayersToStart
                              .toDouble(), // Correction: min doit être plus petit que max
                      max:
                          AppConfig.maxPlayersPerLobby
                              .toDouble(), // Correction: max doit être plus grand que min
                      divisions:
                          (AppConfig.maxPlayersPerLobby -
                                  AppConfig.minPlayersToStart)
                              .toInt(),
                      label: _maxPlayers.toString(),
                      onChanged: (double value) {
                        setState(() {
                          _maxPlayers = value.toInt();
                          if (_minPlayers > _maxPlayers) {
                            _minPlayers = _maxPlayers;
                          }
                        });
                      },
                    ),
                    trailing: Text(
                      _maxPlayers.toString(),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),

                  ListTile(
                    title: const Text('Nombre minimum pour démarrer'),
                    subtitle: Slider(
                      value: _minPlayers.toDouble(),
                      min: 1,
                      max: _maxPlayers.toDouble(),
                      divisions: _maxPlayers - 1,
                      label: _minPlayers.toString(),
                      onChanged: (double value) {
                        setState(() {
                          _minPlayers = value.toInt();
                        });
                      },
                    ),
                    trailing: Text(
                      _minPlayers.toString(),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isCreating ? null : _createLobby,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child:
                        _isCreating
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text(
                              'Créer le lobby',
                              style: TextStyle(fontSize: 18),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
