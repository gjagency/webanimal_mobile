import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PageAuthSignIn extends StatefulWidget {
  const PageAuthSignIn({super.key});

  @override
  State<PageAuthSignIn> createState() => _PageAuthSignInState();
}

class _PageAuthSignInState extends State<PageAuthSignIn> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

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
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[50],
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets, size: 80, color: Colors.purple),
            const SizedBox(height: 16),

            const Text(
              'WeBaNiMaL',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),

            const SizedBox(height: 32),

            // Usuario
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuario o Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // 🔹 Recuperar contraseña
            TextButton(
              onPressed: () => GoRouter.of(context).go('/auth/recover'),
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(color: Colors.purple),
              ),
            ),

            const SizedBox(height: 14),

            // Botón login
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 212, 67, 238),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ingresar', style: TextStyle(fontSize: 16,color: Colors.white)),
              ),
            ),

            const SizedBox(height: 16),

            // Divider
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('o'),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 16),

            // Botón Google
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.g_mobiledata, size: 32),
                label: const Text('Ingresar con Google'),
                onPressed: _loading ? null : _loginWithGoogle,
              ),
            ),

            const SizedBox(height: 24),

            // 🔹 Registrar veterinaria
            TextButton(
              onPressed: () => GoRouter.of(context).go('/auth/register-vet'),
              child: const Text(
                'Registrar Veterinaria',
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}
