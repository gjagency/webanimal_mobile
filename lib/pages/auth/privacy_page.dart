import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          '''
POLÍTICA DE PRIVACIDAD

Web Animal recopila información necesaria para el funcionamiento de la aplicación.

Datos recopilados:

• Correo electrónico.
• Nombre de usuario.
• Fotografías publicadas.
• Ubicación aproximada cuando el usuario lo autoriza.

La información se utiliza para:

• Mostrar publicaciones cercanas.
• Permitir la interacción entre usuarios.
• Mejorar la experiencia dentro de la aplicación.
• Garantizar la seguridad de la plataforma.

Web Animal no vende información personal a terceros.

Los usuarios pueden solicitar la eliminación de su cuenta y datos asociados.

Última actualización: Junio 2026.
          ''',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}