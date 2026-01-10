import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_app/service/posts_service.dart';

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
  File? _selectedImageFile;
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isLoadingTypes = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        PostsService.getPostTypes(),
        PostsService.getPetTypes(),
        _getCurrentLocation(),
      ]);

      setState(() {
        _postTypes = results[0] as List<PostType>;
        _petTypes = results[1] as List<PetType>;
        if (_postTypes.isNotEmpty) _selectedPostTypeId = _postTypes[0].id;
        if (_petTypes.isNotEmpty) _selectedPetTypeId = _petTypes[0].id;
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() => _isLoadingTypes = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando datos: $e')));
      }
    }
  }

  Future<void> _getCurrentLocation() async {
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

      _currentPosition = await Geolocator.getCurrentPosition();
      _locationController.text =
          'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}';
    } catch (e) {
      _locationController.text = 'Error obteniendo ubicación';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    // Mostrar opciones
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera, color: Colors.purple),
              title: Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.purple),
              title: Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _selectedImageFile = File(image.path));
    }
  }

  Future<String> _imageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Debes seleccionar una imagen')));
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener tu ubicación')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final base64Image = await _imageToBase64(_selectedImageFile!);

      final result = await PostsService.createPost(
        postTypeId: _selectedPostTypeId!,
        petTypeId: _selectedPetTypeId!,
        description: _descriptionController.text,
        telefono: _telefonoController.text,
        imageBase64: base64Image,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        locationLabel: _locationController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Publicación creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/posts/${result.id}/view');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear publicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTypes) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Nueva publicación',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Nueva publicación',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePost,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Publicar',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Imagen
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: _selectedImageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _selectedImageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Toca para seleccionar imagen',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            SizedBox(height: 24),

            // Tipo de publicación
            Text(
              'Tipo de publicación',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _postTypes.map((type) {
                final isSelected = _selectedPostTypeId == type.id;
                return ChoiceChip(
                  label: Text(type.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedPostTypeId = type.id);
                  },
                  selectedColor: Colors.purple[100],
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.purple : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            // Tipo de mascota
            Text(
              'Tipo de mascota',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _petTypes.map((type) {
                final isSelected = _selectedPetTypeId == type.id;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pets, size: 18),
                      SizedBox(width: 6),
                      Text(type.name),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedPetTypeId = type.id);
                  },
                  selectedColor: Colors.purple[100],
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            // Teléfono
            Text(
              'Teléfono',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ], // ✅ solo números
              maxLength: 10,
              decoration: InputDecoration(
                hintText: 'Ingresa tu teléfono',
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
                  borderSide: BorderSide(color: Colors.purple, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El teléfono es obligatorio';
                }
                if (value.length != 10) {
                  return 'El teléfono debe tener 10 dígitos';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            // Descripción
            Text(
              'Descripción',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.purple, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La descripción es obligatoria';
                }
                return null;
              },
            ),
            SizedBox(height: 24),

            // Ubicación
            Text(
              'Ubicación',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Ubicación automática',
                prefixIcon: Icon(Icons.location_on, color: Colors.purple),
                suffixIcon: IconButton(
                  icon: Icon(Icons.my_location, color: Colors.purple),
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
                  borderSide: BorderSide(color: Colors.purple, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La ubicación es obligatoria';
                }
                return null;
              },
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
