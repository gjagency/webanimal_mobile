import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_app/pages/location/search.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/service/location_service.dart';

class PagePostCreate extends StatefulWidget {
  const PagePostCreate({super.key});

  @override
  State<PagePostCreate> createState() => _PagePostCreateState();
}

class _PagePostCreateState extends State<PagePostCreate> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _telefonoController = TextEditingController();

  List<PostType> _postTypes = [];
  List<PetType> _petTypes = [];
  String? _selectedPostTypeId;
  String? _selectedPetTypeId;
  List<File> _selectedImages = [];
  bool _isUploading = false;
  final ValueNotifier<double> _uploadProgress = ValueNotifier(0.0);
  static const int maxImages = 3;
  double? _currentLat;
  double? _currentLng;
  bool _isLoading = false;
  bool _isLoadingTypes = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkGpsOrGoBack();
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _checkGpsOrGoBack() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes activar el GPS para crear una publicación'),
        ),
      );
      await Geolocator.openLocationSettings();
      if (mounted) context.pop();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        PostsService.getPostTypes(),
        PostsService.getPetTypes(),
        _getCurrentLocation(),
      ]);

      if (!mounted) return;

      setState(() {
        _postTypes = results[0] as List<PostType>;
        _petTypes = results[1] as List<PetType>;
        if (_postTypes.isNotEmpty) _selectedPostTypeId = _postTypes[0].id;
        if (_petTypes.isNotEmpty) _selectedPetTypeId = _petTypes[0].id;
        _isLoadingTypes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingTypes = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationController.text = 'Ubicación no disponible';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationController.text = 'Permiso de ubicación denegado';
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      _currentLat = position.latitude;
      _currentLng = position.longitude;

      // Usar el servicio de geocodificación inversa
      final address = await LocationService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _locationController.text = address;
        });
      }
    } catch (e) {
      _locationController.text = 'Error obteniendo ubicación';
    }
  }

  Future<void> _openLocationSearch() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(builder: (context) => LocationSearchPage()),
    );

    if (result != null && mounted) {
      setState(() {
        _locationController.text = result.displayName;
        _currentLat = result.lat;
        _currentLng = result.lng;
      });
    }
  }
Future<void> _pickImage() async {
  final picker = ImagePicker();

  if (_selectedImages.length >= maxImages) {
    // Mostrar popup
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Límite alcanzado'),
        content: const Text('Solo podés agregar hasta 3 imágenes'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    return;
  }

  final ImageSource? source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera, color: Colors.purple),
            title: const Text('Cámara'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.purple),
            title: const Text('Galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return;

  if (source == ImageSource.gallery) {
    final images = await picker.pickMultiImage(
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (images.isEmpty) return;

    final remainingSlots = maxImages - _selectedImages.length;

    if (images.length > remainingSlots) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Límite alcanzado'),
          content: const Text('Solo podés agregar hasta 3 imágenes'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }

    setState(() {
      _selectedImages.addAll(
        images.take(remainingSlots).map((e) => File(e.path)),
      );
    });
  } else {
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedImages.add(File(image.path));
    });
  }
}



Future<List<String>> _imagesToBase64(List<File> images) async {
  return Future.wait(
    images.map((img) async => base64Encode(await img.readAsBytes())),
  );
}

Future<void> _savePost() async {
  if (!_formKey.currentState!.validate()) return;

  if (_selectedImages.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agregá al menos una imagen')),
    );
    return;
  }

  // 1️⃣ Activar overlay
  setState(() {
    _isUploading = true;
    _uploadProgress.value = 0.01;
  });

  // 2️⃣ Forzar render (CLAVE)
  await Future.delayed(Duration.zero);

  // 3️⃣ Delay mínimo para que SE VEA (solo UX)
  await Future.delayed(const Duration(milliseconds: 600));

  try {
    // Progreso fake suave
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!_isUploading || _uploadProgress.value >= 0.9) {
        timer.cancel();
      } else {
        _uploadProgress.value += 0.08;
      }
    });

    final imagesBase64 = await _imagesToBase64(_selectedImages);

    await PostsService.createPost(
      postTypeId: _selectedPostTypeId!,
      petTypeId: _selectedPetTypeId!,
      description: _descriptionController.text,
      telefono: _telefonoController.text,
      imagesBase64: imagesBase64,
      lat: _currentLat!,
      lng: _currentLng!,
      locationLabel: _locationController.text,
    );

    _uploadProgress.value = 1.0;

    if (!mounted) return;

    // Pequeño delay para ver el 100%
    await Future.delayed(const Duration(milliseconds: 300));
    context.pop();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al publicar')),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isUploading = false;
      });
    }
  }
}


Widget _uploadProgressBar() {
  return ValueListenableBuilder<double>(
    valueListenable: _uploadProgress,
    builder: (_, value, __) {
      return Column(
        children: [
          LinearProgressIndicator(
            value: value == 0 ? null : value, // indeterminado al inicio
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Text(
            value == 0
                ? 'Subiendo imágenes...'
                : 'Subiendo ${(value * 100).toInt()}%',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    },
  );
}

  @override
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[50],
    appBar: AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.pink],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'WebAnimal',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: (_isLoading || _isUploading) ? null : _savePost,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Publicar',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
        const SizedBox(width: 8),
      ],
    ),

    body: Stack(
      children: [
        /// 🔹 CONTENIDO PRINCIPAL
        _isLoadingTypes
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Imagen
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 300,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                        child: _selectedImages.isNotEmpty
                            ? GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedImages[index],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedImages.removeAt(index);
                                            });
                                          },
                                          child: const CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.black54,
                                            child: Icon(Icons.close,
                                                size: 14,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate,
                                        size: 64, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                        'Toca para agregar hasta 3 imágenes'),
                                  ],
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tipo de publicación
                    const Text(
                      'Tipo de publicación',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _postTypes.map((type) {
                        final isSelected =
                            _selectedPostTypeId == type.id;
                        return ChoiceChip(
                          label: Text(type.name),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() =>
                                _selectedPostTypeId = type.id);
                          },
                          selectedColor: Colors.purple[100],
                          backgroundColor: Colors.white,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Tipo de mascota
                    const Text(
                      'Tipo de mascota',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _petTypes.map((type) {
                        final isSelected =
                            _selectedPetTypeId == type.id;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.pets, size: 18),
                              const SizedBox(width: 6),
                              Text(type.name),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() =>
                                _selectedPetTypeId = type.id);
                          },
                          selectedColor: Colors.purple[100],
                          backgroundColor: Colors.white,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Teléfono
                    const Text(
                      'Teléfono',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      maxLength: 10,
                      decoration: InputDecoration(
                        hintText: 'Ingresa tu teléfono',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Descripción
                    const Text(
                      'Descripción',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Describe tu publicación...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Ubicación
                    const Text(
                      'Ubicación',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _openLocationSearch,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _locationController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'Buscar dirección...',
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.purple),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),

        /// 🔹 OVERLAY DE PROGRESO (AHORA SIEMPRE SE VE)
        if (_isUploading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  width: 200, // 👈 más chico
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Publicando...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

      ],
    ),
  );
}


}
