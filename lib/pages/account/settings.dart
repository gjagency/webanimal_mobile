import 'package:flutter/material.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:go_router/go_router.dart';

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

  /// Función central para cerrar sesión
  Future<void> _logout() async {
    // Cierra sesión en backend y elimina token local
    await AuthService.logout();

    // Redirige al login
    if (mounted) {
      context.go('/auth/sign_in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _logout, // back button protegido
        ),
        title: Text(
          'Cuenta',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildProfileSection(),
          SizedBox(height: 16),

          _buildSection('Cuenta', [
            _buildSettingItem(
              icon: Icons.edit,
              title: 'Editar perfil',
              subtitle: 'Nombre, foto, bio',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.lock,
              title: 'Cambiar contraseña',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.verified,
              title: 'Verificar cuenta',
              subtitle: 'Badge de verificación',
              onTap: () {},
            ),
          ]),
          SizedBox(height: 16),

          _buildSection('Notificaciones', [
            _buildSwitchItem(
              icon: Icons.notifications,
              title: 'Notificaciones push',
              subtitle: 'Recibir alertas',
              value: notificationsEnabled,
              onChanged: (val) => setState(() => notificationsEnabled = val),
            ),
            _buildSettingItem(
              icon: Icons.tune,
              title: 'Preferencias de notificaciones',
              subtitle: 'Personalizar alertas',
              onTap: () {},
            ),
          ]),
          SizedBox(height: 16),

          _buildSection('Privacidad y seguridad', [
            _buildSwitchItem(
              icon: Icons.lock_person,
              title: 'Perfil privado',
              subtitle: 'Solo seguidores ven tus posts',
              value: privateProfile,
              onChanged: (val) => setState(() => privateProfile = val),
            ),
            _buildSwitchItem(
              icon: Icons.location_on,
              title: 'Mostrar ubicación',
              subtitle: 'Visible en publicaciones',
              value: showLocation,
              onChanged: (val) => setState(() => showLocation = val),
            ),
            _buildSettingItem(
              icon: Icons.block,
              title: 'Cuentas bloqueadas',
              onTap: () {},
            ),
          ]),
          SizedBox(height: 16),

          _buildSection('Preferencias', [
            _buildSwitchItem(
              icon: Icons.dark_mode,
              title: 'Modo oscuro',
              value: darkMode,
              onChanged: (val) => setState(() => darkMode = val),
            ),
            _buildSettingItem(
              icon: Icons.language,
              title: 'Idioma',
              subtitle: 'Español',
              onTap: () {},
            ),
          ]),
          SizedBox(height: 16),

          _buildSection('Ayuda y soporte', [
            _buildSettingItem(
              icon: Icons.help,
              title: 'Centro de ayuda',
              onTap: () {},
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
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.privacy_tip,
              title: 'Política de privacidad',
              onTap: () {},
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
                    content: Text('¿Estás seguro que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _logout(); // llama a logout global
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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=10'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Juan Pérez',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '@juanperez',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '45 publicaciones • 234 seguidores',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
        ],
      ),
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
              // TODO: Lógica de eliminación
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
