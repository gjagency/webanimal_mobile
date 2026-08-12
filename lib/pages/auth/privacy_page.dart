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

Esta Política de Privacidad describe cómo Web Animal recopila, usa y protege la información personal de los usuarios que utilizan la aplicación. Al usarla, aceptás las prácticas descritas acá.

1. Información que recopilamos

• Correo electrónico y nombre de usuario.
• Foto de perfil y fotografías que publicás.
• Ubicación aproximada, cuando la autorizás (para mostrarte publicaciones y veterinarias cercanas).
• Datos técnicos básicos del dispositivo (por ejemplo, tipo de dispositivo o sistema operativo).

No recopilamos información sensible sin tu consentimiento explícito.

2. Uso de la información

La información recopilada se utiliza para:

• Mostrar publicaciones y veterinarias cercanas.
• Permitir la interacción entre usuarios.
• Personalizar y mejorar tu experiencia dentro de la app.
• Gestionar la autenticación y seguridad de la cuenta.
• Comunicarnos con vos cuando sea necesario.

3. Almacenamiento y seguridad

Los datos y las imágenes se almacenan de forma segura, incluyendo a través de proveedores de infraestructura externos. Implementamos medidas técnicas y organizativas para proteger tu información, aunque ningún sistema es 100% seguro y no podemos garantizar seguridad absoluta.

4. Compartir información con terceros

Web Animal no vende información personal a terceros. Podemos compartir datos únicamente cuando sea necesario para:

• Cumplir obligaciones legales.
• Proteger derechos, seguridad o integridad de la aplicación.
• Operar con proveedores de almacenamiento e infraestructura necesarios para el funcionamiento de la app (por ejemplo, alojamiento de imágenes).

5. Derechos del usuario

Podés acceder a tus datos personales, modificarlos o actualizarlos, y solicitar la eliminación de tu cuenta y datos asociados desde la app o contactándonos.

6. Eliminación de datos

Al eliminar tu cuenta, tus datos personales serán eliminados o anonimizados. Algunos datos pueden conservarse si la ley lo exige.

7. Cambios en esta política

Nos reservamos el derecho de actualizar esta Política de Privacidad. Los cambios serán informados dentro de la aplicación.

8. Contacto

Para cualquier consulta relacionada con esta Política de Privacidad, podés escribirnos a:

📧 webanimalok@gmail.com

Última actualización: Agosto 2026.
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
