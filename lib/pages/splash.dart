// splash.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    try {
      // Esperamos un momento para simular splash/loading
      await Future.delayed(const Duration(milliseconds: 500));

      final loggedIn = await AuthService.isLoggedIn();

      if (!mounted) return;

      if (loggedIn) {
        GoRouter.of(context).go('/home');
      } else {
        GoRouter.of(context).go('/auth/sign_in');
      }
    } catch (e) {
      print('Splash error: $e');
      if (!mounted) return;
      GoRouter.of(context).go('/auth/sign_in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.pets, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'WeBaNiMaL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
