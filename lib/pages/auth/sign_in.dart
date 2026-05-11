import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
class PageAuthSignIn extends StatefulWidget {
  const PageAuthSignIn({super.key});

  @override
  State<PageAuthSignIn> createState() => _PageAuthSignInState();
}

class _PageAuthSignInState extends State<PageAuthSignIn> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 🔐 Login tradicional
  Future<void> _login() async {
    setState(() => _loading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    try {
      final success = await AuthService.login(username, password);

      if (success) {
        _goHome();
      } else {
        _showError('Usuario o contraseña incorrectos');
      }
    } catch (e) {
      _showError('Error al iniciar sesión');
      debugPrint('Login error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 🔵 Login con Google
  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);

    try {
      final success = await AuthService.loginWithGoogle();

      if (success) {
        _goHome();
      } else {
        _showError('No se pudo iniciar sesión con Google');
      }
    } catch (e) {
      _showError('Error con Google Sign-In');
      debugPrint('Google login error: $e');
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


                                // CARD LOGIN
                // reemplazá TODO el Container del login por esto:

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      // BOTÓN VETERINARIA
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6A1B9A),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(30),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Acceso Veterinaria',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      TextField(
                                        controller: _usernameController,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Usuario o Email',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(18),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      TextField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Contraseña',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.lock,
                                            color: Colors.white,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(18),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 22),

                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: ElevatedButton(
                                          onPressed: _loading ? null : _login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.purple,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(18),
                                            ),
                                          ),
                                          child: _loading
                                              ? const CircularProgressIndicator()
                                              : const Text(
                                                  'Ingresar',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                                
                                
                              ),
                            );
                          },
                        );
                          },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.local_hospital),
                        label: const Text(
                          'Acceso Veterinaria',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                             ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                          // BOTÓN ESPACIO ANIMAL
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(context).viewInsets.bottom,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF6A1B9A),
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(30),
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Acceso Espacio Animal',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              const SizedBox(height: 24),

                                              TextField(
                                                controller: _usernameController,
                                                style: const TextStyle(color: Colors.white),
                                                decoration: InputDecoration(
                                                  hintText: 'Usuario o Email',
                                                  hintStyle: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                  prefixIcon: const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white24,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(18),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 16),

                                              TextField(
                                                controller: _passwordController,
                                                obscureText: true,
                                                style: const TextStyle(color: Colors.white),
                                                decoration: InputDecoration(
                                                  hintText: 'Contraseña',
                                                  hintStyle: const TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                  prefixIcon: const Icon(
                                                    Icons.lock,
                                                    color: Colors.white,
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white24,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(18),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 22),

                                              SizedBox(
                                                width: double.infinity,
                                                height: 54,
                                                child: ElevatedButton(
                                                  onPressed: _loading ? null : _login,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.white,
                                                    foregroundColor: Colors.purple,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(18),
                                                    ),
                                                  ),
                                                  child: _loading
                                                      ? const CircularProgressIndicator()
                                                      : const Text(
                                                          'Ingresar',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                ),
                                              ),

                                              const SizedBox(height: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.15),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.pets),
                              label: const Text(
                                'Acceso Espacio Animal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // BOTÓN GOOGLE
                          SizedBox(
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
                              onPressed: _loading ? null : _loginWithGoogle,
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
                        ],
                      ),
                    ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: () => GoRouter.of(context)
                      .go('/auth/register-vet'),
                  child: const Text(
                    'Registrar\nVeterinaria\nEspacio de mascotas',
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
