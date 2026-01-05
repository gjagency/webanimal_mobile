import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

enum PostType { adopcion, perdido, denuncia, veterinaria, refugio, miMascota }

enum PetType { perro, gato, ave, otros }

class PagePostEdit extends StatefulWidget {
  final String postId;

  const PagePostEdit({super.key, required this.postId});

  @override
  State<PagePostEdit> createState() => _PagePostEditState();
}

class _PagePostEditState extends State<PagePostEdit> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  PostType selectedPostType = PostType.miMascota;
  PetType selectedPetType = PetType.perro;
  String? selectedImage;
  bool isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => selectedImage = image.path);
    }
  }

  Future<void> _savePost() async {
    if (_formKey.currentState!.validate() && selectedImage != null) {
      setState(() => isLoading = true);

      // Simular guardado
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Publicación actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } else if (selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Debes seleccionar una imagen')));
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
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Editar publicación',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _savePost,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Guardar',
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
                child: selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1543466835-00a7907e9de1',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text('Toca para cambiar imagen'),
                                ],
                              ),
                            );
                          },
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
              children: PostType.values.map((type) {
                final isSelected = selectedPostType == type;
                return ChoiceChip(
                  label: Text(_getPostTypeLabel(type)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => selectedPostType = type);
                  },
                  selectedColor: _getPostTypeColor(type).withOpacity(0.2),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? _getPostTypeColor(type)
                        : Colors.black87,
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
              children: PetType.values.map((type) {
                final isSelected = selectedPetType == type;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getPetTypeIcon(type), size: 18),
                      SizedBox(width: 6),
                      Text(_getPetTypeLabel(type)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => selectedPetType = type);
                  },
                  selectedColor: Colors.purple[100],
                  backgroundColor: Colors.white,
                );
              }).toList(),
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
                hintText: 'Ej: Palermo, Buenos Aires',
                prefixIcon: Icon(Icons.location_on, color: Colors.purple),
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
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getPostTypeLabel(PostType type) {
    switch (type) {
      case PostType.adopcion:
        return 'Adopción';
      case PostType.perdido:
        return 'Perdido';
      case PostType.denuncia:
        return 'Denuncia';
      case PostType.veterinaria:
        return 'Veterinaria';
      case PostType.refugio:
        return 'Refugio';
      case PostType.miMascota:
        return 'Mi Mascota';
    }
  }

  Color _getPostTypeColor(PostType type) {
    switch (type) {
      case PostType.adopcion:
        return Colors.blue;
      case PostType.perdido:
        return Colors.orange;
      case PostType.denuncia:
        return Colors.red;
      case PostType.veterinaria:
        return Colors.purple;
      case PostType.refugio:
        return Colors.teal;
      case PostType.miMascota:
        return Colors.green;
    }
  }

  String _getPetTypeLabel(PetType type) {
    switch (type) {
      case PetType.perro:
        return 'Perro';
      case PetType.gato:
        return 'Gato';
      case PetType.ave:
        return 'Ave';
      case PetType.otros:
        return 'Otros';
    }
  }

  IconData _getPetTypeIcon(PetType type) {
    switch (type) {
      case PetType.perro:
        return Icons.pets;
      case PetType.gato:
        return Icons.pets;
      case PetType.ave:
        return Icons.flutter_dash;
      case PetType.otros:
        return Icons.cruelty_free;
    }
  }
}
