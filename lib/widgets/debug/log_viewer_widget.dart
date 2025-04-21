/// Widget de visualisation des logs
///
/// Affiche les logs stockés dans le LoggerService avec des options de filtrage
/// et un système de coloration par niveau de gravité pour faciliter le débogage
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quizzzed/services/logger_service.dart';

class LogViewerWidget extends StatefulWidget {
  const LogViewerWidget({super.key});

  @override
  State<LogViewerWidget> createState() => _LogViewerWidgetState();
}

class _LogViewerWidgetState extends State<LogViewerWidget> {
  final LoggerService _logger = LoggerService();

  // État local
  List<LogEntry> _displayedLogs = [];
  String _filterText = '';
  LogLevel _minLevel = LogLevel.debug;
  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  // Liste de tags uniques pour le filtre
  List<String> _availableTags = [];
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    _updateLogs();

    // Rafraîchissement périodique des logs (toutes les secondes)
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateLogs();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateLogs() {
    setState(() {
      // Filtrer les logs selon les critères actuels
      _displayedLogs = _logger.getFilteredLogs(
        minLevel: _minLevel,
        tag: _selectedTag,
        containsText: _filterText.isEmpty ? null : _filterText,
      );

      // Extraire les tags uniques
      _availableTags =
          _logger.logHistory.map((log) => log.tag).toSet().toList()..sort();

      // Faire défiler automatiquement vers le bas si activé
      if (_autoScroll && _displayedLogs.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  // Obtenir la couleur correspondant au niveau de log
  Color _getLevelColor(LogLevel level) {
    return switch (level) {
      LogLevel.debug => Colors.grey,
      LogLevel.info => Colors.green,
      LogLevel.warning => Colors.orange,
      LogLevel.error => Colors.red,
      LogLevel.critical => Colors.purple,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // En-tête avec options et filtres
        Container(
          padding: const EdgeInsets.all(8),
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Visualiseur de logs', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),

              // Barre de filtre texte
              TextField(
                decoration: InputDecoration(
                  hintText: 'Filtrer par texte...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withAlpha((255 * 0.3).toInt()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _filterText = value;
                    _updateLogs();
                  });
                },
              ),

              const SizedBox(height: 8),

              // Options de filtrage
              Row(
                children: [
                  // Niveau minimum
                  DropdownButton<LogLevel>(
                    value: _minLevel,
                    hint: const Text('Niveau'),
                    onChanged: (LogLevel? value) {
                      if (value != null) {
                        setState(() {
                          _minLevel = value;
                          _updateLogs();
                        });
                      }
                    },
                    items:
                        LogLevel.values.map((level) {
                          return DropdownMenuItem<LogLevel>(
                            value: level,
                            child: Text(
                              level.toString().split('.').last.toUpperCase(),
                              style: TextStyle(color: _getLevelColor(level)),
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(width: 16),

                  // Filtre par tag
                  DropdownButton<String?>(
                    value: _selectedTag,
                    hint: const Text('Tag'),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedTag = value;
                        _updateLogs();
                      });
                    },
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tous les tags'),
                      ),
                      ..._availableTags.map((tag) {
                        return DropdownMenuItem<String>(
                          value: tag,
                          child: Text(tag),
                        );
                      }),
                    ],
                  ),

                  const Spacer(),

                  // Option d'auto-scroll
                  Row(
                    children: [
                      const Text('Auto-scroll'),
                      const SizedBox(width: 4),
                      Switch(
                        value: _autoScroll,
                        onChanged: (value) {
                          setState(() {
                            _autoScroll = value;
                          });
                        },
                      ),
                    ],
                  ),

                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualiser',
                    onPressed: _updateLogs,
                  ),

                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Effacer les logs',
                    onPressed: () {
                      _logger.clearHistory();
                      _updateLogs();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Liste des logs
        Expanded(
          child:
              _displayedLogs.isEmpty
                  ? Center(
                    child: Text(
                      'Aucun log à afficher',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(
                          (255 * 0.6).toInt(),
                        ),
                      ),
                    ),
                  )
                  : ListView.builder(
                    controller: _scrollController,
                    itemCount: _displayedLogs.length,
                    itemBuilder: (context, index) {
                      final log = _displayedLogs[index];
                      return LogEntryTile(
                        log: log,
                        backgroundColor:
                            index % 2 == 0
                                ? theme.colorScheme.surface
                                : theme.colorScheme.surfaceContainerHighest
                                    .withAlpha((0.3 * 255).toInt()),
                      );
                    },
                  ),
        ),

        // Barre d'état
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Text('${_displayedLogs.length} logs affichés'),
              const Spacer(),
              Text(
                'Quizzzed - Debug Console',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (255 * 0.6).toInt(),
                  ),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LogEntryTile extends StatelessWidget {
  final LogEntry log;
  final Color backgroundColor;

  const LogEntryTile({
    super.key,
    required this.log,
    required this.backgroundColor,
  });

  Color _getLevelColor(LogLevel level) {
    return switch (level) {
      LogLevel.debug => Colors.grey,
      LogLevel.info => Colors.green,
      LogLevel.warning => Colors.orange,
      LogLevel.error => Colors.red,
      LogLevel.critical => Colors.purple,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelColor = _getLevelColor(log.level);

    return ExpansionTile(
      backgroundColor: backgroundColor,
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: levelColor.withAlpha((255 * 0.2).toInt()),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: levelColor, width: 2),
        ),
        child: Center(
          child: Text(
            log.levelString[0],
            style: TextStyle(color: levelColor, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      title: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '[${log.formattedTimestamp}] ',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(
                  (255 * 0.6).toInt(),
                ),
                fontFamily: 'monospace',
              ),
            ),
            TextSpan(
              text: log.message,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      subtitle: Text(
        log.tag,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontStyle: FontStyle.italic,
        ),
      ),
      children: [
        // Détails du log
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(
            (255 * 0.3).toInt(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (log.data != null) ...[
                Text(
                  'Données:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(top: 4, bottom: 12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    log.data.toString(),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
              if (log.stackTrace != null) ...[
                Text(
                  'Stack Trace:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(top: 4),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    log.stackTrace.toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
