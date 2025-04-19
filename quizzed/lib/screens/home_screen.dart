import 'package:flutter/material.dart';
import 'package:quizzed/routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final primary = colorScheme.primary;
    final surface = colorScheme.surface;
    final background = colorScheme.background;
    final onPrimary = colorScheme.onPrimary;
    final onSurface = colorScheme.onSurface;
    final onBackground = colorScheme.onBackground;
    final textColor = textTheme.bodyLarge?.color ?? onBackground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzed'),
        centerTitle: true, // Center the app title
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo section
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 150, // Réduit la taille du logo
                        ),
                        const SizedBox(height: 10), // Espace réduit
                        const Text(
                          'Bienvenue sur Quizzed!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22, // Taille réduite
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // App title
                  Text(
                    'QUIZZED',
                    style: textTheme.displayMedium?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                      fontSize: 44,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Tagline
                  Text(
                    'Quiz multijoueur pour la  ZedLAN',
                    style: textTheme.titleMedium?.copyWith(
                      color: onBackground.withOpacity(isDark ? 0.7 : 0.87),
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Player card
                  Card(
                    elevation: 6,
                    margin: const EdgeInsets.only(bottom: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    color: surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.people, size: 48, color: primary),
                          const SizedBox(height: 18),
                          Text(
                            'Rejoindre en tant que joueur',
                            style: textTheme.titleLarge?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Participez au quiz et affrontez vos amis',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.playerLogin,
                                );
                              },
                              label: const Text('REJOINDRE LA PARTIE'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                backgroundColor: primary,
                                foregroundColor: onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Admin card
                  Card(
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    color: surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 48,
                            color: primary,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Accès maître du jeu',
                            style: textTheme.titleLarge?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Créez et gérez les sessions de quiz',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.lock_open),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.adminLogin,
                                );
                              },
                              label: const Text('ACCÈS ADMIN'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                backgroundColor: primary,
                                foregroundColor: onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Footer
                  Text(
                    '© 2025 Quizzed',
                    style: textTheme.bodySmall?.copyWith(
                      color: onBackground.withOpacity(0.24),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
