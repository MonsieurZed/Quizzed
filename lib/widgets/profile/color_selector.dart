/// Widget de sélection de couleur
///
/// Permet à l'utilisateur de sélectionner une couleur parmi les options disponibles
/// pour le fond de son avatar
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/models/user/profile_color.dart';

class ColorSelector extends StatefulWidget {
  final String? currentColor;
  final Function(String) onColorSelected;
  final double size;
  final bool isCompact; // Nouvelle propriété pour le mode compact

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
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      // Mode compact avec grille à deux colonnes
      final colors = ProfileColor.availableColors;

      return Container(
        width: 100,
        child: SingleChildScrollView(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.0, // espace horizontal entre les couleurs
            runSpacing: 8.0, // espace vertical entre les lignes
            children:
                colors.map((colorOption) {
                  final isSelected = _selectedColor == colorOption.name;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorOption.name;
                      });
                      widget.onColorSelected(colorOption.name);
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colorOption.color,
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
      // Mode standard avec grille horizontale
      return SizedBox(
        height: 60,
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16.0),
                scrollDirection: Axis.horizontal,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: ProfileColor.availableColors.length,
                itemBuilder: (context, index) {
                  final colorOption = ProfileColor.availableColors[index];
                  final isSelected = _selectedColor == colorOption.name;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorOption.name;
                      });
                      widget.onColorSelected(colorOption.name);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorOption.color,
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
                                ),
                              )
                              : null,
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
}
