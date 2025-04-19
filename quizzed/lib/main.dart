import 'package:flutter/material.dart';
import 'package:quizzed/config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initializeFirebase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quizzed - Quiz LAN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Using the green fluo (#39FF14) on black theme as specified
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF39FF14),
          secondary: const Color(0xFF39FF14),
          background: Colors.black,
          surface: Colors.black,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: const Color(0xFF39FF14)),
          bodyMedium: TextStyle(color: const Color(0xFF39FF14)),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: const Color(0xFF39FF14),
          textTheme: ButtonTextTheme.primary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: const Color(0xFF39FF14),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quizzed - Quiz LAN')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenue sur Quizzed!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigation to Admin Login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: Colors.black,
              ),
              child: const Text('Accès MJ (Admin)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigation to Player Login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: Colors.black,
              ),
              child: const Text('Accès Joueur'),
            ),
          ],
        ),
      ),
    );
  }
}
