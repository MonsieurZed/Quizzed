/// Vue des paramètres
///
/// Affiche les paramètres de l'utilisateur, notamment la gestion du profil
/// et d'autres options de configuration
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/logger_service.dart';
import 'package:quizzzed/theme/theme_service.dart';
import 'package:quizzzed/services/validation_service.dart';
import 'package:quizzzed/widgets/auth/auth_button.dart';
import 'package:quizzzed/widgets/auth/auth_text_field.dart';
import 'package:quizzzed/widgets/profile/avatar_preview.dart';
import 'package:quizzzed/widgets/profile/avatar_selector.dart';
import 'package:quizzzed/widgets/profile/color_selector.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  bool _isProfileExpanded = false;
  final logTag = 'SettingsContent';
  final logger = LoggerService();

  // Controllers pour l'édition du profil
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedAvatar;
  Color? _selectedColor;
  String? _errorMessage;

  bool _isPasswordChangeVisible = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Initialisation des données utilisateur pour l'édition du profil
  void _initUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;

    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      _selectedAvatar = user.avatar;
      _selectedColor = user.color;

      logger.debug(
        'Profil utilisateur chargé: ${user.displayName}',
        tag: logTag,
      );
    }
  }

  // Sauvegarde des modifications du profil
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Préparation des paramètres de mise à jour
      final String displayName = _displayNameController.text.trim();
      final String? avatar = _selectedAvatar;
      final Color? userColor = _selectedColor;

      // Si la section de changement de mot de passe est ouverte et les champs remplis
      String? currentPassword;
      String? newPassword;

      if (_isPasswordChangeVisible &&
          _currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty) {
        // Vérifier que les mots de passe correspondent
        if (_newPasswordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = 'Les nouveaux mots de passe ne correspondent pas';
          });
          return;
        }

        currentPassword = _currentPasswordController.text;
        newPassword = _newPasswordController.text;
      }

      // Appel au service de mise à jour avec le bon paramètre
      await authService.updateUserProfile(
        displayName: displayName,
        avatar: avatar,
        userColor: userColor,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );

        // Réinitialiser les champs de mot de passe
        if (_isPasswordChangeVisible) {
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          setState(() {
            _isPasswordChangeVisible = false;
          });
        }
      }

      logger.info('Profil utilisateur mis à jour avec succès', tag: logTag);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la mise à jour du profil: $e';
      });
      logger.error('Erreur lors de la mise à jour du profil: $e', tag: logTag);
    }
  }

  // Afficher la boîte de dialogue pour changer le mot de passe
  Future<void> _showPasswordChangeDialog(BuildContext context) async {
    // Réinitialiser les contrôleurs de mot de passe
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    // Afficher la boîte de dialogue
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AuthTextField(
                  controller: _currentPasswordController,
                  labelText: 'Mot de passe actuel',
                  hintText: 'Entrez votre mot de passe actuel',
                  obscureText: _obscureCurrentPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe actuel';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _newPasswordController,
                  labelText: 'Nouveau mot de passe',
                  hintText: 'Entrez votre nouveau mot de passe',
                  obscureText: _obscureNewPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  validator: ValidationService.validatePassword,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirmer le mot de passe',
                  hintText: 'Confirmez votre nouveau mot de passe',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator:
                      (value) => ValidationService.validatePasswordConfirmation(
                        value,
                        _newPasswordController.text,
                      ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Changer le mot de passe'),
              onPressed: () async {
                // Vérifier que les mots de passe correspondent
                if (_newPasswordController.text !=
                    _confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Les mots de passe ne correspondent pas'),
                    ),
                  );
                  return;
                }

                // Activer l'indicateur pour utiliser ces valeurs dans _saveProfile
                setState(() {
                  _isPasswordChangeVisible = true;
                });

                // Appeler la méthode de sauvegarde
                await _saveProfile();

                // Fermer la boîte de dialogue
                if (mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoading = authService.isLoading;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Section profil avec expansion
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // En-tête de la section profil (toujours visible)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Mon profil'),
                    trailing: IconButton(
                      icon: Icon(
                        _isProfileExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                      onPressed: () {
                        setState(() {
                          _isProfileExpanded = !_isProfileExpanded;

                          // Réinitialiser les valeurs si on ouvre la section
                          if (_isProfileExpanded) {
                            _initUserData();
                          }
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _isProfileExpanded = !_isProfileExpanded;

                        // Réinitialiser les valeurs si on ouvre la section
                        if (_isProfileExpanded) {
                          _initUserData();
                        }
                      });
                    },
                  ),

                  // Contenu expansible de l'édition du profil
                  if (_isProfileExpanded)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withAlpha((255 * 0.3).toInt()),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Colonne 1 : Sélection d'avatar (60% de l'espace)
                            Expanded(
                              flex: 55,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(36.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AvatarSelector(
                                        currentAvatar: _selectedAvatar,
                                        onAvatarSelected: (avatar) {
                                          setState(() {
                                            _selectedAvatar = avatar
                                                .split('/')
                                                .last
                                                .replaceAll('.png', '');
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Colonne 2 : Sélection de couleur (10% de l'espace)
                            Expanded(
                              flex: 15,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: Text(
                                          'Couleur',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleSmall,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      ColorSelector(
                                        currentColor: _selectedColor,
                                        onColorSelected: (color) {
                                          setState(() {
                                            _selectedColor = color;
                                          });
                                        },
                                        isCompact: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Colonne 3 : Prévisualisation, pseudo et validation (30% de l'espace)
                            Expanded(
                              flex: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Section 1 : Prévisualisation de l'avatar
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Aperçu',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 12),
                                          AvatarDisplay(
                                            avatar: _selectedAvatar,
                                            color: _selectedColor,
                                            size: 120,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Section 2 : Modification du pseudo
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pseudo',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 12),
                                          AuthTextField(
                                            controller: _displayNameController,
                                            labelText: 'Pseudo',
                                            hintText: 'Entrez votre pseudo',
                                            prefixIcon: const Icon(
                                              Icons.person,
                                            ),
                                            validator:
                                                ValidationService
                                                    .validateUsername,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Section 3 : Bouton de validation
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          // Message d'erreur si présent
                                          if (_errorMessage != null)
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withAlpha(
                                                  (255 * 0.1).toInt(),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _errorMessage!,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),

                                          // Bouton de sauvegarde
                                          AuthButton(
                                            text: 'Sauvegarder',
                                            isLoading: isLoading,
                                            onPressed: _saveProfile,
                                          ),

                                          // Option pour ouvrir le changement de mot de passe
                                          TextButton(
                                            onPressed: () {
                                              _showPasswordChangeDialog(
                                                context,
                                              );
                                            },
                                            child: const Text(
                                              'Changer le mot de passe',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 32),

            // Autres options de paramètres
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Mode sombre'),
              trailing: Switch(
                value: Provider.of<ThemeService>(context).isDarkMode,
                onChanged: (value) {
                  final themeService = Provider.of<ThemeService>(
                    context,
                    listen: false,
                  );
                  themeService.setDarkMode(value);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Open notifications settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Aide'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Open help center
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('À propos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Open about page
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Déconnexion',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Déconnexion'),
                        content: const Text(
                          'Êtes-vous sûr de vouloir vous déconnecter ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Déconnexion',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                );

                if (confirm == true) {
                  await authService.signOut();

                  // Redirection explicite vers la page de connexion
                  if (context.mounted) {
                    // Utiliser GoRouter pour naviguer vers la page de connexion
                    context.go('/login');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
