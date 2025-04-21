/// Écran d'inscription
///
/// Page permettant aux utilisateurs de créer un compte
/// dans l'application avec email et mot de passe
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/config/app_config.dart';
import 'package:quizzzed/models/user/profile_color.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/widgets/auth/auth_button.dart';
import 'package:quizzzed/widgets/auth/auth_text_field.dart';
import 'package:quizzzed/widgets/profile/avatar_preview.dart';
import 'package:quizzzed/widgets/profile/avatar_selector.dart';
import 'package:quizzzed/widgets/profile/color_selector.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _displayNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  // Nouveaux champs pour l'avatar et la couleur de fond
  String? _selectedAvatar;
  String? _selectedColor;
  bool _showAvatarSelector = false;
  bool _showColorSelector = false;

  @override
  void initState() {
    super.initState();
    // Définir des valeurs par défaut
    _selectedAvatar = AppConfig.defaultAvatarUrl;
    _selectedColor = ProfileColor.availableColors[4].name; // Bleu par défaut
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _displayNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  // Fonction pour afficher le sélecteur d'avatar
  void _showAvatarSelectorDialog() {
    setState(() {
      _showAvatarSelector = true;
    });
  }

  // Fonction pour afficher le sélecteur de couleur
  void _showColorSelectorDialog() {
    setState(() {
      _showColorSelector = true;
    });
  }

  Future<void> _handleRegister() async {
    // Cacher le clavier
    FocusScope.of(context).unfocus();

    // Valider le formulaire
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Les mots de passe ne correspondent pas.';
        });
        return;
      }

      setState(() {
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);

        // Inscription avec les paramètres supplémentaires
        await authService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          displayName: _displayNameController.text.trim(),
        );

        // Mettre à jour le profil avec l'avatar et la couleur après l'inscription
        if (authService.currentUser != null) {
          await authService.updateUserProfile(
            photoUrl: _selectedAvatar,
            avatarBackgroundColor: _selectedColor,
          );
        }

        // Forcer la redirection explicitement au lieu d'attendre le RouterGuard
        if (mounted && context.mounted) {
          context.go('/home');
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          switch (e.code) {
            case 'email-already-in-use':
              _errorMessage = 'Cette adresse email est déjà utilisée.';
              break;
            case 'invalid-email':
              _errorMessage = 'Adresse email invalide.';
              break;
            case 'operation-not-allowed':
              _errorMessage = 'Opération non autorisée.';
              break;
            case 'weak-password':
              _errorMessage = 'Ce mot de passe est trop faible.';
              break;
            default:
              _errorMessage = 'Erreur d\'inscription: ${e.message}';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Une erreur est survenue. Veuillez réessayer.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoading = authService.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo et titre
              Image.asset('assets/images/logo.png', height: 80),
              const SizedBox(height: 24),
              Text(
                'Créer un compte',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Prévisualisation de l'avatar avec couleur
              Center(
                child: GestureDetector(
                  onTap: _showAvatarSelectorDialog,
                  child: Column(
                    children: [
                      AvatarPreview(
                        avatarUrl: _selectedAvatar,
                        backgroundColor: _selectedColor,
                        size: 120,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Changer l\'avatar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bouton pour changer la couleur de fond
              Center(
                child: TextButton.icon(
                  onPressed: _showColorSelectorDialog,
                  icon: const Icon(Icons.color_lens),
                  label: const Text('Changer la couleur de fond'),
                ),
              ),

              const SizedBox(height: 24),

              // Formulaire
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Champ nom d'utilisateur
                    AuthTextField(
                      controller: _displayNameController,
                      focusNode: _displayNameFocusNode,
                      labelText: 'Nom d\'utilisateur',
                      hintText: 'Choisissez un nom d\'utilisateur',
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom d\'utilisateur';
                        }
                        if (value.length < AppConfig.minUsernameLength) {
                          return 'Le nom doit contenir au moins ${AppConfig.minUsernameLength} caractères';
                        }
                        if (value.length > AppConfig.maxUsernameLength) {
                          return 'Le nom doit contenir maximum ${AppConfig.maxUsernameLength} caractères';
                        }
                        return null;
                      },
                      onEditingComplete: () {
                        _emailFocusNode.requestFocus();
                      },
                    ),

                    // Champ email
                    AuthTextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      labelText: 'Adresse email',
                      hintText: 'Entrez votre adresse email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre adresse email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Veuillez entrer une adresse email valide';
                        }
                        return null;
                      },
                      onEditingComplete: () {
                        _passwordFocusNode.requestFocus();
                      },
                    ),

                    // Champ mot de passe
                    AuthTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      labelText: 'Mot de passe',
                      hintText: 'Créez votre mot de passe',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        if (value.length < AppConfig.minPasswordLength) {
                          return 'Le mot de passe doit contenir au moins ${AppConfig.minPasswordLength} caractères';
                        }
                        return null;
                      },
                      onEditingComplete: () {
                        _confirmPasswordFocusNode.requestFocus();
                      },
                    ),

                    // Champ confirmation mot de passe
                    AuthTextField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      labelText: 'Confirmer le mot de passe',
                      hintText: 'Confirmez votre mot de passe',
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez confirmer votre mot de passe';
                        }
                        if (value != _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                      onEditingComplete: _handleRegister,
                    ),

                    // Message d'erreur
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Bouton d'inscription
                    AuthButton(
                      text: 'S\'inscrire',
                      onPressed: _handleRegister,
                      isLoading: isLoading,
                    ),

                    // Lien pour se connecter
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Déjà un compte ?'),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Se connecter'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Sélecteur d'avatar en modal
      bottomSheet:
          _showAvatarSelector
              ? Container(
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.1).toInt()),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Choisissez votre avatar',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed:
                                () =>
                                    setState(() => _showAvatarSelector = false),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AvatarSelector(
                        currentAvatar: _selectedAvatar,
                        onAvatarSelected: (avatar) {
                          setState(() {
                            _selectedAvatar = avatar;
                            _showAvatarSelector = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              )
              : null,

      // Sélecteur de couleur en modal
      endDrawer:
          _showColorSelector
              ? Drawer(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Container(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Choisissez une couleur',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed:
                                  () => setState(
                                    () => _showColorSelector = false,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      ColorSelector(
                        currentColor: _selectedColor,
                        onColorSelected: (color) {
                          setState(() {
                            _selectedColor = color;
                            _showColorSelector = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              )
              : null,
    );
  }
}
