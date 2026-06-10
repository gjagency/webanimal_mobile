import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          '''
TÉRMINOS Y CONDICIONES DE USO

Bienvenido a Web Animal.

Al utilizar esta aplicación, aceptas cumplir los presentes términos y condiciones.

Está prohibido:

• Publicar contenido ofensivo.
• Publicar contenido violento.
• Publicar contenido sexual explícito.
• Realizar acoso o amenazas.
• Difundir spam o publicidad no autorizada.
• Publicar información falsa o engañosa.
• Publicar contenido relacionado con maltrato animal.

Web Animal se reserva el derecho de eliminar contenido que infrinja estas normas.

Los usuarios que incumplan estas condiciones podrán ser suspendidos o bloqueados permanentemente.

Las denuncias de contenido inapropiado serán revisadas dentro de las 24 horas.

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