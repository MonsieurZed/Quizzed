/// Exemple d'utilisation de la gestion d'erreurs améliorée
///
/// Ce fichier montre comment utiliser les fonctionnalités de gestion d'erreurs améliorées
/// dans différents contextes de l'application (contrôleurs, services et vues).
library;

import 'package:flutter/material.dart';
import 'package:quizzzed/models/error_code.dart';
import 'package:quizzzed/services/error_message_service.dart';
import 'package:quizzzed/widgets/shared/error_handler.dart';

/// Exemple de méthode qui pourrait être dans un contrôleur ou un service
void exampleControllerMethod({
  required BuildContext context,
  required bool shouldSucceed,
}) {
  final errorMessageService = ErrorMessageService();

  try {
    // Simuler une opération qui pourrait échouer
    if (!shouldSucceed) {
      throw Exception("Une erreur s'est produite lors de l'opération");
    }

    // Opération réussie
    print('Opération réussie');
  } catch (e) {
    // Utiliser le service amélioré pour gérer l'erreur
    final errorCode = errorMessageService.getErrorCodeFromException(e);
    errorMessageService.handleError(
      operation: "Exemple d'opération",
      tag: 'ExampleController',
      error: e,
      errorCode: errorCode,
    );

    // Afficher l'erreur à l'utilisateur en utilisant l'extension sur BuildContext
    context.logAndShowError(
      operation: "Exemple d'opération",
      tag: 'ExampleController',
      error: e,
      errorCode: errorCode,
      showAsSnackBar: true,
    );
  }
}

/// Exemple d'un widget qui utilise l'ErrorObserver
class ErrorHandlingExampleView extends StatelessWidget {
  final bool simulateError;

  const ErrorHandlingExampleView({Key? key, this.simulateError = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorObserver(
      useDialog: true,
      logTag: 'ErrorHandlingExample',
      child: Scaffold(
        appBar: AppBar(title: const Text('Exemple de gestion d\'erreurs')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  exampleControllerMethod(
                    context: context,
                    shouldSucceed: !simulateError,
                  );
                },
                child: Text(
                  simulateError
                      ? 'Déclencher une erreur'
                      : 'Exécuter sans erreur',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  try {
                    if (simulateError) {
                      throw Exception('Erreur simulée directement dans la vue');
                    }
                  } catch (e) {
                    // Utiliser directement l'extension sur BuildContext
                    context.showErrorDialog(
                      'Une erreur s\'est produite lors de l\'opération.',
                      ErrorCode.operationFailed,
                    );
                  }
                },
                child: const Text('Tester ErrorDialog'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  try {
                    if (simulateError) {
                      throw Exception('Erreur réseau simulée');
                    }
                  } catch (e) {
                    // Utiliser directement l'extension sur BuildContext
                    context.showErrorMessage(
                      'Erreur de connexion au serveur.',
                      ErrorCode.networkError,
                    );
                  }
                },
                child: const Text('Tester ErrorSnackBar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
