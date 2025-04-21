/// Widget de carte de catégorie de quiz
///
/// Affiche une catégorie de quiz avec une image et un titre
/// Utilisé dans la page d'accueil et dans la vue des catégories
library;

import 'package:flutter/material.dart';

class QuizCategoryCard extends StatelessWidget {
  final String category;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isSelected;

  const QuizCategoryCard({
    super.key,
    required this.category,
    this.imageUrl,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? theme.colorScheme.primary.withAlpha((255 * 0.1).toInt())
                    : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withAlpha(
                        (255 * 0.5).toInt(),
                      ),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withAlpha((255 * 0.1).toInt()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          color: theme.colorScheme.primary.withAlpha(
                            (255 * 0.2).toInt(),
                          ),
                          child: Icon(
                            Icons.category,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 16),
              ] else ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(
                      (255 * 0.2).toInt(),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.category, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  category,
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
