import 'homepage.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "login",
      routes: {
        'home': (context) => const HomePage(),
        'login': (context) => const LoginScreen(),
        'register': (context) => const RegisterScreen(),
      },
    );
  }
}