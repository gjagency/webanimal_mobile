import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
class PageAuthRegisterVet extends StatefulWidget {
  const PageAuthRegisterVet({super.key});

  @override
  State<PageAuthRegisterVet> createState() => _PageAuthRegisterVetState();
}

class _PageAuthRegisterVetState extends State<PageAuthRegisterVet> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
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

Widget _imagePickerCard() {
  return GestureDetector(
    onTap: _pickImage,
    child: Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.grey.shade100,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        image: _imagen != null
            ? DecorationImage(
                image: FileImage(_imagen!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: _imagen == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: 38,
                  color: Colors.grey,
                ),
                SizedBox(height: 10),
                Text(
                  'Agregar imagen',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
    ),
  );
}

Widget _locationInput() {
  return TextFormField(
    controller: _locationController,
    style: const TextStyle(
      color: Colors.black87,
      fontWeight: FontWeight.w500,
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'La ubicación es obligatoria';
      }
      return null;
    },
    decoration: InputDecoration(
      hintText: 'Ubicación automática',
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: const Icon(
        Icons.location_on_outlined,
        color: Colors.grey,
      ),
      suffixIcon: IconButton(
        onPressed: _getCurrentLocation,
        icon: const Icon(
          Icons.my_location_rounded,
          color: Color(0xFF9B4DCC),
        ),
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF9B4DCC),
          width: 1.5,
        ),
      ),
    ),
  );
}
@override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: true,
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9B4DCC),
            Color(0xFFE0528D),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /// BACK
                Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          GoRouter.of(context).go('/auth/sign_in'),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// LOGO + TITLE
                Column(
                  children: [
                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Registrar veterinaria',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Completá tus datos para comenzar',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                /// CARD
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.12),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _styledInput(
                        _emailController,
                        'Email',
                        Icons.email_outlined,
                        darkMode: true,
                        validator: _required,
                      ),
                      const SizedBox(height: 14),

                      _styledInput(
                        _passwordController,
                        'Contraseña',
                        Icons.lock_outline,
                        obscure: _obscurePassword,
                        isPassword: true,
                        darkMode: true,
                        validator: (v) =>
                            v != null && v.length >= 6
                                ? null
                                : 'Mínimo 6 caracteres',
                      ),
                      const SizedBox(height: 14),

                      _styledInput(
                        _nombreController,
                        'Nombre comercial',
                        Icons.storefront_outlined,
                        darkMode: true,
                        validator: _required,
                      ),
                      const SizedBox(height: 14),

                      _styledInput(
                        _telefonoController,
                        'Teléfono',
                        Icons.phone_outlined,
                        darkMode: true,
                      ),
                      const SizedBox(height: 14),

                      _styledInput(
                        _direccionController,
                        'Dirección',
                        Icons.location_city_outlined,
                        darkMode: true,
                      ),

                      const SizedBox(height: 18),

                      _locationInput(),

                      const SizedBox(height: 20),

                      _imagePickerCard(),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF9B4DCC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Crear cuenta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _styledInput(
  TextEditingController controller,
  String hint,
  IconData icon, {
  bool obscure = false,
  bool isPassword = false,
  bool darkMode = false,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscure,
    validator: validator,
    style: TextStyle(
      color: darkMode ? Colors.black87 : Colors.white,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: darkMode ? Colors.grey : Colors.white70,
      ),
      prefixIcon: Icon(
        icon,
        color: darkMode ? Colors.grey[700] : Colors.white,
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: darkMode ? Colors.grey[700] : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            )
          : null,
      filled: true,
      fillColor:
          darkMode ? Colors.grey.shade100 : Colors.white.withOpacity(.10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
  );
}


  String? _required(String? v) {
    if (v == null || v.isEmpty) return 'Campo obligatorio';
    return null;
  }
}
