/// Create Lobby View
///
/// Vue permettant de créer un nouveau lobby de quiz
/// L'utilisateur peut configurer les paramètres du lobby comme le nom,
/// la visibilité (public/privé), le nombre de joueurs, etc.
library;

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/controllers/lobby_controller.dart';
import 'package:quizzzed/models/quiz/lobby_model.dart';
import 'package:quizzzed/models/user/user_model.dart';
import 'package:quizzzed/routes/app_routes.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/widgets/shared/section_header.dart';

class CreateLobbyView extends StatefulWidget {
  const CreateLobbyView({super.key});

  @override
  State<CreateLobbyView> createState() => _CreateLobbyViewState();
}

class _CreateLobbyViewState extends State<CreateLobbyView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final Random _random = Random();

  LobbyVisibility _visibility = LobbyVisibility.public;
  String _category = 'Général';
  int _maxPlayers = AppConfig.maxPlayersPerLobby;
  int _minPlayers = AppConfig.minPlayersToStart;
  bool _isCreating = false;
  bool _isGeneratingName = false;

  // Listes pour la génération de nom aléatoire
  List<String> _adjectifs = [];
  List<String> _noms = [];

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
  void initState() {
    super.initState();
    _loadDictionaries();
  }

  // Charge les dictionnaires depuis les fichiers JSON
  Future<void> _loadDictionaries() async {
    try {
      // Charger les adjectifs
      final String adjectifsJson = await rootBundle.loadString(
        'assets/dictionary/adjectifs.json',
      );
      _adjectifs = List<String>.from(jsonDecode(adjectifsJson));

      // Charger les noms
      final String nomsJson = await rootBundle.loadString(
        'assets/dictionary/names.json',
      );
      _noms = List<String>.from(jsonDecode(nomsJson));
    } catch (e) {
      debugPrint('Erreur lors du chargement des dictionnaires: $e');
      // Utiliser des listes par défaut en cas d'erreur
      _adjectifs = [
        'Mythique',
        'Épique',
        'Magique',
        'Légendaire',
        'Fantastique',
      ];
      _noms = ['Quiz', 'Défi', 'Combat', 'Challenge', 'Tournoi'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Génère un nom de lobby aléatoire
  String _generateRandomLobbyName() {
    if (_adjectifs.isEmpty || _noms.isEmpty) {
      return 'Quiz Fantastique'; // Nom par défaut si les listes ne sont pas chargées
    }

    final adjectifIndex = _random.nextInt(_adjectifs.length);
    final nomIndex = _random.nextInt(_noms.length);

    return '${_noms[nomIndex]} ${_adjectifs[adjectifIndex]}';
  }

  // Remplit le champ de nom avec un nom aléatoire
  Future<void> _setRandomLobbyName() async {
    setState(() {
      _isGeneratingName = true;
    });

    // Attendre que les dictionnaires soient chargés si ce n'est pas déjà fait
    if (_adjectifs.isEmpty || _noms.isEmpty) {
      await _loadDictionaries();
    }

    setState(() {
      _nameController.text = _generateRandomLobbyName();
      _isGeneratingName = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final UserModel? user = authService.currentUserModel;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SectionHeader(title: 'Informations du lobby'),
          const SizedBox(height: 16),

          // Nom du lobby
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nom du lobby',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.group),
              suffixIcon: IconButton(
                icon: const Icon(Icons.shuffle),
                onPressed: _setRandomLobbyName,
              ),
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
                  subtitle: const Text('Accessible par code uniquement'),
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
                  (AppConfig.maxPlayersPerLobby - AppConfig.minPlayersToStart)
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
    );
  }
}
