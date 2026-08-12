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

Bienvenido a Web Animal. Al registrarte o utilizar esta aplicación, aceptás los presentes Términos y Condiciones. Si no estás de acuerdo con alguno de ellos, no deberías utilizar la app.

1. Uso de la aplicación

El usuario se compromete a usar la aplicación de forma legal y responsable, y a no utilizarla para actividades fraudulentas o dañinas.

Está prohibido publicar o difundir:

• Contenido ofensivo.
• Contenido violento.
• Contenido sexual explícito.
• Acoso o amenazas hacia otros usuarios.
• Spam o publicidad no autorizada.
• Información falsa o engañosa.
• Contenido relacionado con maltrato animal.

Web Animal se reserva el derecho de eliminar contenido que infrinja estas normas. Las denuncias de contenido inapropiado serán revisadas dentro de las 24 horas.

2. Registro y cuenta

El usuario es responsable de mantener la confidencialidad de su cuenta y de que la información proporcionada sea veraz y esté actualizada. Web Animal no se responsabiliza por accesos no autorizados causados por el uso indebido de las credenciales.

3. Contenido del usuario

El contenido publicado es responsabilidad exclusiva de quien lo publica. Al publicarlo, autorizás a Web Animal a mostrarlo dentro de la plataforma. Web Animal puede eliminar contenido que viole estos términos.

4. Privacidad

El uso de la aplicación también se rige por nuestra Política de Privacidad, donde se detalla cómo se recopilan y protegen tus datos personales.

5. Limitación de responsabilidad

La aplicación se ofrece "tal cual está". No garantizamos que el servicio sea ininterrumpido o esté libre de errores, y no seremos responsables por daños directos o indirectos derivados de su uso.

6. Suspensión y eliminación de cuentas

Los usuarios que incumplan estas condiciones podrán ser suspendidos o bloqueados permanentemente. También podés eliminar tu cuenta en cualquier momento.

7. Modificaciones

Nos reservamos el derecho de modificar estos Términos y Condiciones en cualquier momento. Los cambios serán informados dentro de la aplicación.

8. Contacto

Para cualquier consulta relacionada con estos Términos y Condiciones, podés escribirnos a:

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
