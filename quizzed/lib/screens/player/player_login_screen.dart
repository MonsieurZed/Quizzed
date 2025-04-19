import 'package:flutter/material.dart';
import 'package:quizzed/routes/app_routes.dart';
import 'package:quizzed/services/asset_service.dart';
import 'package:quizzed/services/logging_service.dart';
import 'package:quizzed/widgets/avatar_selector.dart';
import 'package:quizzed/widgets/color_selector.dart';
import 'package:quizzed/widgets/player_avatar.dart';

class PlayerLoginScreen extends StatefulWidget {
  const PlayerLoginScreen({super.key});

  @override
  State<PlayerLoginScreen> createState() => _PlayerLoginScreenState();
}

class _PlayerLoginScreenState extends State<PlayerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final LoggingService _logger = LoggingService();
  final TextEditingController _nicknameController = TextEditingController();
  String? _selectedAvatar;
  Color _selectedColor = const Color(0xFFB5EAD7); // Default pastel color
  List<String> _avatarNames = []; // Will be populated from assets
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _logger.logInfo(
      'Player login screen initialized',
      'PlayerLoginScreen.initState',
    );
    // Load avatars from assets
    _loadAvatars();
  }

  // Load available avatars dynamically from asset directory
  Future<void> _loadAvatars() async {
    try {
      final List<String> avatars = await AssetService.getAvatarNames();
      setState(() {
        _avatarNames = avatars;
        _selectedAvatar = avatars.isNotEmpty ? avatars[0] : null;
        _isLoading = false;
      });
      _logger.logInfo(
        'Loaded ${avatars.length} avatars from assets',
        'PlayerLoginScreen._loadAvatars',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error loading avatars',
        e,
        stackTrace,
        'PlayerLoginScreen._loadAvatars',
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _logger.logInfo(
      'Player login screen disposed',
      'PlayerLoginScreen.dispose',
    );
    _nicknameController.dispose();
    super.dispose();
  }

  void _joinGame() {
    if (_formKey.currentState!.validate() && _selectedAvatar != null) {
      try {
        final nickname = _nicknameController.text;
        final colorHex =
            '#${_selectedColor.value.toRadixString(16).substring(2)}';

        _logger.logInfo(
          'Player joining game - Nickname: $nickname, Avatar: $_selectedAvatar, Color: $colorHex',
          'PlayerLoginScreen._joinGame',
        );

        Navigator.pushNamed(
          context,
          AppRoutes.quizLobby,
          arguments: {
            'nickname': nickname,
            'avatar': _selectedAvatar,
            'color': _selectedColor,
          },
        );

        _logger.logInfo(
          'Player $nickname navigated to quiz lobby',
          'PlayerLoginScreen._joinGame',
        );
      } catch (e, stackTrace) {
        _logger.logError(
          'Error joining game',
          e,
          stackTrace,
          'PlayerLoginScreen._joinGame',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Une erreur est survenue. Veuillez réessayer.'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
    } else if (_selectedAvatar == null) {
      _logger.logWarning(
        'Join game attempt without avatar selection',
        'PlayerLoginScreen._joinGame',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner un avatar'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive calculations
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 900;

    // Si aucun avatar n'est encore chargé, on affiche un état de chargement
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rejoindre la partie'),
          toolbarHeight: 48,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des avatars...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejoindre la partie'),
        // Make app bar more compact
        toolbarHeight: 48,
      ),
      body: SafeArea(
        // Use LayoutBuilder to fit content to available space
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 700 : 500,
                  maxHeight:
                      constraints.maxHeight * 0.95, // Use available height
                ),
                child: Card(
                  elevation: 4.0,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with avatar preview
                        _buildHeader(context),

                        // Main content in a more efficient layout
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .center, // Changed from stretch to center
                              children: [
                                // Color selector avec espacement réduit
                                const SizedBox(height: 50),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                  ), // Réduction du padding top
                                  child: ColorSelector(
                                    selectedColor: _selectedColor,
                                    onColorChanged: (color) {
                                      setState(() {
                                        _selectedColor = color;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 4), // Espace réduit
                                // Avatar selector avec une proportion plus équilibrée
                                Expanded(
                                  child: AvatarSelector(
                                    selectedAvatar: _selectedAvatar,
                                    onAvatarSelected: (avatar) {
                                      setState(() {
                                        _selectedAvatar = avatar;
                                      });
                                    },
                                    avatarNames: _avatarNames,
                                  ),
                                ),
                                const SizedBox(height: 4), // Espace réduit
                                _buildNicknameField(),
                                const SizedBox(height: 50), // Espace réduit
                                // Join game button at the bottom with minimum spacing
                                FilledButton(
                                  onPressed: _joinGame,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 100,
                                    ),
                                  ),

                                  child: const Text(
                                    ' Rejoindre la partie ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 50),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Header with preview of selected avatar and color
  Widget _buildHeader(BuildContext context) {
    // Vérifier si un avatar est disponible pour l'aperçu
    final bool hasAvatar = _selectedAvatar != null && _avatarNames.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              // N'afficher l'avatar que s'il est disponible
              if (hasAvatar)
                PlayerAvatar(
                  avatarName: _selectedAvatar!,
                  backgroundColor: _selectedColor,
                  size: 150,
                  isSelected: false,
                )
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              const SizedBox(height: 10),
            ],
          ),
          const SizedBox(width: 10),
          if (_nicknameController.text.isNotEmpty)
            Text(
              _nicknameController.text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  // Compact nickname field
  Widget _buildNicknameField() {
    return Container(
      alignment: Alignment.center,
      width: 300, // Fixed width for consistent centering
      child: TextFormField(
        controller: _nicknameController,
        decoration: const InputDecoration(
          labelText: 'Pseudo',
          hintText: 'Entrez votre pseudo',
          prefixIcon: Icon(Icons.person),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          isDense: true, // Make the field more compact
        ),
        textAlign: TextAlign.center, // Center text input
        style: const TextStyle(fontSize: 14),
        onChanged: (_) => setState(() {}), // Update preview when text changes
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
    );
  }
}
