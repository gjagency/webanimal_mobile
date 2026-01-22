import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mobile_app/service/auth_service.dart';

class PageAuthRegisterVet extends StatefulWidget {
  const PageAuthRegisterVet({super.key});

  @override
  State<PageAuthRegisterVet> createState() => _PageAuthRegisterVetState();
}

class _PageAuthRegisterVetState extends State<PageAuthRegisterVet> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _locationController = TextEditingController();

  File? _imagen;
  bool _loading = false;

  // 📍 ubicación
  double? _lat;
  double? _lng;
  String? _label;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Obtener ubicación automáticamente al abrir la pantalla
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// 📸 Elegir imagen
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _imagen = File(picked.path));
    }
  }

  /// 📍 Obtener ubicación actual con reverse geocoding
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa el GPS para continuar')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Permiso de ubicación denegado permanentemente, activa desde ajustes')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _lat = position.latitude;
      _lng = position.longitude;

      // Reverse geocoding para obtener dirección legible
      List<Placemark> placemarks =
          await placemarkFromCoordinates(_lat!, _lng!);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        _label =
            '${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';
        setState(() {
          _locationController.text = _label!;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la ubicación')),
      );
    }
  }

  /// ✅ Registrar veterinaria
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final success = await AuthService.registerVeterinaria(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nombreComercial: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        imagen: _imagen,
        ubicacionLabel: _label,
        lat: _lat,
        lng: _lng,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veterinaria registrada. Revisá tu email para verificar la cuenta',
            ),
          ),
        );
        GoRouter.of(context).go('/auth/sign_in');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Registrar Veterinaria'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.purple),
          onPressed: () => GoRouter.of(context).go('/auth/sign_in'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.local_hospital, size: 72, color: Colors.purple),
              const SizedBox(height: 24),

              _input(_emailController, 'Email', validator: _required),
              const SizedBox(height: 16),

              _input(
                _passwordController,
                'Contraseña',
                obscure: true,
                validator: (v) =>
                    v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
              ),
              const SizedBox(height: 16),

              _input(
                _nombreController,
                'Nombre comercial',
                validator: _required,
              ),
              const SizedBox(height: 16),

              _input(_telefonoController, 'Teléfono'),
              const SizedBox(height: 16),

              _input(_direccionController, 'Dirección'),
              const SizedBox(height: 16),

              // 📍 Ubicación automática
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ubicación',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Ubicación automática',
                  prefixIcon:
                      const Icon(Icons.location_on, color: Colors.purple),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.purple),
                    onPressed: _getCurrentLocation,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: Colors.purple, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La ubicación es obligatoria';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 📸 Imagen
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[200],
                    image: _imagen != null
                        ? DecorationImage(
                            image: FileImage(_imagen!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imagen == null
                      ? const Center(
                          child: Icon(Icons.camera_alt, size: 40),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Registrar veterinaria'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String? _required(String? v) {
    if (v == null || v.isEmpty) return 'Campo obligatorio';
    return null;
  }
}
