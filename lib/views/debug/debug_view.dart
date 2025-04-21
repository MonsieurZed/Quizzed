/// Vue de débogage
///
/// Interface permettant d'accéder aux outils de débogage de l'application
/// comme le visualiseur de logs, les états des services et des options de test

import 'package:flutter/material.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:quizzzed/widgets/debug/log_viewer_widget.dart';

class DebugView extends StatefulWidget {
  const DebugView({Key? key}) : super(key: key);

  @override
  State<DebugView> createState() => _DebugViewState();
}

class _DebugViewState extends State<DebugView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LoggerService _loggerService = LoggerService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Enregistrer quelques logs de test pour démontrer le fonctionnement
    _logDemoEntries();
  }

  void _logDemoEntries() {
    _loggerService.debug('Application lancée en mode debug', tag: 'SYSTEM');
    _loggerService.info('Bienvenue dans la console de débogage', tag: 'DEBUG');
    _loggerService.warning(
      'Ceci est un exemple d\'avertissement',
      tag: 'TEST',
      data: {'example': true},
    );
    _loggerService.error(
      'Exemple d\'erreur avec stack trace',
      tag: 'DEMO',
      data: Exception('Erreur de démonstration'),
      stackTrace: StackTrace.current,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateTestLogs() {
    _loggerService.debug('Log de débogage généré manuellement', tag: 'TEST');
    _loggerService.info(
      'Information de test avec données',
      tag: 'TEST',
      data: {'timestamp': DateTime.now().toIso8601String()},
    );
    _loggerService.warning('Attention: ceci est un test', tag: 'TEST');

    try {
      // Générer une erreur intentionnelle pour démontrer la capture de stack trace
      final list = <int>[];
      list[10] = 0; // Hors limites
    } catch (e, stackTrace) {
      _loggerService.error(
        'Erreur interceptée lors du test',
        tag: 'TEST',
        data: e,
        stackTrace: stackTrace,
      );
    }

    _loggerService.critical('Erreur critique simulée', tag: 'TEST');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs de test générés avec succès')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Débogage'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Logs', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Outils', icon: Icon(Icons.build)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Logs
          const LogViewerWidget(),

          // Onglet Outils de débogage
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outils de débogage',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                // Groupe: Logger
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long),
                            const SizedBox(width: 8),
                            Text('Logger', style: theme.textTheme.titleLarge),
                          ],
                        ),
                        const Divider(),
                        const Text(
                          'Options de journalisation et de test des logs',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _generateTestLogs,
                              icon: const Icon(Icons.add_comment),
                              label: const Text('Générer des logs de test'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                _loggerService.clearHistory();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Historique des logs effacé'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Effacer les logs'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Configuration de l'environnement
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.settings),
                            const SizedBox(width: 8),
                            Text(
                              'Configuration',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const Divider(),
                        const Text(
                          'Options de configuration du service de journalisation',
                        ),
                        const SizedBox(height: 16),

                        // Niveaux de log
                        DropdownButtonFormField<LogLevel>(
                          decoration: const InputDecoration(
                            labelText: 'Niveau minimum de log',
                            border: OutlineInputBorder(),
                          ),
                          value: _loggerService.minLevel,
                          onChanged: (LogLevel? newValue) {
                            if (newValue != null) {
                              _loggerService.configure(minLevel: newValue);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Niveau minimum défini sur ${newValue.toString().split('.').last}',
                                  ),
                                ),
                              );
                            }
                          },
                          items:
                              LogLevel.values.map((level) {
                                return DropdownMenuItem<LogLevel>(
                                  value: level,
                                  child: Text(
                                    level
                                        .toString()
                                        .split('.')
                                        .last
                                        .toUpperCase(),
                                  ),
                                );
                              }).toList(),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Note: Ces paramètres sont réinitialisés au redémarrage de l\'application',
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Informations de version
                Center(
                  child: Text(
                    'Quizzzed - Version de débogage',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(
                        (255 * 0.6).toInt(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
