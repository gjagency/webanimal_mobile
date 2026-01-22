import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/config.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  bool get hayVeterinarias {
  return _posts.any((p) => p.user.esVeterinaria == true);
}
  String? selectedTypeId;
  String? selectedPetTypeId;
  String? selectedCityId;
  Position? _currentPosition;
  DateTimeRange? selectedDateRange;
  bool? esVeterinariaLogueada;
  List<Promocion> _promociones = [];

  List<Post> _posts = [];
  List<PostType> _postTypes = [];
  List<PetType> _petTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
    _getCurrentLocation();
    
  }
Future<void> _init() async {
  await AuthService.loadCurrentUser(); 
  final esVet = AuthService.esVeterinaria;

  setState(() {
    esVeterinariaLogueada = esVet;
  });
}

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('GPS apagado, cargando posts sin ubicación');
        await _loadData(); // ✅ importante llamar siempre
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint(
            'Permiso de ubicación denegado, cargando posts sin ubicación',
          );
          await _loadData();
          return;
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      await _loadData();
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      await _loadData();
    }
  }
bool _isDialOpen = false;
Widget _buildSpeedDial() {
  return Stack(
    alignment: Alignment.bottomRight,
    children: [
      // Fondo semitransparente cuando el menú está abierto
      if (_isDialOpen)
        GestureDetector(
          onTap: () => setState(() => _isDialOpen = false),
          child: Container(
            color: Colors.black54,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

      // Botones secundarios + principal
      Positioned(
        bottom: 16,
        right: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end, // 🔹 todos pegados a la derecha
          children: [
            // Crear Promoción
            if (AuthService.currentUser?['es_veterinaria'] == true) ...[
              AnimatedOpacity(
                opacity: _isDialOpen ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _fabButton(
                  icon: Icons.local_offer_rounded,
                  label: 'Crear Promoción',
                  onTap: () {
                    setState(() => _isDialOpen = false);
                    _mostrarCrearPromocionDialog();
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],

            if (_isDialOpen) const SizedBox(height: 16),

            // Crear Post
            AnimatedOpacity(
              opacity: _isDialOpen ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: _fabButton(
                icon: Icons.add,
                label: 'Crear Post',
                onTap: () {
                  setState(() => _isDialOpen = false);
                  GoRouter.of(context).push('/posts/create');
                },
              ),
            ),
            if (_isDialOpen) const SizedBox(height: 16),

            // Botón principal
            _fabButton(
              icon: _isDialOpen ? Icons.close : Icons.add,
              onTap: () => setState(() => _isDialOpen = !_isDialOpen),
              isMain: true,
            ),
          ],
        ),
      ),
    ],
  );
}

// Función helper para los FABs
Widget _fabButton({
  required IconData icon,
  required VoidCallback onTap,
  String? label,
  bool isMain = false,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end, // 🔹 etiqueta también a la derecha
    children: [
      if (label != null)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isMain
                ? [Colors.purple, Colors.pink]
                : [Colors.purple.shade200, Colors.pink.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Center(
              child: Icon(icon, size: 28, color: Colors.white),
            ),
          ),
        ),
      ),
    ],
  );
}

Future<void> _loadData() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    // 🔹 PROMOCIONES / OFERTAS
        if (selectedTypeId == 'promociones') {
          try {
            List<dynamic> data;

            if (AuthService.currentUser?['es_veterinaria'] == true) {
              // 🔹 Veterinaria → Mis Promociones
              data = await AuthService.getMisPromociones();
            } else {
              // 🔹 No veterinaria → Todas las ofertas
              data = await AuthService.getOfertasPromociones();
            }

            final promos = data.map((e) => Promocion.fromJson(e)).toList();

            setState(() {
              _promociones = promos;
              _posts = [];       // limpiamos posts normales
              _isLoading = false;
            });
          } catch (e) {
            setState(() {
              _error = 'Error al cargar promociones: $e';
              _promociones = [];
              _posts = [];
              _isLoading = false;
            });
          }

          return; // importante para no continuar con PostsService.getPosts
        }


    // 🔵 POSTS NORMALES
    final results = await Future.wait([
      PostsService.getPosts(
        postType: selectedTypeId,
        petType: selectedPetTypeId,
        cityId: selectedCityId,
        lat: _currentPosition?.latitude,
        lng: _currentPosition?.longitude,
      ),
      PostsService.getPostTypes(),
      PostsService.getPetTypes(),
    ]);

    setState(() {
      _posts = results[0] as List<Post>;
      _postTypes = results[1] as List<PostType>;
      _petTypes = results[2] as List<PetType>;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _error = e.toString();
      _isLoading = false;
    });
  }
}


/// 🔹 POPUP PARA CREAR PROMOCIÓN
void _mostrarCrearPromocionDialog() {
  showDialog(
    context: context,
    builder: (context) {
      final _formKey = GlobalKey<FormState>();
      String? _titulo;
      String? _descripcion;
      String? _precio;
      DateTime? _fechaDesde;
      DateTime? _fechaHasta;
      File? _imagen;
      final ImagePicker _picker = ImagePicker();

      Future<void> _pickImage(void Function(void Function()) setState) async {
        final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          setState(() {
            _imagen = File(picked.path);
          });
        }
      }

      Future<void> _pickDate({required bool desde, required void Function(void Function()) setState}) async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            if (desde) {
              _fechaDesde = picked;
            } else {
              _fechaHasta = picked;
            }
          });
        }
      }

      // 🔹 StatefulBuilder para que el dialog tenga su propio estado
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Crear Promoción',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Ingrese un título' : null,
                    onSaved: (value) => _titulo = value,
                  ),
                  const SizedBox(height: 8),

                  // Descripción
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Ingrese una descripción' : null,
                    onSaved: (value) => _descripcion = value,
                  ),
                  const SizedBox(height: 8),

                  // Precio
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _precio = value,
                  ),
                  const SizedBox(height: 8),

                  // Fechas
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _pickDate(desde: true, setState: setState),
                          child: Text(
                            _fechaDesde != null
                                ? 'Desde: ${DateFormat('dd/MM/yyyy').format(_fechaDesde!)}'
                                : 'Seleccionar fecha desde',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _pickDate(desde: false, setState: setState),
                          child: Text(
                            _fechaHasta != null
                                ? 'Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaHasta!)}'
                                : 'Seleccionar fecha hasta',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Imagen seleccionada
                  _imagen != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_imagen!, height: 120, fit: BoxFit.cover),
                        )
                      : const SizedBox(height: 120),

                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(setState),
                    icon: const Icon(Icons.image),
                    label: const Text('Seleccionar Imagen'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                _formKey.currentState!.save();

                bool success = await PromocionesService.crearPromocion(
                  titulo: _titulo!,
                  descripcion: _descripcion!,
                  precio: _precio,
                  fechaDesde: _fechaDesde,
                  fechaHasta: _fechaHasta,
                  imagen: _imagen,
                );

                String mensaje = success
                    ? 'Promoción creada'
                    : 'Excediste el límite de promociones, para aumentarlo comunicate al WhatsApp';

                // 🔹 Mostrar popup de resultado
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(success ? 'Éxito' : 'Error'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(mensaje),
                        if (!success) ...[
                          const SizedBox(height: 16),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 32),
                            onPressed: () async {
                              final Uri whatsappUrl = Uri.parse(
                                  "https://wa.me/5492920601338?text=Hola%20WebAnimal%20quiero%20aumentar%20el%20límite%20de%20promociones");
                              try {
                                await launchUrl(
                                  whatsappUrl,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No se pudo abrir WhatsApp')),
                                );
                              }
                            },
                          ),
                        ]
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // cerrar popup
                          if (success) {
                            Navigator.pop(context); // cerrar dialog principal
                            _loadData(); // recargar lista de promociones
                          }
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      );
    },
  );
}





          List<Post> get filteredPosts {
            return _posts.toList();
          }

          void _clearFilters() {
            setState(() {
              selectedTypeId = null;
              selectedPetTypeId = null;
              selectedDateRange = null;
              selectedCityId = null;
            });
            _loadData();
          }

          void _showFilterBottomSheet() {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => FilterBottomSheet(
                selectedTypeId: selectedTypeId,
                selectedPetTypeId: selectedPetTypeId,
                postTypes: _postTypes,
                petTypes: _petTypes,
                selectedCityId: selectedCityId,
                hasLocation: _currentPosition != null,
                onApply: (typeId, petTypeId, citiId) {
                  setState(() {
                    selectedTypeId = typeId;
                    selectedPetTypeId = petTypeId;
                    selectedCityId = citiId;
                  });
                  _loadData();
                },
              ),
            );
          }
        Map<String, dynamic>? currentUser;
        bool _loadingUser = true;
          @override
          Widget build(BuildContext context) {

            final hasFilters =
                selectedTypeId != null ||
                selectedPetTypeId != null ||
                selectedCityId != null ||
                selectedDateRange != null;

            return Scaffold(
              backgroundColor: Colors.grey[50],
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WebAnimal',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          if (AuthService.currentUser != null)
          Text(
            'Hola ${AuthService.displayName}',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),


          ],
        ),

          ],
        ),

        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () =>
                GoRouter.of(context).push('/account/notifications'),
          ),
          IconButton(
            icon: Icon(Icons.person_2_rounded, color: Colors.black),
            onPressed: () => GoRouter.of(context).push('/account/settings'),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Barra de filtros
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                     children: [
              
                        _buildQuickFilter(
                          'Todos',
                          Icons.grid_view_rounded,
                          selectedTypeId == null,
                          () {
                            setState(() => selectedTypeId = null);
                            _loadData();
                          },
                        ),
                      if (AuthService.currentUser?['es_veterinaria'] == true) ...[
                          _buildQuickFilter(
                            'Mis Promociones',
                            Icons.local_offer_rounded,
                            selectedTypeId == 'promociones',
                            () {
                              setState(() => selectedTypeId = 'promociones');
                              _loadData();
                            },
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          _buildQuickFilter(
                            'Ofertas',
                            Icons.local_fire_department,
                            selectedTypeId == 'promociones',
                            () {
                              setState(() => selectedTypeId = 'promociones'); // <- aquí
                              _loadData();
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Los primeros 3 tipos de post
                        ..._postTypes.take(3).map(
                          (type) => Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: _buildQuickFilter(
                              type.name,
                              _getIconForType(type.name),
                              selectedTypeId == type.id,
                              () {
                                setState(() => selectedTypeId = type.id);
                                _loadData();
                              },
                            ),
                          ),
                        ),
                      ],

                    ),
                  ),
                ),
                SizedBox(width: 8),
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.tune_rounded),
                      onPressed: _showFilterBottomSheet,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                      ),
                    ),
                    if (hasFilters)
                     // Botón secundario: Crear Post
Positioned(
  bottom: 90, // separa los botones
  right: 16,
  child: Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [Colors.purple, Colors.pink],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.purple.withOpacity(0.4),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          GoRouter.of(context).push('/posts/create'); // 🔹 acá abrís crear post
        },
        borderRadius: BorderRadius.circular(30),
        child: const Center(
          child: Icon(Icons.add_circle_outline, size: 28, color: Colors.white),
        ),
      ),
    ),
  ),
),

                  ],
                ),
              ],
            ),
          ),

          // Active filters chips
          if (hasFilters)
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (selectedPetTypeId != null)
                    _buildActiveFilterChip(
                      _petTypes
                          .firstWhere((p) => p.id == selectedPetTypeId)
                          .name,
                      () {
                        setState(() => selectedPetTypeId = null);
                        _loadData();
                      },
                    ),
                  if (selectedDateRange != null)
                    _buildActiveFilterChip(
                      'Rango de fecha',
                      () => setState(() => selectedDateRange = null),
                    ),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: Icon(Icons.clear_all, size: 16),
                    label: Text('Limpiar filtros'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Posts feed
Expanded(
  child: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )

          // 🔥 PROMOCIONES
          : selectedTypeId == 'promociones'
              ? _promociones.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_offer_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No tenés promociones activas',
                            style:
                                TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                   : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 80,
                        ),
                        itemCount: _promociones.length,
                        itemBuilder: (context, index) {
                          final promo = _promociones[index];
                          return _PromocionCard(
                            promocion: promo,
                            onCrearPromocion: _mostrarCrearPromocionDialog, // <-- así abrís el popup desde cada card
                          );
                        },
                      ),
                      )

          // 🔵 POSTS NORMALES
          : filteredPosts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No se encontraron posts',
                        style:
                            TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 80, // ✅ deja espacio al final para que no choque con la barra del teléfono
                          ),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      return ModernPostCard(post: filteredPosts[index]);
                    },
                  ),
                ),
),

        ],
      ),
      
floatingActionButton: _buildSpeedDial(),
    );
  }

  IconData _getIconForType(String typeName) {
    switch (typeName.toLowerCase()) {
      case 'adopcion':
        return Icons.favorite;
      case 'perdido':
        return Icons.search;
      case 'denuncia':
        return Icons.report;
      default:
        return Icons.pets;
    }
  }

  Widget _buildQuickFilter(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [Colors.purple, Colors.pink])
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Colors.purple[50],
      deleteIconColor: Colors.purple,
    );
  }
}

class ModernPostCard extends StatefulWidget {
  final Post post;

  const ModernPostCard({super.key, required this.post});

  @override
  State<ModernPostCard> createState() => _ModernPostCardState();
}

class _ModernPostCardState extends State<ModernPostCard> {
  bool like = false;
  int inc = 0;

  @override
  void initState() {
    super.initState();

    like = widget.post.reacciones.isNotEmpty;
  }

  String _getTimeAgo() {
    final difference = DateTime.now().difference(widget.post.datetime);
    if (difference.inDays > 0) {
      return 'hace ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours}h';
    } else {
      return 'hace ${difference.inMinutes}m';
    }
  }
void _openImagePopup(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.9),
    builder: (_) {
      return GestureDetector(
        onTap: () => Navigator.of(context).pop(), // cerrar al tocar
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(widget.post.postType.color.replaceAll('#', '0xff')),
    );
    final colors = [color.withValues(alpha: 0.7), color];
    final icon = IconData(
      int.parse(widget.post.postType.icon),
      fontFamily: 'MaterialIcons',
    );

    return InkWell(
      onTap: () => GoRouter.of(context).push('/posts/${widget.post.id}/view'),
      onDoubleTap: _toggleLike,
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 229, 12, 12).withValues(alpha: 0.05),
              blurRadius: 5,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(0.5),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: colors),
                    ),
                    padding: EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: widget.post.user.imageUrl != null
                          ? NetworkImage(widget.post.user.imageUrl!)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: widget.post.user.imageUrl == null
                          ? Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                           Text(
                              widget.post.user.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            
                        Text(
                          "${_getTimeAgo()} - ${widget.post.location.label}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            WidgetSpan(
                              child: Icon(icon, color: Colors.white, size: 14),
                              alignment: PlaceholderAlignment.middle,
                            ),
                            const WidgetSpan(child: SizedBox(width: 4)),
                            TextSpan(
                              text: widget.post.postType.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Imagen
           // Imagen
            ClipRRect(
              borderRadius: BorderRadius.zero, // sin bordes
              child: Image.network(
                widget.post.imageUrl ??
                    "https://via.placeholder.com/400x300?text=Sin+Imagen",
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            ),



            // Botones de acción
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        like
                            ? Icon(Icons.favorite, size: 28, color: Colors.red)
                            : Icon(Icons.favorite_border, size: 28),
                        SizedBox(width: 4),
                        Text(
                          '${widget.post.likes + inc}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 28),
                      SizedBox(width: 4),
                      Text(
                        '${widget.post.comments}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Descripción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: widget.post.user.username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' ${widget.post.description}'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike() async {
    await PostsService.addReaction(widget.post.id, "1");

    setState(() {
      like = !like;
      inc = like ? inc + 1 : inc - 1;
    });
  }
}

class FilterBottomSheet extends StatefulWidget {
  final String? selectedTypeId;
  final String? selectedPetTypeId;
  final String? selectedCityId;
  final List<PostType> postTypes;
  final List<PetType> petTypes;
  final bool hasLocation;
  final Function(String?, String?, String?) onApply;

  const FilterBottomSheet({
    super.key,
    this.selectedTypeId,
    this.selectedPetTypeId,
    this.selectedCityId,
    required this.postTypes,
    required this.petTypes,
    required this.hasLocation,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? tempTypeId;
  late String? tempPetTypeId;
  late String? tempCityId;

  @override
  void initState() {
    super.initState();
    tempTypeId = widget.selectedTypeId;
    tempPetTypeId = widget.selectedPetTypeId;
    tempCityId = widget.selectedCityId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtros',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),

                // Tipo de post
                Text(
                  'Tipo de Publicación',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.postTypes.map((type) {
                    final isSelected = tempTypeId == type.id;
                    return ChoiceChip(
                      label: Text(type.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => tempTypeId = selected ? type.id : null);
                      },
                      selectedColor: Colors.purple[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.purple : Colors.black87,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24),

                // Tipo de mascota
                Text(
                  'Tipo de Mascota',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.petTypes.map((type) {
                    final isSelected = tempPetTypeId == type.id;
                    return ChoiceChip(
                      label: Text(type.name),
                      avatar: Icon(
                        Icons.pets,
                        size: 18,
                        color: isSelected ? Colors.purple : Colors.black54,
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(
                          () => tempPetTypeId = selected ? type.id : null,
                        );
                      },
                      selectedColor: Colors.purple[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.purple : Colors.black87,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),

                // ✅ CIUDAD con SearchView mejorado
                Text(
                  'Ciudad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                SearchAnchor(
                  builder: (BuildContext context, SearchController controller) {
                    final data = tempCityId != null
                        ? utf8.decode(base64.decode(tempCityId!)).split(":")
                        : [];

                    return Container(
                      decoration: BoxDecoration(
                        color: tempCityId != null
                            ? Colors.purple[50]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tempCityId != null
                              ? Colors.purple[300]!
                              : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => controller.openView(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: tempCityId != null
                                      ? Colors.purple
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    data.length == 3
                                        ? data[2]
                                        : 'Seleccionar ciudad',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: tempCityId != null
                                          ? Colors.purple[900]
                                          : Colors.grey[600],
                                      fontWeight: tempCityId != null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (tempCityId != null)
                                  IconButton(
                                    icon: Icon(Icons.clear, size: 20),
                                    color: Colors.purple,
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed: () {
                                      setState(() => tempCityId = null);
                                      controller.clear();
                                    },
                                  )
                                else
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey[600],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  suggestionsBuilder:
                      (
                        BuildContext context,
                        SearchController controller,
                      ) async {
                        if (controller.text.length < 2) {
                          return [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.grey),
                                  SizedBox(width: 12),
                                  Text(
                                    'Escribe al menos 2 caracteres',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        }

                        try {
                          final cities = await PostsService.searchCities(
                            controller.text,
                          );

                          if (cities.isEmpty) {
                            return [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.search_off, color: Colors.grey),
                                    SizedBox(width: 12),
                                    Text(
                                      'No se encontraron ciudades',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ];
                          }

                          return cities.map((city) {
                            return ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_city,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                city.ciudad,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text('${city.estado}, ${city.pais}'),
                              onTap: () {
                                setState(() {
                                  tempCityId = city.id;
                                });
                                controller.closeView(city.ciudad);
                              },
                            );
                          }).toList();
                        } catch (e) {
                          return [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text(
                                    'Error al buscar ciudades',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        }
                      },
                ),

                SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            tempTypeId = null;
                            tempPetTypeId = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Limpiar'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply(tempTypeId, tempPetTypeId, tempCityId);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
}
String getFullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  // Usamos tu Config.baseUrl
  return '${Config.baseUrl}$path';
}
class _PromocionCard extends StatelessWidget {
  final Promocion promocion;
  final VoidCallback onCrearPromocion; // <-- NUEVO: función que viene del padre

  const _PromocionCard({
    required this.promocion,
    required this.onCrearPromocion, // <-- la pasamos al constructor
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          
          // 🖼️ IMAGEN
          if (promocion.imagen != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                getFullImageUrl(promocion.imagen),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                      Icon(Icons.local_offer_rounded, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Ofertas - ${promocion.nombreComercio}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                ),
                const SizedBox(height: 12),
                Text(
                  promocion.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  promocion.descripcion,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (promocion.precio != null && promocion.precio!.isNotEmpty)
                  Text(
                    'Precio: ${promocion.precio}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    
                  ),
                  
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      promocion.fechadesde != null
                          ? 'Desde ${promocion.fechadesde}'
                          : 'Sin fecha de inicio',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      promocion.fechahasta != null
                          ? 'Hasta ${promocion.fechahasta}'
                          : 'Sin fecha de vencimiento',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
