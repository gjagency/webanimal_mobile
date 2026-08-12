import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_app/pages/auth/terms_page.dart';
import 'package:mobile_app/pages/auth/privacy_page.dart';
class PageAuthSignIn extends StatefulWidget {
  const PageAuthSignIn({super.key});

  @override
  State<PageAuthSignIn> createState() => _PageAuthSignInState();
}

class _PageAuthSignInState extends State<PageAuthSignIn> {
  bool _acceptTerms = false;

  bool _loading = false;

  /// 🔵 Login con Google
Future<void> _loginWithGoogle() async {

  if (!_acceptTerms) {
    _showError(
      'Debes aceptar los Términos y Condiciones para continuar',
    );
    return;
  }

  setState(() => _loading = true);

  try {
    final success = await AuthService.loginWithGoogle();

    if (success) {
      _goHome();
    } else {
      _showError('No se pudo iniciar sesión con Google');
    }
  } on AccountPendingException catch (e) {
    _showAccountPendingDialog(e.message);
  } catch (e) {
    _showError('Error con Google Sign-In');
    debugPrint('Google login error: $e');
  } finally {
    setState(() => _loading = false);
  }
}

Future<void> _loginWithApple() async {

  if (!_acceptTerms) {
    _showError(
      'Debes aceptar los Términos y Condiciones para continuar',
    );
    return;
  }

  setState(() => _loading = true);

  try {
    final success = await AuthService.loginWithApple();

    if (success) {
      _goHome();
    } else {
      _showError('No se pudo iniciar sesión con Apple');
    }
  } on AccountPendingException catch (e) {
    _showAccountPendingDialog(e.message);
  } catch (e) {
    _showError('Error con Apple Sign-In');
    debugPrint('Apple login error: $e');
  } finally {
    setState(() => _loading = false);
  }
}

  void _goHome() {
    if (!mounted) return;
    GoRouter.of(context).go('/home');
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAccountPendingDialog(String message) {
    if (!mounted) return;
    setState(() => _loading = false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9B4DCC).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFF9B4DCC),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cuenta en proceso de alta',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B4DCC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    );
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LOGO
                  SizedBox(
                    width: 280,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // huellas fondo
                        Positioned(
                          top: 10,
                          left: 20,
                          child: Transform.rotate(
                            angle: -0.3,
                            child: Icon(
                              Icons.pets,
                              size: 70,
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 50,
                          right: 20,
                          child: Transform.rotate(
                            angle: 0.2,
                            child: Icon(
                              Icons.pets,
                              size: 55,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),

                        // W
                        Positioned(
                          left: 75,
                          top: 1,
                          child: Transform.rotate(
                            angle: -0.00,
                            child: Text(
                              'W',
                              style: GoogleFonts.cormorantGaramond(
                                color: Colors.white,
                                fontSize: 100,
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
                          left: 120,
                          top: 20,
                          child: Transform.rotate(
                            angle: -0.00,
                            child: Text(
                              'A',
                              style: GoogleFonts.cormorantGaramond(
                                color: Colors.white,
                                fontSize: 100,
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

                  Text(
                    '§',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // CARD LOGIN
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Iniciá sesión para continuar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 18),

CheckboxListTile(
  contentPadding: EdgeInsets.zero,
  value: _acceptTerms,
  activeColor: Colors.white,
  checkColor: const Color(0xFF9B4DCC),
  controlAffinity: ListTileControlAffinity.leading,
  onChanged: (value) {
    setState(() {
      _acceptTerms = value ?? false;
    });
  },
  title: Wrap(
    children: [
      const Text(
        'Acepto los ',
        style: TextStyle(
          fontSize: 13,
          color: Colors.white,
        ),
      ),
      GestureDetector(
        onTap: () {
          context.push('/auth/terms_page');
        },
        child: const Text(
          'Términos y Condiciones',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      const Text(
        ' y la ',
        style: TextStyle(
          fontSize: 13,
          color: Colors.white,
        ),
      ),
      GestureDetector(
        onTap: () {
          context.push('/auth/privacy_page');
        },
        child: const Text(
          'Política de Privacidad',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ],
  ),
),

                        const SizedBox(height: 10),

                        if (!_acceptTerms)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white.withOpacity(0.85),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Aceptá los Términos y Condiciones para poder continuar',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        /// ================= GOOGLE LOGIN =================
                          if (Platform.isAndroid)
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _acceptTerms ? 1.0 : 0.5,
                              child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                icon: const FaIcon(
                                  FontAwesomeIcons.google,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Ingresar con Google',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                               onPressed: _loading
                                ? null
                                : _loginWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                            ),

                          if (Platform.isIOS)
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _acceptTerms ? 1.0 : 0.5,
                              child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                icon: const FaIcon(
                                  FontAwesomeIcons.apple,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Ingresar con Apple',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: _loading
                                    ? null
                                    : _loginWithApple,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                            ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextButton(
                    onPressed: () =>
                        GoRouter.of(context).go('/auth/register-vet'),
                    child: const Text(
                      'Registrar Comercio',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
