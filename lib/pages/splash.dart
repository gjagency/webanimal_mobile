// splash.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
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
        await AuthService.loadCurrentUser();
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
  body: Container(
    width: double.infinity,
    height: double.infinity,
     decoration: const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9B4DCC), // violeta
      Color(0xFFE0528D), // rosa rojizo más visible
    ],
  ),
),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 320,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // huella elefante
                Positioned(
                  top: 10,
                  left: 20,
                  child: Transform.rotate(
                    angle: -0.00,
                    child: Icon(
                      Icons.pets,
                      size: 70,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),

                // huella león
                Positioned(
                  top: 50,
                  right: 20,
                  child: Transform.rotate(
                    angle: 0.00,
                    child: Icon(
                      Icons.pets,
                      size: 55,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),

                // herradura caballo
                Positioned(
                  bottom: 10,
                  left: 60,
                  child: Transform.rotate(
                    angle: -0.00,
                    child: Text(
                      'U',
                      style: TextStyle(
                        fontSize: 70,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                ),

                // W
                Positioned(
                  left: 50,
                  top: 10,
                  child: Transform.rotate(
                    angle: -0.00,
                    child: Text(
                      'W',
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white,
                        fontSize: 185,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // A
                Positioned(
                  left: 125,
                  top: 62,
                  child: Transform.rotate(
                    angle: -0.00,
                    child: Text(
                      'A',
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white,
                        fontSize: 175,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'WeBaNiMaL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 28),

          const CircularProgressIndicator(
            color: Colors.white,
          ),
        ],
      ),
    ),
  ),
);
}
}
