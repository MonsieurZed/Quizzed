/// Widget de sélection de couleur
///
/// Permet à l'utilisateur de sélectionner une couleur parmi les options disponibles
/// pour le fond de son avatar

import 'package:flutter/material.dart';
import 'package:quizzzed/models/user/profile_color.dart';

class ColorSelector extends StatefulWidget {
  final String? currentColor;
  final Function(String) onColorSelected;
  final double size;

  const ColorSelector({
    Key? key,
    this.currentColor,
    required this.onColorSelected,
    this.size = 40.0,
  }) : super(key: key);

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
    return Container(
      height: 150,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Choisissez la couleur de fond',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
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
