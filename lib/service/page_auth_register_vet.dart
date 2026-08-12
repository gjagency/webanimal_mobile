import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile_app/pages/auth/terms_page.dart';
import 'package:mobile_app/pages/auth/privacy_page.dart';

class PageAuthRegisterVet extends StatefulWidget {
  const PageAuthRegisterVet({super.key});

  @override
  State<PageAuthRegisterVet> createState() => _PageAuthRegisterVetState();
}

class _PageAuthRegisterVetState extends State<PageAuthRegisterVet> {
  bool _acceptTerms = false;
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _locationController = TextEditingController();

  File? _imagen;
  bool _loading = false;
  bool _googleLoading = false;
  String _tipoNegocio = 'veterinaria';

  // 🔵 cuenta de Google con la que se va a registrar el comercio
  String? _googleIdToken;
  String? _googleEmail;
  String? _googleName;

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
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// 🔵 Iniciar sesión con Google para vincular el comercio
  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);

    try {
      final idToken = await AuthService.getGoogleIdToken();

      if (idToken == null) {
        if (!mounted) return;
        _showError('No se pudo obtener la cuenta de Google');
        return;
      }

      // Decodificamos el JWT solo para mostrar el email/nombre en pantalla
      String? email;
      String? name;
      try {
        final parts = idToken.split('.');
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        email = payload['email'];
        name = payload['name'];
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _googleIdToken = idToken;
        _googleEmail = email;
        _googleName = name;
      });
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
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

    if (!mounted) return;

    if (!serviceEnabled) {
      final opened = await Geolocator.openLocationSettings();

      if (!mounted) return;

      if (opened) {
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        return _getCurrentLocation();
      }

      return;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso de ubicación denegado'),
          ),
        );

        context.go('/auth/sign_in');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes habilitar la ubicación desde Configuración',
          ),
        ),
      );

      await Geolocator.openAppSettings();
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (!mounted) return;

    _lat = position.latitude;
    _lng = position.longitude;

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;

      _label =
          '${place.locality ?? ''}, '
          '${place.administrativeArea ?? ''}, '
          '${place.country ?? ''}';

      setState(() {
        _locationController.text = _label!;
      });
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo obtener la ubicación'),
      ),
    );
  }
}


  /// ✅ Registrar veterinaria
  Future<void> _submit() async {

      if (_googleIdToken == null) {
    _showError('Primero iniciá sesión con Google');
    return;
  }

      if (!_acceptTerms) {
    _showError(
      'Debes aceptar los Términos y Condiciones para continuar',
    );
    return;
  }

  if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final success = await AuthService.registerVeterinariaConGoogle(
        idToken: _googleIdToken!,
        nombreComercial: _nombreController.text.trim(),
        tipoNegocio: _tipoNegocio,
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        ubicacionLabel: _label,
        lat: _lat,
        lng: _lng,
      );

      if (!mounted) return;

      if (success) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B4DCC).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF9B4DCC),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '¡Registro exitoso!',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Tu comercio fue registrado correctamente. Te avisaremos por email en cuanto un administrador active tu cuenta.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B4DCC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        );

        if (!mounted) return;
        GoRouter.of(context).push('/auth/sign_in');
      }
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');

      if (message.toLowerCase().contains('ya existe')) {
        await _showAccountExistsDialog(message);
      } else {
        _showError(message);
      }
    } finally {
  if (mounted) {
    setState(() => _loading = false);
  }
}
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showAccountExistsDialog(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9B4DCC).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF9B4DCC),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cuenta ya registrada',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B4DCC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    );
  }

    Widget _tipoNegocioSelector() {
      Widget option({
        required String value,
        required String label,
        required IconData icon,
      }) {
        final selected = _tipoNegocio == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tipoNegocio = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF9B4DCC)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF9B4DCC)
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: selected ? Colors.white : Colors.grey[700],
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Row(
        children: [
          option(
            value: 'veterinaria',
            label: 'Veterinaria',
            icon: Icons.local_hospital_outlined,
          ),
          const SizedBox(width: 10),
          option(
            value: 'comercio',
            label: 'Comercio',
            icon: Icons.storefront_outlined,
          ),
        ],
      );
    }

    Widget _googleAccountCard() {
      if (_googleIdToken != null) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF9B4DCC).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF9B4DCC).withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF9B4DCC)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _googleName?.isNotEmpty == true
                          ? _googleName!
                          : 'Cuenta de Google vinculada',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (_googleEmail != null)
                      Text(
                        _googleEmail!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _signInWithGoogle,
                child: const Text('Cambiar'),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          icon: _googleLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const FaIcon(FontAwesomeIcons.google, size: 18),
          label: const Text(
            'Continuar con Google',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: _googleLoading ? null : _signInWithGoogle,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
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
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            GoRouter.of(context).go('/auth/sign_in');
          }
        },
        child: Scaffold(
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
                keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
      16,
      8,
      16,
      MediaQuery.of(context).viewInsets.bottom + 20,
    ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  /// BACK
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            GoRouter.of(context).go('/auth/sign_in'),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// LOGO + TITLE
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Registrar Comercio',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Completá tus datos',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// CARD
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _googleAccountCard(),

                        if (_googleIdToken != null) ...[
                          const SizedBox(height: 14),

                          _styledInput(
                            _nombreController,
                            'Nombre comercial',
                            Icons.storefront_outlined,
                            darkMode: true,
                            validator: _required,
                          ),
                          const SizedBox(height: 10),

                          _tipoNegocioSelector(),
                          const SizedBox(height: 10),

                          _styledInput(
                            _telefonoController,
                            'Teléfono',
                            Icons.phone_outlined,
                            darkMode: true,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 10),

                          _styledInput(
                            _direccionController,
                            'Dirección',
                            Icons.location_city_outlined,
                            darkMode: true,
                          ),

                          const SizedBox(height: 12),

                          _locationInput(),

                          const SizedBox(height: 12),

                          _imagePickerCard(),

const SizedBox(height: 10),

CheckboxListTile(
  contentPadding: EdgeInsets.zero,
  value: _acceptTerms,
  activeColor: const Color(0xFF9B4DCC),
  controlAffinity: ListTileControlAffinity.leading,
  onChanged: (value) {
    setState(() {
      _acceptTerms = value ?? false;
    });
  },
  title: Wrap(
    children: [
      const Text(
        'Acepto los ',
        style: TextStyle(fontSize: 13),
      ),
     GestureDetector(
        onTap: () {
          context.push('/auth/terms_page');
        },
        child: const Text(
          'Términos y Condiciones',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF9B4DCC),
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      const Text(
        ' y la ',
        style: TextStyle(fontSize: 13),
      ),
     GestureDetector(
          onTap: () {
            context.push('/auth/privacy_page');
          },
          child: const Text(
            'Política de Privacidad',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9B4DCC),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
    ],
  ),
),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (_loading || !_acceptTerms)
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9B4DCC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Crear cuenta',
                                    style: TextStyle(
                                     color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
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
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
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
      suffixIcon: null,
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
