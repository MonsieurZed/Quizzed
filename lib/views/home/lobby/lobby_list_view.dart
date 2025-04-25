// filepath: d:\GIT\quizzzed\lib\views\home\lobby_list_view.dart
/// Lobby List View
///
/// Vue qui affiche la liste des lobbies publics disponibles
/// Permet aux utilisateurs de parcourir, filtrer et rejoindre des lobbies
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/controllers/lobby/lobby_controller.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';
import 'package:quizzzed/routes/app_routes.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/widgets/home/lobby_card.dart';
import 'package:quizzzed/widgets/shared/empty_state.dart';
import 'package:quizzzed/widgets/shared/error_display.dart';
import 'package:quizzzed/widgets/shared/loading_display.dart';
import 'package:quizzzed/widgets/shared/section_header.dart';

class LobbyListView extends StatefulWidget {
  const LobbyListView({super.key});

  @override
  State<LobbyListView> createState() => _LobbyListViewState();
}

class _LobbyListViewState extends State<LobbyListView> {
  bool _isRefreshing = false;
  String _selectedCategory = 'Tous';
  List<String> _categories = ['Tous'];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Chargement initial des lobbies et des catégories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLobbies();
    });
    // Chargement initial des catégories
    _updateCategoriesFromLobbies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _joinLobby(LobbyModel lobby, {bool isResuming = false}) async {
    final lobbyController = Provider.of<LobbyController>(
      context,
      listen: false,
    );

    // If resuming an existing lobby, use loadExistingLobby instead of joinLobby
    if (isResuming) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Chargement du lobby..."),
              ],
            ),
          );
        },
      );

      try {
        // Use loadExistingLobby to avoid rejoining
        final success = await lobbyController.loadExistingLobby(lobby.id);

        // Close loading dialog
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (success && mounted) {
          // Navigate to the lobby detail view using correct nested path
          context.go('/home/lobbies/${lobby.id}');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le lobby n\'existe plus ou a été supprimé'),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog in case of error
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
        }
      }
      return;
    }

    // For regular join (not resuming), show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Connexion au lobby en cours..."),
            ],
          ),
        );
      },
    );

    try {
      final success = await lobbyController.joinLobby(lobby.id);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (success && mounted) {
        context.pushReplacementNamed(
          AppRoutes.lobbyDetail,
          pathParameters: {'id': lobby.id},
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de rejoindre ce lobby')),
        );
      }
    } catch (e) {
      // Close loading dialog in case of error
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
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

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentFirebaseUser;

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

            // Filtrer par catégorie et terme de recherche
            final filteredLobbies =
                lobbies
                    .where(
                      (lobby) =>
                          (_selectedCategory == 'Tous' ||
                              lobby.category == _selectedCategory) &&
                          (_searchQuery.isEmpty ||
                              lobby.name.toLowerCase().contains(_searchQuery) ||
                              lobby.category.toLowerCase().contains(
                                _searchQuery,
                              )),
                    )
                    .toList();

            if (filteredLobbies.isEmpty) {
              // Afficher le menu horizontal en haut et le message d'état vide
              return Column(
                children: [
                  _buildHorizontalActionsMenu(context),
                  _buildSearchBar(),
                  _buildCategoryFilter(),
                  Expanded(
                    child: EmptyState(
                      title: 'Aucun lobby disponible',
                      message:
                          _searchQuery.isNotEmpty
                              ? 'Aucun lobby ne correspond à votre recherche'
                              : _selectedCategory == 'Tous'
                              ? 'Aucun lobby public n\'est disponible pour le moment'
                              : 'Aucun lobby disponible dans cette catégorie',
                      icon:
                          _searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.public_off,
                      actionText: 'Créer un lobby',
                      onAction: () => context.pushNamed(AppRoutes.createLobby),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                // Menu horizontal d'actions
                _buildHorizontalActionsMenu(context),

                // Barre de recherche (conditionnelle)
                _buildSearchBar(),

                // Filtre par catégorie
                _buildCategoryFilter(),

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
                          final isCurrentLobby =
                              authService.currentUserModel?.currentLobbyId ==
                              lobby.id;

                          return Column(
                            children: [
                              LobbyCard(
                                lobby: lobby,
                                isHost: isHost,
                                isCurrentLobby: isCurrentLobby,
                                canJoin: !isHost && !isCurrentLobby,
                                onJoin:
                                    () => _joinLobby(
                                      lobby,
                                      isResuming: isHost || isCurrentLobby,
                                    ),
                              ),
                            ],
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

  // Widget pour la barre de recherche
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: TextField(
        controller: _searchController,
        onChanged: _updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Rechercher un lobby...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _updateSearchQuery('');
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
        ),
        textInputAction: TextInputAction.search,
        autofocus: true,
      ),
    );
  }

  // Widget pour le menu horizontal d'actions
  Widget _buildHorizontalActionsMenu(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha((0.1 * 255).toInt()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Centrer les boutons
        children: [
          // Bouton pour créer un lobby
          SizedBox(
            width: 160, // Largeur fixe au lieu de Expanded
            child: ElevatedButton.icon(
              onPressed: () => context.pushNamed(AppRoutes.createLobby),
              icon: const Icon(Icons.add),
              label: const Text('Créer un lobby'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor:
                    theme.colorScheme.primary, // Force la couleur primaire
                foregroundColor:
                    theme.colorScheme.onPrimary, // Force la couleur du texte
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Bouton pour rejoindre un lobby privé
          SizedBox(
            width: 160, // Largeur fixe au lieu de Expanded
            child: ElevatedButton.icon(
              onPressed: _showJoinPrivateLobbyDialog,
              icon: const Icon(Icons.vpn_key),
              label: const Text('Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.white, // Fond blanc pour contraster
                foregroundColor:
                    theme.colorScheme.primary, // Texte couleur primaire
                side: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Bouton pour rafraîchir (seul bouton d'action restant)
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
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceVariant,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
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
