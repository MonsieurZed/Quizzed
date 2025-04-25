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
import 'package:quizzzed/controllers/lobby/lobby_controller.dart';
import 'package:quizzzed/models/lobby/lobby_model.dart';
import 'package:quizzzed/routes/app_routes.dart';
import 'package:quizzzed/services/validation_service.dart';
import 'package:quizzzed/widgets/shared/section_header.dart';

class CreateLobbyView extends StatefulWidget {
  final LobbyModel?
  lobbyToEdit; // Paramètre optionnel pour l'édition d'un lobby existant

  const CreateLobbyView({super.key, this.lobbyToEdit});

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
  bool _isEditing = false;
  // ignore: unused_field
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

    // Déterminer si nous éditons un lobby existant
    _isEditing = widget.lobbyToEdit != null;

    // Si nous éditons un lobby existant, initialiser les contrôleurs
    if (_isEditing && widget.lobbyToEdit != null) {
      _initializeFormWithLobby(widget.lobbyToEdit!);
    }
  }

  // Initialise les champs du formulaire avec les données du lobby existant
  void _initializeFormWithLobby(LobbyModel lobby) {
    _nameController.text = lobby.name;
    _visibility = lobby.visibility;

    // Trouver la catégorie correspondante ou utiliser la première par défaut
    if (_categories.contains(lobby.category)) {
      _category = lobby.category;
    } else if (lobby.category.isNotEmpty) {
      // Ajouter la catégorie si elle n'existe pas dans la liste
      _categories.add(lobby.category);
      _category = lobby.category;
    }

    _maxPlayers = lobby.maxPlayers;
    _minPlayers = lobby.minPlayers;
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

  Future<void> _createOrUpdateLobby() async {
    // Générer un nom aléatoire si le champ est vide
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = _generateRandomLobbyName();
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final lobbyController = Provider.of<LobbyController>(
        context,
        listen: false,
      );

      String? lobbyId;

      if (_isEditing && widget.lobbyToEdit != null) {
        // Mode édition: mettre à jour le lobby existant
        final updatedLobby = widget.lobbyToEdit!.copyWith(
          name: _nameController.text.trim(),
          category: _category,
          maxPlayers: _maxPlayers,
          minPlayers: _minPlayers,
          visibility: _visibility,
        );

        final success = await lobbyController.updateLobby(
          updatedLobby,
          lobbyId: widget.lobbyToEdit!.id,
        );

        if (success && mounted) {
          // Revenir au détail du lobby
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lobby mis à jour avec succès')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la mise à jour du lobby'),
            ),
          );
        }
      } else {
        // Mode création: créer un nouveau lobby
        lobbyId = await lobbyController.createLobby(
          name: _nameController.text.trim(),
          description:
              _category, // Utilisation de la catégorie comme description
          maxPlayers: _maxPlayers,
          visibility: _visibility,
          joinPolicy: LobbyJoinPolicy.open, // Par défaut: lobby ouvert
          accessCode:
              _visibility == LobbyVisibility.private
                  ? null
                  : '', // Génération automatique si privé
          quizId:
              null, // Sera défini ultérieurement lors de la sélection d'un quiz
        );

        if (lobbyId != null && mounted) {
          // Rediriger vers le lobby créé
          context.pushReplacementNamed(
            AppRoutes.lobbyDetail,
            pathParameters: {'id': lobbyId},
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la création du lobby'),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Générer un hint pour le champ de nom
    final String randomNameHint = _generateRandomLobbyName();

    // Adapte le titre en fonction du mode d'édition ou de création
    final String title = _isEditing ? 'Modifier le lobby' : 'Créer un lobby';

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // En-tête avec bouton de retour si en mode édition
          if (_isEditing)
            AppBar(
              title: Text(title),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.onBackground,
            ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Afficher le titre seulement si pas en mode édition (pour éviter la duplication)
                if (!_isEditing) SectionHeader(title: title),
                const SizedBox(height: 16),

                // Carte pour les informations de base
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nom du lobby
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nom du lobby',
                            hintText: 'Ex: $randomNameHint',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.group),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.shuffle),
                              tooltip: 'Générer un nom aléatoire',
                              onPressed: _setRandomLobbyName,
                            ),
                          ),
                          maxLength: 30,
                          validator: ValidationService.validateLobbyName,
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Carte pour les paramètres de visibilité
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Visibilité'),
                        const SizedBox(height: 8),

                        // Options de visibilité en colonnes au lieu de rangées
                        RadioListTile<LobbyVisibility>(
                          title: const Text('Public'),
                          subtitle: const Text('Visible par tous les joueurs'),
                          value: LobbyVisibility.public,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          groupValue: _visibility,
                          onChanged: (LobbyVisibility? value) {
                            if (value != null) {
                              setState(() {
                                _visibility = value;
                              });
                            }
                          },
                        ),

                        RadioListTile<LobbyVisibility>(
                          title: const Text('Privé'),
                          subtitle: const Text(
                            'Accessible par code uniquement',
                          ),
                          value: LobbyVisibility.private,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          groupValue: _visibility,
                          onChanged: (LobbyVisibility? value) {
                            if (value != null) {
                              setState(() {
                                _visibility = value;
                              });
                            }
                          },
                        ),

                        if (_visibility == LobbyVisibility.private)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Un code d\'accès sera généré automatiquement',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Carte pour les paramètres de joueurs
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Paramètres de joueurs'),
                        const SizedBox(height: 16),

                        // Nombre maximum de joueurs
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Nombre maximum de joueurs'),
                                Text(
                                  _maxPlayers.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _maxPlayers.toDouble(),
                              min: AppConfig.minPlayersToStart.toDouble(),
                              max: AppConfig.maxPlayersPerLobby.toDouble(),
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
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Nombre minimum de joueurs
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Nombre minimum pour démarrer'),
                                Text(
                                  _minPlayers.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Bouton de création
                ElevatedButton(
                  onPressed: _isCreating ? null : _createOrUpdateLobby,
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
                          : Text(
                            _isEditing
                                ? 'Mettre à jour le lobby'
                                : 'Créer le lobby',
                            style: const TextStyle(fontSize: 18),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
