import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Notifier global pour les changements de thème
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);
final Color seedColor = const Color.fromARGB(45, 108, 179, 254);
// final Color seedColorLightOverload = const Color.fromARGB(255, 100, 159, 156);

class ThemeService {
  // Obtenir le thème actuel
  static Future<ThemeMode> getThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int themeMode = prefs.getInt('themeMode') ?? 0;
    return ThemeMode.values[themeMode];
  }

  // Sauvegarder le thème
  static Future<void> saveThemeMode(ThemeMode themeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeMode.index);
    // Mettre à jour le notificateur global
    themeModeNotifier.value = themeMode;
  }

  // Basculer entre les thèmes
  static Future<ThemeMode> toggleThemeMode() async {
    ThemeMode currentThemeMode = await getThemeMode();
    ThemeMode newThemeMode =
        currentThemeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await saveThemeMode(newThemeMode);
    return newThemeMode;
  }

  // Créer le thème clair
  static ThemeData getLightTheme() {
    // Utilisation de ColorScheme.fromSeed pour générer toute la palette
    // à partir de la couleur de base (seed color)
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      // primaryContainer: seedColorLightOverload,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      // Correction de la couleur d'arrière-plan
      scaffoldBackgroundColor: colorScheme.surface,
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      textTheme: TextTheme(
        // Remplacer onBackground par onSurface pour éviter la dépréciation
        bodyLarge: TextStyle(color: colorScheme.onSurface),
        bodyMedium: TextStyle(color: colorScheme.onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
    );
  }

  // Créer le thème sombre
  static ThemeData getDarkTheme() {
    // Utilisation de ColorScheme.fromSeed pour le thème sombre
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor, // Même couleur de base pour garantir la cohérence
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      // Correction de la couleur d'arrière-plan
      scaffoldBackgroundColor: colorScheme.surface,
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      textTheme: TextTheme(
        // Remplacer onBackground par onSurface pour éviter la dépréciation
        bodyLarge: TextStyle(color: colorScheme.onSurface),
        bodyMedium: TextStyle(color: colorScheme.onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
    );
  }
}
