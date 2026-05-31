import 'package:flutter/material.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/mis_veterinarias_service.dart';

class PageAccountSettings extends StatefulWidget {
  const PageAccountSettings({super.key});

  @override
  State<PageAccountSettings> createState() => _PageAccountSettingsState();
}

class _PageAccountSettingsState extends State<PageAccountSettings> {
  bool notificationsEnabled = true;
  bool privateProfile = false;
  bool showLocation = true;
  bool darkMode = false;

  String displayName = '';
  String username = '';
  String first_name = '';
  String lastName = '';
  String email = '';
  String avatarUrl = '';
  int postsCount = 0;
  bool loadingProfile = true;

  List<MiVeterinaria> veterinarias = [];
  bool loadingVets = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadVeterinarias();
  }

  /// Cargar perfil desde AuthService
  Future<void> _loadProfile() async {
    try {
      final token = await AuthService.getAccessToken();
      print('MI TOKEN: $token'); // 👈 Aquí ves si se guardó correctamente
      final profile =
          await AuthService.getProfile(); // 🟢 Método que trae usuario
      setState(() {
        final firstName = profile['first_name'] ?? '';
        final lastName = profile['last_name'] ?? '';

        displayName = [
          firstName,
          lastName,
        ].where((e) => e.isNotEmpty).join(' ');

        username = profile['username'] ?? '';
        email = profile['email'] ?? '';
        postsCount = profile['posts_count'] ?? 0;

        avatarUrl = profile['avatar'] ?? 'https://i.pravatar.cc/150?img=10';

        loadingProfile = false;
      });
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
      setState(() {
        loadingProfile = false;
      });
    }
  }

  Future<void> _loadVeterinarias() async {
    try {
      final data = await MisVeterinariasService.getAll();
      setState(() {
        veterinarias = data;
        loadingVets = false;
      });
    } catch (e) {
      debugPrint('Error cargando veterinarias: $e');
      setState(() => loadingVets = false);
    }
  }

  /// Función para cerrar sesión
  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      context.go('/auth/sign_in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo con gradiente
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.pink],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset("assets/logo6.png", width: 22, height: 22),
            ),

            const SizedBox(width: 10),

            // Texto que NO rompe el layout
            Expanded(
              child: Text(
                "WebAnimal",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: loadingProfile
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildProfileSection(),
                SizedBox(height: 16),
                _buildSection('Cuenta', [
                  _buildSettingItem(
                    icon: Icons.edit,
                    title: 'Editar perfil',
                    onTap: () async {
                      await context.push('/api/auth/profile');
                      _loadProfile(); // 👈 refresca al volver
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.lock,
                    title: 'Cambiar contraseña',
                    onTap: () {
                      _showChangePasswordModal();
                    },
                  ),
                ]),
                SizedBox(height: 16),
                _buildSection(AuthService.esVeterinaria ? 'Veterinaria' : '', [
                  if (loadingVets)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    ...veterinarias.map(
                      (vet) => InkWell(
                        onTap: () async {},
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      (vet.verified
                                              ? Colors.blue
                                              : Colors.purple)
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.local_hospital,
                                  color: vet.verified
                                      ? Colors.blue
                                      : Colors.purple,
                                  size: 22,
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            vet.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (vet.verified) ...[
                                          SizedBox(width: 6),
                                          Icon(
                                            Icons.verified,
                                            color: Colors.blue,
                                            size: 18,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ]),

                SizedBox(height: 16),
                _buildSection('Ayuda y soporte', [
                  _buildSettingItem(
                    icon: Icons.help,
                    title: 'Centro de ayuda',
                    onTap: _showHelpCenter,
                  ),
                  _buildSettingItem(
                    icon: Icons.info,
                    title: 'Acerca de',
                    subtitle: 'Versión 1.0.0',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    icon: Icons.description,
                    title: 'Términos y condiciones',
                    onTap: _showTermsAndConditions,
                  ),
                  _buildSettingItem(
                    icon: Icons.privacy_tip,
                    title: 'Política de privacidad',
                    onTap: _showPrivacyPolicy,
                  ),
                ]),
                SizedBox(height: 16),
                _buildSection('', [
                  _buildSettingItem(
                    icon: Icons.logout,
                    title: 'Cerrar sesión',
                    titleColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Cerrar sesión'),
                          content: Text(
                            '¿Estás seguro que deseas cerrar sesión?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _logout();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text('Cerrar sesión'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.delete_forever,
                    title: 'Eliminar cuenta',
                    titleColor: Colors.red[700],
                    iconColor: Colors.red[700],
                    onTap: () => _showDeleteAccountDialog(),
                  ),
                ]),
                SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildProfileSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool small = constraints.maxWidth < 360;

        final double avatarRadius = small ? 26 : 35;

        final double spacing = small ? 10 : 16;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),

          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

            borderRadius: BorderRadius.circular(20),

            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Row(
            children: [
              /// AVATAR RESPONSIVE
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  border: Border.all(color: Colors.white, width: 3),
                ),

                child: CircleAvatar(
                  radius: avatarRadius,

                  backgroundImage: NetworkImage(avatarUrl),
                ),
              ),

              SizedBox(width: spacing),

              /// INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  mainAxisSize: MainAxisSize.min,

                  children: [
                    /// NAME
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: small ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// EMAIL
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),

                        fontSize: small ? 12 : 14,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// POSTS
                    Text(
                      '$postsCount publicaciones',

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),

                        fontSize: small ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: small ? 6 : 10),

              /// ARROW
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: small ? 14 : 18,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.purple).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? Colors.purple, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.purple, size: 22),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  void _showChangePasswordModal() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // altura de la mitad de la pantalla
        final height = MediaQuery.of(context).size.height * 0.5;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(
              context,
            ).viewInsets.bottom, // mueve el modal con el teclado
          ),
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    'Cambiar contraseña',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  _passwordField('Contraseña actual', currentController),
                  SizedBox(height: 12),
                  _passwordField('Nueva contraseña', newController),
                  SizedBox(height: 12),
                  _passwordField('Confirmar contraseña', confirmController),
                  SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (newController.text != confirmController.text) {
                          _showError('Las contraseñas no coinciden');
                          return;
                        }

                        final success = await AuthService.changePassword(
                          currentPassword: currentController.text,
                          newPassword: newController.text,
                        );

                        if (success) {
                          Navigator.pop(context);
                          _showSuccess('Contraseña actualizada');
                        } else {
                          _showError('No se pudo cambiar la contraseña');
                        }
                      },
                      child: Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _passwordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar cuenta'),
        content: Text('Esta acción es irreversible. ¿Estás seguro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: lógica de eliminación
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter() {
    final screen = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.42,
          minChildSize: 0.32,
          maxChildSize: 0.85,

          expand: false,

          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),

              child: SafeArea(
                top: false,

                child: SingleChildScrollView(
                  controller: controller,

                  padding: EdgeInsets.fromLTRB(
                    screen.width * 0.06,
                    14,
                    screen.width * 0.06,
                    28,
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// HANDLE
                      Container(
                        width: screen.width * 0.14,
                        height: 5,

                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                      SizedBox(height: screen.height * 0.025),

                      /// HEADER
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          /// ICON
                          Container(
                            width: screen.width * 0.15,
                            height: screen.width * 0.15,

                            constraints: const BoxConstraints(
                              maxWidth: 62,
                              maxHeight: 62,
                            ),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),

                              gradient: const LinearGradient(
                                colors: [Colors.purple, Colors.pink],
                              ),
                            ),

                            child: Icon(
                              Icons.support_agent,
                              color: Colors.white,
                              size: screen.width * 0.075,
                            ),
                          ),

                          SizedBox(width: screen.width * 0.04),

                          /// TEXTS
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,

                                  child: Text(
                                    'Centro de ayuda',

                                    maxLines: 1,

                                    style: TextStyle(
                                      fontSize: screen.width * 0.06,

                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screen.height * 0.03),

                      /// CONTACT CARD
                      Container(
                        width: double.infinity,

                        padding: EdgeInsets.all(screen.width * 0.045),

                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,

                          borderRadius: BorderRadius.circular(24),

                          border: Border.all(color: Colors.grey.shade200),
                        ),

                        child: Row(
                          children: [
                            Container(
                              width: screen.width * 0.13,
                              height: screen.width * 0.13,

                              constraints: const BoxConstraints(
                                maxWidth: 54,
                                maxHeight: 54,
                              ),

                              decoration: BoxDecoration(
                                color: Colors.white,

                                borderRadius: BorderRadius.circular(16),
                              ),

                              child: Icon(
                                Icons.email_outlined,
                                color: Colors.purple,
                                size: screen.width * 0.06,
                              ),
                            ),

                            SizedBox(width: screen.width * 0.04),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    'Contacto',

                                    style: TextStyle(
                                      color: Colors.grey.shade700,

                                      fontSize: screen.width * 0.033,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,

                                    child: const SelectableText(
                                      'webanimalok@gmail.com',

                                      maxLines: 1,

                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screen.height * 0.035),

                      /// BUTTON
                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },

                          style: ElevatedButton.styleFrom(
                            elevation: 0,

                            backgroundColor: Colors.purple,

                            foregroundColor: Colors.white,

                            padding: EdgeInsets.symmetric(
                              vertical: screen.height * 0.02,
                            ),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),

                          child: FittedBox(
                            fit: BoxFit.scaleDown,

                            child: Text(
                              'Cerrar',

                              maxLines: 1,

                              style: TextStyle(
                                fontSize: screen.width * 0.042,

                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _helpItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  'Política de privacidad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(_privacyText, style: TextStyle(fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        );
      },
    );
  }

  static const String _privacyText = '''
🔐 POLÍTICA DE PRIVACIDAD
1. Introducción

Esta Política de Privacidad describe cómo recopilamos, usamos y protegemos la información personal de los usuarios que utilizan esta aplicación.

Al usar la app, aceptás las prácticas descritas en esta política.

2. Información que recopilamos

Podemos recopilar la siguiente información:

Datos de registro: nombre, nombre de usuario, email, foto de perfil.

Información de uso de la app.

Datos técnicos básicos (por ejemplo, tipo de dispositivo o sistema operativo).

No recopilamos información sensible sin tu consentimiento explícito.

3. Uso de la información

La información recopilada se utiliza para:

Proveer y mejorar el funcionamiento de la aplicación.

Personalizar la experiencia del usuario.

Gestionar la autenticación y seguridad de la cuenta.

Comunicarnos con el usuario cuando sea necesario.

4. Almacenamiento y seguridad

Los datos se almacenan de forma segura.

Implementamos medidas técnicas y organizativas para proteger la información.

Aun así, ningún sistema es 100% seguro y no podemos garantizar seguridad absoluta.

5. Compartir información con terceros

No compartimos datos personales con terceros, salvo cuando sea necesario para:

Cumplir obligaciones legales.

Proteger derechos, seguridad o integridad de la aplicación.

6. Derechos del usuario

El usuario puede:

Acceder a sus datos personales.

Modificar o actualizar su información.

Solicitar la eliminación de su cuenta y datos asociados.

Estas acciones pueden realizarse desde la app o contactándonos.

7. Eliminación de datos

Al eliminar una cuenta:

Los datos personales serán eliminados o anonimizados.

Algunos datos pueden conservarse si la ley lo exige.

8. Cambios en la política

Nos reservamos el derecho de actualizar esta Política de Privacidad.
Los cambios serán informados dentro de la aplicación.

9. Contacto

Para cualquier consulta relacionada con esta Política de Privacidad, podés escribirnos a:

📧 webanimalok@gmail.com
''';

  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  'Términos y condiciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(_termsText, style: TextStyle(fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        );
      },
    );
  }

  static const String _termsText = '''
1. Aceptación de los términos

Al registrarte o utilizar esta aplicación, aceptás estos Términos y Condiciones.
Si no estás de acuerdo con alguno de ellos, no deberías utilizar la app.

2. Uso de la aplicación

El usuario se compromete a:

Usar la aplicación de forma legal y responsable.

No publicar contenido falso, ofensivo o ilegal.

No utilizar la app para actividades fraudulentas o dañinas.

La app se reserva el derecho de suspender o eliminar cuentas que incumplan estas normas.

3. Registro y cuenta

El usuario es responsable de mantener la confidencialidad de su cuenta.

La información proporcionada debe ser veraz y actualizada.

La app no se responsabiliza por accesos no autorizados causados por el uso indebido de las credenciales.

4. Contenido del usuario

El contenido publicado es responsabilidad exclusiva del usuario.

Al publicar contenido, el usuario autoriza a la app a mostrarlo dentro de la plataforma.

La app puede eliminar contenido que viole estos términos.

5. Privacidad

El uso de la aplicación también se rige por nuestra Política de Privacidad, donde se detalla cómo se recopilan y protegen los datos personales.

6. Limitación de responsabilidad

La aplicación se ofrece “tal cual está”.
No garantizamos que el servicio sea ininterrumpido o libre de errores.

La app no será responsable por daños directos o indirectos derivados del uso de la plataforma.

7. Modificaciones

Nos reservamos el derecho de modificar estos Términos y Condiciones en cualquier momento.
Los cambios serán informados dentro de la aplicación.

8. Terminación de la cuenta

El usuario puede eliminar su cuenta en cualquier momento.
La app puede suspender o eliminar cuentas que incumplan estos términos.

9. Contacto

Para cualquier consulta relacionada con estos términos, podés contactarnos en:

📧 webanimalok@gmail.com
''';
}
