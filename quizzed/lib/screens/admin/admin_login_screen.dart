import 'package:flutter/material.dart';
import 'package:quizzed/services/auth_service.dart';
import 'package:quizzed/services/logging_service.dart';
import 'package:quizzed/routes/app_routes.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final LoggingService _logger = LoggingService();
  final TextEditingController _emailController = TextEditingController(
    text: 'thibault.feuvrier@hotmail.fr',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'kainna66',
  );
  String _errorMessage = '';
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _logger.logInfo(
      'Admin login screen initialized',
      'AdminLoginScreen.initState',
    );
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      _logger.logDebug(
        'Loading saved credentials',
        'AdminLoginScreen._loadSavedCredentials',
      );
      // TODO: Implement loading saved credentials from secure storage
      // For now, we'll just simulate this with default values
      setState(() {
        _emailController.text = '';
        _passwordController.text = '';
        _rememberMe = false;
      });
      _logger.logDebug(
        'Saved credentials loaded',
        'AdminLoginScreen._loadSavedCredentials',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error loading saved credentials',
        e,
        stackTrace,
        'AdminLoginScreen._loadSavedCredentials',
      );
    }
  }

  @override
  void dispose() {
    _logger.logInfo('Admin login screen disposed', 'AdminLoginScreen.dispose');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveCredentials() async {
    try {
      if (_rememberMe) {
        _logger.logInfo(
          'Saving credentials for: ${_emailController.text}',
          'AdminLoginScreen._saveCredentials',
        );
        // TODO: Save credentials securely
        // For now, this is just a UI placeholder
        _logger.logInfo(
          'Credentials saved',
          'AdminLoginScreen._saveCredentials',
        );
      }
    } catch (e, stackTrace) {
      _logger.logError(
        'Error saving credentials',
        e,
        stackTrace,
        'AdminLoginScreen._saveCredentials',
      );
    }
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        _logger.logInfo(
          'Admin login attempt with email: ${_emailController.text}',
          'AdminLoginScreen._signIn',
        );

        final user = await _authService.signInAdmin(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null) {
          _logger.logInfo(
            'Admin login successful for: ${_emailController.text}',
            'AdminLoginScreen._signIn',
          );

          if (_rememberMe) {
            await _saveCredentials();
          }

          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
          }
        } else {
          _logger.logWarning(
            'Admin login failed for: ${_emailController.text} - Invalid credentials',
            'AdminLoginScreen._signIn',
          );

          setState(() {
            _errorMessage = 'Email ou mot de passe incorrect';
          });
        }
      } catch (e, stackTrace) {
        _logger.logError(
          'Error during admin login',
          e,
          stackTrace,
          'AdminLoginScreen._signIn',
        );

        setState(() {
          _errorMessage = 'Une erreur s\'est produite. Veuillez réessayer.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion Administrateur')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 400,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Accès MJ (Admin)',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // Remember me checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor:
                                  Theme.of(context).colorScheme.tertiary,
                            ),
                            Text(
                              'Se souvenir de moi',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),

                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            child:
                                _isLoading
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                      ),
                                    )
                                    : const Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
