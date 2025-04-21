/// Theme Service
///
/// Gère l'apparence visuelle de l'application
/// Fournit les thèmes clair/sombre et les styles communs

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeService extends ChangeNotifier {
  // Singleton pattern
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  // Mode sombre par défaut à false
  bool _isDarkMode = false;

  // Getters
  bool get isDarkMode => _isDarkMode;
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  // Couleurs principales de l'application pour générer les schemes
  static const Color primarySeedColor = Color(0xFF6750A4);
  static const Color secondarySeedColor = Color(0xFF7D5260);
  static const Color tertiarySeedColor = Color(0xFF625B71);
  static const Color errorColor = Color(0xFFB3261E);

  // Couleurs spécifiques
  static const Color backgroundColorLight = Color(0xFFF6F6FA);
  static const Color backgroundColorDark = Color(0xFF1B1B1F);
  static const Color cardColorLight = Colors.white;
  static const Color cardColorDark = Color(0xFF2B2B30);

  // Configuration des thèmes avec ColorScheme.fromSeed
  final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySeedColor,
      secondary: secondarySeedColor,
      tertiary: tertiarySeedColor,
      error: errorColor,
      brightness: Brightness.light,
      background: backgroundColorLight,
      // Paramètres additionnels pour personnaliser chaque teinte
      primaryContainer: primarySeedColor.withAlpha((255 * 0.1).toInt()),
      secondaryContainer: secondarySeedColor.withAlpha((255 * 0.1).toInt()),
      tertiaryContainer: tertiarySeedColor.withAlpha((255 * 0.1).toInt()),
      surface: Colors.white,
      surfaceTint: primarySeedColor.withOpacity(0.05),
    ),
    scaffoldBackgroundColor: backgroundColorLight,
    cardTheme: const CardTheme(
      color: cardColorLight,
      elevation: 2,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    textTheme: GoogleFonts.nunitoSansTextTheme(ThemeData.light().textTheme),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor:
          ColorScheme.fromSeed(
            seedColor: primarySeedColor,
            brightness: Brightness.light,
          ).primaryContainer,
      foregroundColor:
          ColorScheme.fromSeed(
            seedColor: primarySeedColor,
            brightness: Brightness.light,
          ).onPrimaryContainer,
      elevation: 0,
      centerTitle: true,
    ),
  );

  final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySeedColor,
      secondary: secondarySeedColor,
      tertiary: tertiarySeedColor,
      error: errorColor,
      brightness: Brightness.dark,
      background: backgroundColorDark,
      // Paramètres additionnels pour personnaliser chaque teinte
      primaryContainer: primarySeedColor.withAlpha((255 * 0.3).toInt()),
      secondaryContainer: secondarySeedColor.withAlpha((255 * 0.3).toInt()),
      tertiaryContainer: tertiarySeedColor.withAlpha((255 * 0.3).toInt()),
      surface: const Color(0xFF252529),
      surfaceTint: primarySeedColor.withAlpha((255 * 0.1).toInt()),
    ),
    scaffoldBackgroundColor: backgroundColorDark,
    cardTheme: const CardTheme(
      color: cardColorDark,
      elevation: 2,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    textTheme: GoogleFonts.nunitoSansTextTheme(ThemeData.dark().textTheme),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor:
          ColorScheme.fromSeed(
            seedColor: primarySeedColor,
            brightness: Brightness.dark,
          ).primaryContainer,
      foregroundColor:
          ColorScheme.fromSeed(
            seedColor: primarySeedColor,
            brightness: Brightness.dark,
          ).onPrimaryContainer,
      elevation: 0,
      centerTitle: true,
    ),
  );

  // Bascule entre les modes clair et sombre
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Définit explicitement un mode
  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
    }
  }

  // Styles communs
  static TextStyle get headingStyle =>
      const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);

  static TextStyle get subtitleStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.grey,
  );

  // Styles de boutons adaptés au thème
  ButtonStyle getElevatedButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );

  ButtonStyle getOutlinedButtonStyle(BuildContext context) =>
      OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
}
