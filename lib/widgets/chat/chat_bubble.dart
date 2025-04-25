/// Widget de bulle de tchat
///
/// Affiche un message individuel dans le tchat
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quizzzed/models/chat/chat_message_model.dart';
import 'package:quizzzed/utils/color_utils.dart';
import 'package:quizzzed/widgets/profile/avatar_preview.dart';

/// Widget qui affiche une bulle de message dans l'interface de chat
class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isCurrentUser;
  final bool showAvatar;
  final bool showTime;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.showAvatar = true,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Vérifier si c'est un message système (userId == 'system')
    final isSystemMessage = message.userId == 'system';

    // Utiliser la couleur de profil de l'utilisateur si disponible
    Color bubbleColor;
    Color textColor;

    if (isSystemMessage) {
      // Style spécifique pour les messages système
      bubbleColor = theme.colorScheme.primary.withOpacity(0.1);
      textColor = theme.colorScheme.primary;
    } else if (isCurrentUser) {
      // Pour l'utilisateur actuel, on utilise toujours la couleur du thème
      // pour faciliter la distinction entre messages envoyés et reçus
      bubbleColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    } else {
      // Pour les autres utilisateurs, utiliser leur couleur de profil si disponible
      if (message.color != null && message.color!.isNotEmpty) {
        final profileColor = ColorUtils.getProfileColorByName(message.color!);
        if (profileColor != null) {
          bubbleColor = profileColor.color.withOpacity(
            0.7,
          ); // Légèrement transparent pour meilleure lisibilité
          textColor = profileColor.textColor;
        } else {
          bubbleColor = theme.colorScheme.surfaceVariant;
          textColor = theme.colorScheme.onSurfaceVariant;
        }
      } else {
        bubbleColor = theme.colorScheme.surfaceVariant;
        textColor = theme.colorScheme.onSurfaceVariant;
      }
    }

    final timeTextColor = textColor.withAlpha((0.7 * 255).toInt());

    // Déterminer la couleur d'arrière-plan de l'avatar
    if (message.color != null && message.color!.isNotEmpty) {
      final profileColor = ColorUtils.getProfileColorByName(message.color!);
      if (profileColor != null) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 2.0,
      ), // Espacement réduit entre les bulles
      child:
          isSystemMessage
              ? _buildSystemMessage(
                context,
                theme,
                bubbleColor,
                textColor,
                timeTextColor,
              )
              : _buildUserMessage(theme, bubbleColor, textColor, timeTextColor),
    );
  }

  /// Construit l'UI pour un message système (centré avec style distinct)
  Widget _buildSystemMessage(
    BuildContext context,
    ThemeData theme,
    Color bubbleColor,
    Color textColor,
    Color timeTextColor,
  ) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            if (showTime)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  _formatTime(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: timeTextColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Construit l'UI pour un message utilisateur standard
  Widget _buildUserMessage(
    ThemeData theme,
    Color bubbleColor,
    Color textColor,
    Color timeTextColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment:
          isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        // Contenu du message
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.05).toInt()),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              child: Column(
                crossAxisAlignment:
                    isCurrentUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                children: [
                  // En-tête avec avatar et nom (si ce n'est pas un message de l'utilisateur actuel)
                  if (!isCurrentUser && showAvatar)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AvatarDisplay(
                          avatar: message.avatar ?? '',
                          size:
                              24, // Plus petit avatar car intégré dans la bulle
                          color:
                              message.color != null
                                  ? ColorUtils.getProfileColorByName(
                                    message.color!,
                                  )?.color
                                  : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          message.userName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),

                  // Espace si un en-tête est affiché
                  if (!isCurrentUser && showAvatar) const SizedBox(height: 6),

                  // Contenu du message
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                    ),
                  ),

                  // Heure d'envoi (intégrée dans la bulle)
                  if (showTime)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        _formatTime(message.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: timeTextColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }
}
