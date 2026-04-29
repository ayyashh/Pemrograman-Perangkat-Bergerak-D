import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'admin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 1));
    final fbUser = AuthService.firebaseUser;
    if (fbUser != null) {
      currentUser = await DbService.getUser(fbUser.uid);
    }
    if (!mounted) return;
    Widget next = const LoginScreen();
    if (currentUser != null) {
      next = currentUser!.role == 'admin' ? const AdminScreen() : const HomeScreen();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded, size: 64, color: Color(0xFF4F8EF7)),
            SizedBox(height: 16),
            Text('BorrowIt', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('BorrowIt Borrowing System', style: TextStyle(color: Color(0xFF8892B0))),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Color(0xFF4F8EF7), strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
