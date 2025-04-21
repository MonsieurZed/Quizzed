// filepath: d:\GIT\quizzzed\lib\widgets\shared\section_header.dart
/// Section Header
///
/// Widget pour afficher un en-tête de section avec un titre
/// et éventuellement un bouton d'action
library;

import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding = EdgeInsets.zero,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: textStyle ?? defaultStyle),
          if (action != null) action!,
        ],
      ),
    );
  }
}
