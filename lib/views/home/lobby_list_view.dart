// filepath: d:\GIT\quizzzed\lib\views\home\lobby_list_view.dart
/// Lobby List View
///
/// Vue qui affiche la liste des lobbies publics disponibles
/// Permet aux utilisateurs de parcourir, filtrer et rejoindre des lobbies

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/controllers/lobby_controller.dart';
import 'package:quizzzed/models/quiz/lobby_model.dart';
import 'package:quizzzed/routes/app_routes.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/theme/theme_service.dart';
import 'package:quizzzed/widgets/home/lobby_card.dart';
import 'package:quizzzed/widgets/shared/empty_state.dart';
import 'package:quizzzed/widgets/shared/error_display.dart';
import 'package:quizzzed/widgets/shared/loading_display.dart';
import 'package:quizzzed/widgets/shared/section_header.dart';

class LobbyListView extends StatefulWidget {
  const LobbyListView({Key? key}) : super(key: key);

  @override
  State<LobbyListView> createState() => _LobbyListViewState();
}

class _LobbyListViewState extends State<LobbyListView> {
  bool _isRefreshing = false;
  String _selectedCategory = 'Tous';
  List<String> _categories = ['Tous'];

  @override
  void initState() {
    super.initState();
    // Chargement initial des catégories
    _updateCategoriesFromLobbies();
  }

  // Méthode pour mettre à jour les catégories à partir des lobbies existants
  void _updateCategoriesFromLobbies() {
    final lobbyController = Provider.of<LobbyController>(
      context,
      listen: false,
    );

    final lobbies = lobbyController.publicLobbies;
    final categories =
        lobbies.map((lobby) => lobby.category).toSet().toList()..sort();
    categories.insert(0, 'Tous');

    if (mounted) {
      setState(() {
        _categories = categories;
      });
    }
  }

  Future<void> _loadLobbies() async {
    if (mounted) {
      setState(() => _isRefreshing = true);
    }

    try {
      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );
      await lobbyController.loadPublicLobbies();

      // Mettre à jour les catégories
      _updateCategoriesFromLobbies();

      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _joinLobby(LobbyModel lobby) async {
    final lobbyController = Provider.of<LobbyController>(
      context,
      listen: false,
    );

    final success = await lobbyController.joinLobby(lobby.id);

    if (success && mounted) {
      context.pushNamed(
        AppRoutes.lobbyDetail,
        pathParameters: {'id': lobby.id},
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de rejoindre ce lobby')),
      );
    }
  }

  void _showJoinPrivateLobbyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _JoinPrivateLobbyDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Utilisateur non connecté'));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadLobbies,
        child: Consumer<LobbyController>(
          builder: (context, lobbyController, child) {
            final isLoading = _isRefreshing || lobbyController.isLoading;
            final hasError = lobbyController.error != null;
            final lobbies = lobbyController.publicLobbies;

            if (isLoading && lobbies.isEmpty) {
              return const LoadingDisplay(message: 'Chargement des lobbies...');
            }

            if (hasError && lobbies.isEmpty) {
              return ErrorDisplay(
                title: 'Erreur de chargement',
                message: lobbyController.error ?? 'Une erreur est survenue',
                onRetry: _loadLobbies,
              );
            }

            // Filtrer par catégorie si besoin
            final filteredLobbies =
                _selectedCategory == 'Tous'
                    ? lobbies
                    : lobbies
                        .where((l) => l.category == _selectedCategory)
                        .toList();

            if (filteredLobbies.isEmpty) {
              // Afficher le menu horizontal en haut et le message d'état vide
              return Column(
                children: [
                  _buildHorizontalActionsMenu(context),
                  Expanded(
                    child: EmptyState(
                      title: 'Aucun lobby disponible',
                      message:
                          _selectedCategory == 'Tous'
                              ? 'Aucun lobby public n\'est disponible pour le moment'
                              : 'Aucun lobby disponible dans cette catégorie',
                      icon: Icons.public_off,
                      actionText: 'Créer un lobby',
                      onAction: () => context.pushNamed(AppRoutes.createLobby),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                // Nouveau menu horizontal d'actions
                _buildHorizontalActionsMenu(context),

                // Liste des lobbies
                Expanded(
                  child: Stack(
                    children: [
                      ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredLobbies.length,
                        itemBuilder: (context, index) {
                          final lobby = filteredLobbies[index];
                          final isHost = lobby.hostId == currentUser.uid;

                          return LobbyCard(
                            lobby: lobby,
                            isHost: isHost,
                            canJoin: !isHost,
                            onJoin: () => _joinLobby(lobby),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Nouveau widget pour le menu horizontal d'actions
  Widget _buildHorizontalActionsMenu(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton pour créer un lobby
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.pushNamed(AppRoutes.createLobby),
              icon: const Icon(Icons.add),
              label: const Text('Créer un lobby'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Bouton pour rejoindre un lobby privé
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showJoinPrivateLobbyDialog,
              icon: const Icon(Icons.vpn_key),
              label: const Text('Rejoindre avec un code'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Bouton pour rafraîchir
          IconButton(
            onPressed: _isRefreshing ? null : _loadLobbies,
            icon:
                _isRefreshing
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Catégories'),
          const SizedBox(height: 8.0),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinPrivateLobbyDialog extends StatefulWidget {
  @override
  State<_JoinPrivateLobbyDialog> createState() =>
      _JoinPrivateLobbyDialogState();
}

class _JoinPrivateLobbyDialogState extends State<_JoinPrivateLobbyDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinPrivateLobby() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Veuillez entrer un code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );

      final lobbyId = await lobbyController.joinLobbyByCode(code);

      if (lobbyId != null && mounted) {
        Navigator.pop(context);
        context.pushNamed(
          AppRoutes.lobbyDetail,
          pathParameters: {'id': lobbyId},
        );
      } else if (mounted) {
        setState(() {
          _error = 'Code invalide ou lobby inaccessible';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Une erreur est survenue';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rejoindre un lobby privé'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Entrez le code du lobby à 6 caractères'),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Code du lobby',
              errorText: _error,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.vpn_key),
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              letterSpacing: 4,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _joinPrivateLobby,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Rejoindre'),
        ),
      ],
    );
  }
}
