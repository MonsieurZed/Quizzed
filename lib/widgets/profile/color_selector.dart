/// Widget de sélection de couleur
///
/// Permet à l'utilisateur de sélectionner une couleur parmi les options disponibles
/// pour le fond de son avatar
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/utils/color_utils.dart';

class ColorSelector extends StatefulWidget {
  final Color? currentColor;
  final Function(Color) onColorSelected;
  final double size;
  final bool isCompact; // Propriété pour le mode compact

  const ColorSelector({
    super.key,
    this.currentColor,
    required this.onColorSelected,
    this.size = 40.0,
    this.isCompact = false, // Par défaut, le mode standard est utilisé
  });

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      // Mode compact avec grille à deux colonnes
      final colors = AppConfig.availableProfileColors;

      return SizedBox(
        width: 100,
        child: SingleChildScrollView(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.0, // espace horizontal entre les couleurs
            runSpacing: 8.0, // espace vertical entre les lignes
            children:
                colors.map((colorOption) {
                  final isSelected = _selectedColor == colorOption.color;
                  // Appliquer l'opacité à la couleur
                  final displayColor = colorOption.color.withOpacity(
                    AppConfig.colorOpacity,
                  );

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorOption.color;
                      });
                      widget.onColorSelected(colorOption.color);
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: displayColor, // Utiliser la couleur avec opacité
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary
                                  .withAlpha((255 * 0.5).toInt()),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child:
                          isSelected
                              ? Center(
                                child: Icon(
                                  Icons.check,
                                  color: colorOption.textColor,
                                  size: 18,
                                ),
                              )
                              : null,
                    ),
                  );
                }).toList(),
          ),
        ),
      );
    } else {
      // Mode standard avec grille à trois colonnes
      return SizedBox(
        height: 200, // Hauteur adaptée pour afficher plusieurs rangées
        child: GridView.builder(
          padding: const EdgeInsets.all(10.0),
          scrollDirection:
              Axis.vertical, // Défilement vertical pour un comportement intuitif
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 colonnes
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0, // Cellules carrées
          ),
          itemCount: AppConfig.availableProfileColors.length,
          itemBuilder: (context, index) {
            final colorOption = AppConfig.availableProfileColors[index];
            final isSelected = _selectedColor == colorOption.color;
            // Appliquer l'opacité à la couleur
            final displayColor = colorOption.color.withOpacity(
              AppConfig.colorOpacity,
            );

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = colorOption.color;
                });
                widget.onColorSelected(colorOption.color);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: displayColor, // Utiliser la couleur avec opacité
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha((255 * 0.5).toInt()),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child:
                    isSelected
                        ? Center(
                          child: Icon(
                            Icons.check,
                            color: colorOption.textColor,
                          ),
                        )
                        : null,
              ),
            );
          },
        ),
      );
    }
  }
}
