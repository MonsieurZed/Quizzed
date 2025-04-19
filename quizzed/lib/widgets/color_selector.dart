import 'package:flutter/material.dart';

class ColorSelector extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorChanged;

  const ColorSelector({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  // Expanded to 20 pastel colors
  static const List<Color> _pastelColors = [
    // Rouge pastel
    Color(0xFFFFC0CB), // Pink
    Color(0xFFFF9AA2), // Light Red
    Color(0xFFFFB7B2), // Salmon
    // Orange pastel
    Color(0xFFFFDAC1), // Peach
    Color(0xFFFFD166), // Light Orange
    Color(0xFFFFE6B3), // Pale Orange
    // Jaune pastel
    Color(0xFFFFF7AD), // Light Yellow
    Color(0xFFFFEE93), // Pastel Yellow
    Color(0xFFFFE066), // Pale Yellow
    // Vert pastel
    Color(0xFFE2F0CB), // Light Lime
    Color(0xFFB5EAD7), // Mint
    Color(0xFF98D8C8), // Light Teal
    Color(0xFF77DD77), // Pastel Green
    // Bleu pastel
    Color(0xFFC7CEEA), // Periwinkle
    Color(0xFF9FD8DF), // Baby Blue
    Color(0xFFAFDAF6), // Sky Blue
    Color(0xFFAEC6CF), // Pastel Blue
    // Indigo/Violet pastel
    Color(0xFFB19CD9), // Light Purple
    Color(0xFFD4BBEB), // Lavender
    Color(0xFFE0BBE4), // Light Violet
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40, // Fixed height for the entire widget
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pastelColors.length,
              itemBuilder: (context, index) {
                final color = _pastelColors[index];
                final isSelected = selectedColor.value == color.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: GestureDetector(
                    onTap: () => onColorChanged(color),
                    child: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 3,
                                    spreadRadius: 0.5,
                                  ),
                                ]
                                : null,
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
