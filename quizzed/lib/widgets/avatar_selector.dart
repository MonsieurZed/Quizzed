import 'package:flutter/material.dart';
import 'package:quizzed/widgets/player_avatar.dart';

class AvatarSelector extends StatefulWidget {
  final String? selectedAvatar;
  final Function(String) onAvatarSelected;
  final List<String> avatarNames;

  const AvatarSelector({
    super.key,
    required this.selectedAvatar,
    required this.onAvatarSelected,
    required this.avatarNames,
  });

  @override
  State<AvatarSelector> createState() => _AvatarSelectorState();
}

class _AvatarSelectorState extends State<AvatarSelector> {
  int _currentPage = 0;
  static const int _itemsPerRow = 5; // More avatars per row
  static const int _rows = 3; // Fewer rows
  static const int _pageSize = _itemsPerRow * _rows; // Total avatars per page

  @override
  Widget build(BuildContext context) {
    // Si la liste des avatars est vide, afficher un message
    if (widget.avatarNames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun avatar disponible',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Tenter de recharger la page
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder:
                        (context) => const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        ),
                  ),
                );
                Future.delayed(const Duration(milliseconds: 300), () {
                  Navigator.of(context).pop();
                });
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    // Calculate total pages
    final totalPages = (widget.avatarNames.length / _pageSize).ceil();

    // Ensure current page is valid
    if (_currentPage >= totalPages) {
      _currentPage = 0;
    }

    // Calculate start and end indices for current page
    final startIndex = _currentPage * _pageSize;
    final endIndex =
        startIndex + _pageSize > widget.avatarNames.length
            ? widget.avatarNames.length
            : startIndex + _pageSize;

    // Get avatars for current page
    final currentPageAvatars = widget.avatarNames.sublist(startIndex, endIndex);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left arrow for navigation
        if (totalPages > 1)
          Container(
            width: 20,
            height: 400, // Hauteur réduite de 400 à 200
            alignment: Alignment.center,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 20,
              ), // Taille réduite
              onPressed:
                  () => setState(() {
                    // Circular navigation: if at first page, go to last page
                    _currentPage =
                        (_currentPage > 0) ? _currentPage - 1 : totalPages - 1;
                  }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 20,
                maxWidth: 20,
                minHeight: 400,
                maxHeight: 400, // Hauteur réduite
              ),
            ),
          ),

        // Avatar grid in a more compact layout
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _itemsPerRow,
                  mainAxisSpacing: 8, // Espacement réduit
                  crossAxisSpacing: 8, // Espacement réduit
                  childAspectRatio: 1,
                  mainAxisExtent: 120, // Hauteur réduite de 120 à 80
                ),
                itemCount: currentPageAvatars.length,
                itemBuilder: (context, index) {
                  final avatarName = currentPageAvatars[index];
                  final isSelected = avatarName == widget.selectedAvatar;

                  return GestureDetector(
                    onTap: () => widget.onAvatarSelected(avatarName),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PlayerAvatar(
                          avatarName: avatarName,
                          backgroundColor:
                              Theme.of(context).colorScheme.onInverseSurface,
                          size: 110, // Taille réduite de 60 à 45
                          isSelected: isSelected,
                          allowOverflow: true,
                          onTap: null, // Handle tap on the column instead
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Right arrow for navigation
        if (totalPages > 1)
          Container(
            width: 20,
            height: 400, // Hauteur réduite correspondant à la flèche gauche
            alignment: Alignment.center,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 20,
              ), // Taille réduite
              onPressed:
                  () => setState(() {
                    // Circular navigation: if at last page, go to first page
                    _currentPage =
                        (_currentPage < totalPages - 1) ? _currentPage + 1 : 0;
                  }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 20,
                maxWidth: 20,
                minHeight: 400,
                maxHeight: 400, // Hauteur réduite
              ),
            ),
          ),
      ],
    );
  }
}
