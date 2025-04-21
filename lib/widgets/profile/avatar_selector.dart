/// Widget de sélection d'avatar
///
/// Permet à l'utilisateur de sélectionner son avatar parmi les images disponibles
/// avec un affichage en grille et pagination
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/services/avatar_service.dart';

class AvatarSelector extends StatefulWidget {
  final String? currentAvatar;
  final Function(String) onAvatarSelected;
  final double size;

  const AvatarSelector({
    super.key,
    this.currentAvatar,
    required this.onAvatarSelected,
    this.size = 80.0,
  });

  @override
  State<AvatarSelector> createState() => _AvatarSelectorState();
}

class _AvatarSelectorState extends State<AvatarSelector> {
  List<String> _avatars = [];
  bool _isLoading = true;
  String? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.currentAvatar;
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final avatars = await AvatarService.getAvailableAvatars();
      setState(() {
        _avatars = avatars;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_avatars.isEmpty) {
      return Center(child: Text('Aucun avatar disponible'));
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _avatars.length,
              itemBuilder: (context, index) {
                final avatar = _avatars[index];
                final isSelected = _selectedAvatar == avatar;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatar;
                    });
                    widget.onAvatarSelected(avatar);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        avatar,
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.cover,
                      ),
                    ),
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
