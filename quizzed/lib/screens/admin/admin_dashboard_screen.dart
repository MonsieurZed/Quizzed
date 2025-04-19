import 'package:flutter/material.dart';
import 'package:quizzed/services/auth_service.dart';
import 'package:quizzed/routes/app_routes.dart';
import 'package:quizzed/repositories/quiz_repository.dart';
import 'package:quizzed/models/quiz_session.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  final QuizRepository _quizRepository = QuizRepository();
  bool _isFetchingData = false;
  List<QuizSession> _quizSessions = [];
  QuizSession? _selectedSession;
  int _currentIndex = 0;

  // Nouvelles options pour le menu latéral
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Tableau de bord'},
    {'icon': Icons.quiz, 'label': 'Sessions de quiz'},
    {'icon': Icons.people, 'label': 'Joueurs'},
    {'icon': Icons.analytics, 'label': 'Statistiques'},
    {'icon': Icons.settings, 'label': 'Paramètres'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isFetchingData = true;
    });

    try {
      // Get initial data
      final sessionsStream = _quizRepository.getQuizSessions();
      final initialSessions = await sessionsStream.first;

      setState(() {
        _quizSessions = initialSessions;
        _isFetchingData = false;
      });
    } catch (e) {
      setState(() {
        _isFetchingData = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading sessions: $e')));
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  void _createNewQuizSession() {
    Navigator.pushNamed(context, AppRoutes.quizCreation);
  }

  void _editQuizSession(QuizSession session) {
    Navigator.pushNamed(
      context,
      AppRoutes.quizCreation,
      arguments: {'sessionId': session.id},
    );
  }

  void _manageQuizSession(QuizSession session) {
    if (session.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session ID is missing')));
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Gérer: ${session.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statut: ${session.isActive ? 'Actif' : 'Inactif'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _editQuizSession(session);
                },
                child: const Text('Modifier les questions'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _launchQuizSession(session);
                },
                child: const Text('Gérer la session'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _launchQuizSession(QuizSession session) {
    if (session.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session ID is missing')));
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.quizSessionManagement,
      arguments: {'sessionId': session.id},
    );
  }

  Future<void> _deleteQuizSession(QuizSession session) async {
    if (session.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmation'),
            content: Text(
              'Voulez-vous vraiment supprimer la session "${session.title}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _quizRepository.deleteQuizSession(session.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session supprimée avec succès')),
        );

        // Refresh the list
        _fetchData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final ratio = screenSize.width / screenSize.height;
    final isDesktop = ratio >= 1.6 && screenSize.width > 1200;

    return Scaffold(
      appBar:
          isDesktop
              ? null
              : AppBar(
                title: const Text('Dashboard Admin'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    onPressed: _signOut,
                  ),
                ],
              ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      floatingActionButton:
          isDesktop
              ? null
              : FloatingActionButton(
                onPressed: () {
                  // Navigate to player view to monitor current quiz
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Vue du lobby'),
                          content: const Text(
                            'Cette fonctionnalité vous permettra de voir le lobby des joueurs en temps réel.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Fermer'),
                            ),
                          ],
                        ),
                  );
                },
                child: const Icon(Icons.visibility),
              ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Menu de navigation latéral
        _buildSidebar(),

        // Contenu principal
        Expanded(
          child: Column(
            children: [
              // En-tête avec barre de recherche et actions
              _buildDesktopHeader(),

              // Contenu principal basé sur la sélection du menu
              Expanded(
                child:
                    _currentIndex == 0
                        ? _buildDesktopDashboard()
                        : _currentIndex == 1
                        ? _buildSessionsContent()
                        : const Center(child: Text("Fonctionnalité à venir")),
              ),
            ],
          ),
        ),

        // Panneau de détails (visible si une session est sélectionnée)
        if (_selectedSession != null) _buildSessionDetailsPanel(),
      ],
    );
  }

  Widget _buildSidebar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;
    final brightness = colorScheme.brightness;

    return Container(
      width: 240,
      color: primary,
      child: Column(
        children: [
          // Logo et nom de l'application
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz, size: 32, color: onPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'QUIZZED',
                      style: TextStyle(
                        color: onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: onPrimary.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: onPrimary.withOpacity(0.24), height: 1),

          // Informations de l'utilisateur
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: onPrimary.withOpacity(0.3),
                  child: Icon(Icons.person, color: onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maître du jeu',
                        style: TextStyle(
                          color: onPrimary.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _authService.currentUser?.email ?? 'Non connecté',
                        style: TextStyle(
                          color: onPrimary.withOpacity(0.5),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: onPrimary.withOpacity(0.24), height: 1),

          // Menu de navigation
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final bool isSelected = index == _currentIndex;

                return ListTile(
                  leading: Icon(
                    item['icon'],
                    color: isSelected ? onPrimary : onPrimary.withOpacity(0.7),
                  ),
                  title: Text(
                    item['label'],
                    style: TextStyle(
                      color:
                          isSelected ? onPrimary : onPrimary.withOpacity(0.7),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: onPrimary.withOpacity(0.1),
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                      // Réinitialiser la session sélectionnée lors du changement de tab
                      _selectedSession = null;
                    });
                  },
                );
              },
            ),
          ),

          Divider(color: onPrimary.withOpacity(0.24), height: 1),

          // Bouton de déconnexion
          ListTile(
            leading: Icon(Icons.exit_to_app, color: onPrimary.withOpacity(0.7)),
            title: Text(
              'Déconnexion',
              style: TextStyle(color: onPrimary.withOpacity(0.7)),
            ),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceVariant = colorScheme.surfaceVariant;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;
    final surface = colorScheme.surface;
    final primaryContainer = colorScheme.primaryContainer;
    final onPrimaryContainer = colorScheme.onPrimaryContainer;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: surface,
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
          // Titre de la page actuelle
          Text(
            _menuItems[_currentIndex]['label'],
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // Barre de recherche
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
              color: surfaceVariant,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search, color: onSurfaceVariant),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Bouton pour créer une nouvelle session
          ElevatedButton.icon(
            onPressed: _createNewQuizSession,
            icon: const Icon(Icons.add),
            label: const Text('Créer une session'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(width: 8),

          // Bouton pour voir le lobby
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: 'Voir le lobby',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Vue du lobby'),
                      content: const Text(
                        'Cette fonctionnalité vous permettra de voir le lobby des joueurs en temps réel.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
              );
            },
          ),

          const SizedBox(width: 8),

          // Menu de notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDashboard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cartes d'informations
          Row(
            children: [
              _buildInfoCard(
                title: 'Sessions de quiz',
                value: '${_quizSessions.length}',
                icon: Icons.quiz,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 16),
              _buildInfoCard(
                title: 'Sessions actives',
                value: '${_quizSessions.where((s) => s.isActive).length}',
                icon: Icons.play_circle,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 16),
              _buildInfoCard(
                title: 'Questions créées',
                value: '142', // Simulé
                icon: Icons.help,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 16),
              _buildInfoCard(
                title: 'Joueurs totaux',
                value: '347', // Simulé
                icon: Icons.people,
                color: colorScheme.error,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Sessions récentes
          Text(
            'Sessions récentes',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<List<QuizSession>>(
              stream: _quizRepository.getQuizSessions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _quizSessions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final sessions = snapshot.data ?? _quizSessions;
                final recentSessions = sessions.take(5).toList();

                return _isFetchingData
                    ? const Center(child: CircularProgressIndicator())
                    : recentSessions.isEmpty
                    ? const Center(child: Text('Aucune session disponible'))
                    : ListView.builder(
                      itemCount: recentSessions.length,
                      itemBuilder: (context, index) {
                        final session = recentSessions[index];
                        final statusColor =
                            session.isActive
                                ? colorScheme.tertiary
                                : colorScheme.outline;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.quiz, color: statusColor),
                            ),
                            title: Text(
                              session.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Créé le ${_formatDate(session.createdAt)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                session.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onTap:
                                () => setState(() {
                                  _selectedSession = session;
                                }),
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

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 16),
              Text(
                value,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtre et tri
          Row(
            children: [
              const Text(
                'Filtrer par:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Toutes'),
                selected: true,
                onSelected: (selected) {},
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Actives'),
                selected: false,
                onSelected: (selected) {},
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Inactives'),
                selected: false,
                onSelected: (selected) {},
              ),
              const Spacer(),
              DropdownButton<String>(
                value: 'recent',
                items: const [
                  DropdownMenuItem(
                    value: 'recent',
                    child: Text('Plus récentes'),
                  ),
                  DropdownMenuItem(
                    value: 'alphabetical',
                    child: Text('Ordre alphabétique'),
                  ),
                  DropdownMenuItem(value: 'status', child: Text('Par statut')),
                ],
                onChanged: (value) {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Liste des sessions de quiz dans une grille
          Expanded(
            child: StreamBuilder<List<QuizSession>>(
              stream: _quizRepository.getQuizSessions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _quizSessions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final sessions = snapshot.data ?? _quizSessions;

                return _isFetchingData
                    ? const Center(child: CircularProgressIndicator())
                    : sessions.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.quiz,
                            size: 80,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune session de quiz disponible',
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _createNewQuizSession,
                            child: const Text('Créer une session'),
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isSelected = _selectedSession?.id == session.id;

                        return InkWell(
                          onTap:
                              () => setState(() {
                                _selectedSession = session;
                              }),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                          context,
                                        ).colorScheme.outline.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                              color:
                                  isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withOpacity(0.2)
                                      : Theme.of(context).colorScheme.surface,
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            session.isActive
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                    .withOpacity(0.1)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .surfaceVariant
                                                    .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  session.isActive
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.tertiary
                                                      : Theme.of(
                                                        context,
                                                      ).colorScheme.outline,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            session.isActive
                                                ? 'Active'
                                                : 'Inactive',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  session.isActive
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.tertiary
                                                      : Theme.of(
                                                        context,
                                                      ).colorScheme.outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      itemBuilder:
                                          (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Modifier'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'launch',
                                              child: Text('Lancer'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Supprimer'),
                                            ),
                                          ],
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            _editQuizSession(session);
                                            break;
                                          case 'launch':
                                            _launchQuizSession(session);
                                            break;
                                          case 'delete':
                                            _deleteQuizSession(session);
                                            break;
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  session.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                if (session.description != null &&
                                    session.description!.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      session.description!,
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatDate(session.createdAt),
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed:
                                          () => _launchQuizSession(session),
                                      child: const Text('Gérer'),
                                    ),
                                  ],
                                ),
                              ],
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

  Widget _buildSessionDetailsPanel() {
    final session = _selectedSession!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 380,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        color: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entête avec titre et bouton de fermeture
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              color: colorScheme.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Détails de la session',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed:
                      () => setState(() {
                        _selectedSession = null;
                      }),
                ),
              ],
            ),
          ),

          // Contenu avec défilement
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Actions rapides
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchQuizSession(session),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Lancer'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editQuizSession(session),
                          icon: const Icon(Icons.edit),
                          label: const Text('Modifier'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Informations de la session
                  const Text(
                    'Informations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem('Titre', session.title),
                  _buildDetailItem(
                    'Description',
                    session.description ?? 'Aucune description',
                  ),
                  _buildDetailItem(
                    'Statut',
                    session.isActive ? 'Active' : 'Inactive',
                    valueColor:
                        session.isActive
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.outline,
                  ),
                  _buildDetailItem(
                    'Date de création',
                    _formatDate(session.createdAt),
                  ),

                  const SizedBox(height: 24),

                  // Statistiques
                  const Text(
                    'Statistiques',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    icon: Icons.help,
                    title: 'Questions',
                    value: '0',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.people,
                    title: 'Joueurs',
                    value: '0', // À remplacer par les données réelles
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.timer,
                    title: 'Durée estimée',
                    value: '0 min',
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 24),

                  // Danger zone
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zone de danger',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'La suppression de cette session est définitive et ne peut pas être annulée.',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _deleteQuizSession(session),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              child: const Text('Supprimer la session'),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor ?? colorScheme.onSurface,
              fontWeight: valueColor != null ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return StreamBuilder<List<QuizSession>>(
      stream: _quizRepository.getQuizSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _quizSessions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final sessions = snapshot.data ?? _quizSessions;

        return _isFetchingData
            ? const Center(child: CircularProgressIndicator())
            : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Maître du jeu',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _authService.currentUser?.email ??
                                      'Non connecté',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sessions de quiz',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _createNewQuizSession,
                        icon: const Icon(Icons.add),
                        label: const Text('Créer une session'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        sessions.isEmpty
                            ? const Center(
                              child: Text('Aucune session de quiz disponible'),
                            )
                            : ListView.builder(
                              itemCount: sessions.length,
                              itemBuilder: (context, index) {
                                final session = sessions[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    title: Text(
                                      session.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (session.description != null &&
                                            session.description!.isNotEmpty)
                                          Text(
                                            session.description!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                              fontSize: 14,
                                            ),
                                          ),
                                        Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    session.isActive
                                                        ? Theme.of(
                                                          context,
                                                        ).colorScheme.tertiary
                                                        : Theme.of(
                                                          context,
                                                        ).colorScheme.outline,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              session.isActive
                                                  ? 'Active'
                                                  : 'Inactive',
                                            ),
                                            const SizedBox(width: 10),
                                            Icon(
                                              Icons.calendar_today,
                                              size: 12,
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDate(session.createdAt),
                                              style: TextStyle(
                                                color:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          tooltip: 'Edit',
                                          onPressed:
                                              () => _editQuizSession(session),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.play_arrow),
                                          tooltip: 'Launch',
                                          onPressed:
                                              () => _launchQuizSession(session),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          tooltip: 'Delete',
                                          onPressed:
                                              () => _deleteQuizSession(session),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _manageQuizSession(session),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
