/// Écran de récupération de mot de passe
///
/// Page permettant aux utilisateurs de demander une réinitialisation
/// de mot de passe en entrant leur adresse email
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quizzzed/services/auth_service.dart';
import 'package:quizzzed/widgets/auth/auth_button.dart';
import 'package:quizzzed/widgets/auth/auth_text_field.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  String? _errorMessage;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    // Cacher le clavier
    FocusScope.of(context).unfocus();

    // Valider le formulaire
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.sendPasswordResetEmail(_emailController.text.trim());

        // Afficher le message de confirmation
        setState(() {
          _emailSent = true;
        });
      } on FirebaseAuthException catch (e) {
        setState(() {
          switch (e.code) {
            case 'user-not-found':
              _errorMessage =
                  'Aucun utilisateur trouvé pour cette adresse email.';
              break;
            case 'invalid-email':
              _errorMessage = 'Adresse email invalide.';
              break;
            default:
              _errorMessage = 'Erreur de réinitialisation: ${e.message}';
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
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Image.asset('assets/images/logo.png', height: 80),
              const SizedBox(height: 24),

              if (!_emailSent) ...[
                // Instruction
                Text(
                  'Réinitialisation du mot de passe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Entrez l\'adresse email associée à votre compte pour recevoir un lien de réinitialisation.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Formulaire
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Champ email
                      AuthTextField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        labelText: 'Adresse email',
                        hintText: 'Entrez votre adresse email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
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
                        onEditingComplete: _handleResetPassword,
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

                      // Bouton de réinitialisation
                      AuthButton(
                        text: 'Envoyer le lien de réinitialisation',
                        onPressed: _handleResetPassword,
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Message de succès
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Email envoyé !',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Un email a été envoyé à ${_emailController.text}. '
                    'Veuillez suivre les instructions pour réinitialiser votre mot de passe.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton retour
                AuthButton(
                  text: 'Retour à la connexion',
                  onPressed: () => context.go('/login'),
                  isOutlined: true,
                ),
              ],

              // Lien pour retourner à la connexion
              if (!_emailSent)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Retour à la connexion'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
