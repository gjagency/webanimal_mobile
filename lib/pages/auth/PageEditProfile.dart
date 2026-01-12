import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/service/auth_service.dart';

class PageEditProfile extends StatefulWidget {
  const PageEditProfile({super.key});

  @override
  State<PageEditProfile> createState() => _PageEditProfileState();
}

class _PageEditProfileState extends State<PageEditProfile> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  File? _avatarFile;
  String _avatarUrl = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// 📥 Cargar datos actuales
  Future<void> _loadProfile() async {
    final profile = await AuthService.getProfile();

    setState(() {
      _nameCtrl.text = profile['first_name'] ?? '';
      _bioCtrl.text = profile['bio'] ?? '';
      _avatarUrl = profile['avatar'] ?? '';
      _loading = false;
    });
  }

  /// 🖼️ Elegir imagen
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
    }
  }

  /// 💾 Guardar cambios
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final ok = await AuthService.updateProfile(
      name: _nameCtrl.text,
      bio: _bioCtrl.text,
      avatar: _avatarFile,
    );

    setState(() => _saving = false);

    if (ok && mounted) {
      Navigator.pop(context, true); // 🔁 vuelve y recarga
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar perfil')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.purple, Colors.pink]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.pets, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'WebAnimal',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// 👤 AVATAR
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundImage: _avatarFile != null
                                ? FileImage(_avatarFile!)
                                : (_avatarUrl.isNotEmpty
                                    ? NetworkImage(_avatarUrl)
                                    : null) as ImageProvider?,
                            child: _avatarFile == null && _avatarUrl.isEmpty
                                ? Icon(Icons.person, size: 50)
                                : null,
                          ),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.purple,
                            child: Icon(Icons.edit,
                                color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    /// ✏️ NOMBRE
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(labelText: 'Nombre'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Campo requerido' : null,
                    ),

                    SizedBox(height: 16),

                    /// 📝 BIO
                    TextFormField(
                      controller: _bioCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: 'Bio'),
                    ),

                    SizedBox(height: 32),

                    /// 💾 GUARDAR
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        child: _saving
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Guardar cambios'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
