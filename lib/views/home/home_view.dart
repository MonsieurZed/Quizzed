/// Vue principale de l'accueil
///
/// Page d'accueil affichée après l'authentification
/// Contient les différentes sections et fonctionnalités principales
/// Utilise un menu latéral à gauche pour la navigation
/// et un bandeau à droite pour des informations supplémentaires
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/controllers/lobby/lobby_controller.dart';
import 'package:quizzzed/models/user/user_model.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:quizzzed/widgets/chat/chat_view.dart';
import 'package:quizzzed/widgets/profile/avatar_preview.dart';

/// HomeView est maintenant un conteneur shell qui maintient le menu latéral
/// persistant pendant la navigation entre les différentes vues enfants
class HomeView extends StatefulWidget {
  final int currentIndex;
  final Widget child;

  const HomeView({super.key, this.currentIndex = 0, required this.child});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late int _currentIndex;
  bool _isDrawerExpanded = true; // État d'expansion du menu latéral
  bool _isBannerVisible = true; // État de visibilité du bandeau droit
  final LoggerService logger = LoggerService();
  final String logTag = 'HomeView';

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      setState(() {
        _currentIndex = widget.currentIndex;
      });
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
          // Menu latéral (toujours présent quelle que soit la vue)
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

          // Contenu principal (injecté par le routeur)
          Expanded(child: widget.child),

          // Ligne de séparation pour le bandeau droit
          VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),

          // Bandeau droit (toujours présent quelle que soit la vue)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isBannerVisible ? 300 : 50,
            child: _buildRightBanner(theme, user),
          ),
        ],
      ),
    );
  }

  // Construction du bandeau droit
  Widget _buildRightBanner(ThemeData theme, UserModel? user) {
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // En-tête du bandeau
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isBannerVisible)
                  Text(
                    'Tchat de lobby',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _isBannerVisible ? Icons.chevron_right : Icons.chevron_left,
                  ),
                  onPressed: () {
                    setState(() {
                      _isBannerVisible = !_isBannerVisible;
                    });
                  },
                  tooltip: _isBannerVisible ? 'Replier' : 'Déplier',
                ),
              ],
            ),
          ),

          const Divider(),

          // Contenu du bandeau - Widget de tchat
          Expanded(
            child:
                _isBannerVisible
                    ? Padding(
                      padding: const EdgeInsets.all(
                        0,
                      ), // Pas de padding pour maximiser l'espace
                      child: Consumer<LobbyController>(
                        builder: (context, lobbyController, _) {
                          final currentLobby = lobbyController.currentLobby;
                          return ChatView(
                            lobbyId: currentLobby?.id ?? '',
                          ); // Ajout du paramètre lobbyId requis
                        },
                      ),
                    )
                    : RotatedBox(
                      quarterTurns: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('Tchat', style: theme.textTheme.labelLarge),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // Construction du menu latéral
  Widget _buildSideNav(ThemeData theme, UserModel? user, bool isSmallScreen) {
    // Vérifier si l'utilisateur a un lobby actuel et encoder correctement l'ID
    final String? rawLobbyId = user?.currentLobbyId;
    // Un lobby est considéré comme actif uniquement si l'ID existe et n'est pas vide
    final bool hasCurrentLobby =
        rawLobbyId != null && rawLobbyId.trim().isNotEmpty;

    // Encoder l'ID du lobby pour éviter les problèmes de caractères spéciaux dans l'URL
    final String? currentLobbyId =
        hasCurrentLobby ? Uri.encodeComponent(rawLobbyId) : null;

    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Accueil',
        'route': '/home',
      },
      {
        'icon': Icons.groups_outlined,
        'activeIcon': Icons.groups,
        'label': 'Lobbys',
        'route': '/home/lobbies',
      },
      // Ajouter conditionnellement le raccourci vers le lobby actuel seulement si un lobby est actif
      if (hasCurrentLobby)
        {
          'icon': Icons.meeting_room_outlined,
          'activeIcon': Icons.meeting_room,
          'label': 'Mon Lobby',
          'route': '/home/lobbies/$currentLobbyId',
          'isSpecial': true, // Pour appliquer un style spécial
        },
      {
        'icon': Icons.leaderboard_outlined,
        'activeIcon': Icons.leaderboard,
        'label': 'Classement',
        'route': '/home/leaderboard',
      },
      {
        'icon': Icons.settings_outlined,
        'activeIcon': Icons.settings,
        'label': 'Paramètres',
        'route': '/home/settings',
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
                  AvatarDisplay(
                    avatar: user?.avatar ?? 'logo',
                    color: user?.color,
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
              child: AvatarDisplay(
                avatar: user?.avatar ?? 'logo',
                color: user?.color,
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
                final bool isSelected = index == _currentIndex;
                final bool isSpecial = item['isSpecial'] == true;

                return ListTile(
                  leading: Icon(
                    isSelected ? item['activeIcon'] : item['icon'],
                    color:
                        isSelected
                            ? theme.colorScheme.primary
                            : isSpecial
                            ? theme.colorScheme.secondary
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
                                      : isSpecial
                                      ? theme.colorScheme.secondary
                                      : theme.colorScheme.onSurfaceVariant,
                              fontWeight:
                                  isSelected || isSpecial
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          )
                          : null,
                  selected: isSelected,
                  onTap: () {
                    // Navigation vers la route appropriée
                    if (item['route'] != null) {
                      context.go(item['route']);
                    }

                    // Sur petit écran, refermer le menu après sélection
                    if (isSmallScreen && _isDrawerExpanded) {
                      setState(() {
                        _isDrawerExpanded = false;
                      });
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
}
