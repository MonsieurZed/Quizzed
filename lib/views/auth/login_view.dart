/// Écran de connexion
///
/// Page permettant aux utilisateurs de se connecter
/// à l'application avec leur email et mot de passe
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/private_key.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/services/validation_service.dart';
import 'package:quizzzed/widgets/auth/auth_button.dart';
import 'package:quizzzed/widgets/auth/auth_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Pré-remplir les champs avec les identifiants admin en mode debug
    if (kDebugMode) {
      _emailController.text = PrivateKey.admin_email;
      _passwordController.text = PrivateKey.admin_password;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleLogin() async {
    // Cacher le clavier
    FocusScope.of(context).unfocus();

    // Valider le formulaire
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Forcer la redirection explicitement au lieu d'attendre le RouterGuard
        if (mounted && context.mounted) {
          context.go('/home');
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          switch (e.code) {
            case 'user-not-found':
              _errorMessage = 'Aucun utilisateur trouvé pour cet email.';
              break;
            case 'wrong-password':
              _errorMessage = 'Mot de passe incorrect.';
              break;
            case 'user-disabled':
              _errorMessage = 'Ce compte a été désactivé.';
              break;
            case 'too-many-requests':
              _errorMessage =
                  'Trop de tentatives échouées. Veuillez réessayer plus tard.';
              break;
            default:
              _errorMessage = 'Erreur de connexion: ${e.message}';
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
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 450, // Largeur maximale pour les grands écrans
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Espace supérieur pour meilleur centrage
                  SizedBox(height: screenSize.height * 0.05),

                  // Logo et titre
                  Center(
                    child: Image.asset('assets/images/logo.png', height: 120),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Connexion',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Formulaire
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Champ email
                          AuthTextField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            labelText: 'Adresse email',
                            hintText: 'Entrez votre adresse email',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: ValidationService.validateEmail,
                            onEditingComplete: () {
                              _passwordFocusNode.requestFocus();
                            },
                          ),

                          // Champ mot de passe
                          AuthTextField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            labelText: 'Mot de passe',
                            hintText: 'Entrez votre mot de passe',
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                            validator: ValidationService.validatePassword,
                            onEditingComplete: _handleLogin,
                          ),

                          // Message d'erreur
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 8,
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Bouton de connexion
                          AuthButton(
                            text: 'Se connecter',
                            onPressed: _handleLogin,
                            isLoading: isLoading,
                          ),

                          // Lien mot de passe oublié
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: TextButton(
                                onPressed:
                                    () => context.push('/forgot-password'),
                                child: const Text('Mot de passe oublié ?'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Séparateur
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OU',
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                  ),

                  // Bouton d'inscription
                  AuthButton(
                    text: 'Créer un compte',
                    onPressed: () => context.push('/register'),
                    isOutlined: true,
                  ),

                  // Espace inférieur pour meilleur centrage
                  SizedBox(height: screenSize.height * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
