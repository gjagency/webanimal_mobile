import 'package:flutter/material.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:go_router/go_router.dart';

class PageAuthRecover extends StatefulWidget {
  const PageAuthRecover({super.key});

  @override
  State<PageAuthRecover> createState() => _PageAuthRecoverState();
}

class _PageAuthRecoverState extends State<PageAuthRecover> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Enviar solicitud de recuperación
  Future<void> _recoverPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Por favor ingresa tu email');
      return;
    }

    setState(() => _loading = true);

    try {
      final success = await AuthService.recoverPassword(email);

      if (success) {
        _showMessage('Revisa tu email para restablecer la contraseña');
        // Opcional: volver al login
        GoRouter.of(context).go('/auth/sign_in');
      } else {
        _showMessage('No se pudo enviar el email de recuperación');
      }
    } catch (e) {
      debugPrint('Recover error: $e');
      _showMessage('Error al enviar el email de recuperación');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_reset, size: 80, color: Colors.purple),
              const SizedBox(height: 16),
              const Text(
                'Ingresa tu email para recuperar la contraseña',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _recoverPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enviar', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => GoRouter.of(context).go('/auth/sign_in'),
                child: const Text(
                  'Volver al login',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
