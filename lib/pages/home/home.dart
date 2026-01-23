import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile_app/service/auth_service.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/widgets/active_filter_chip.dart';
import 'package:mobile_app/widgets/filter_bottom_sheet.dart';
import 'package:mobile_app/widgets/posts_feed.dart';
import 'package:mobile_app/widgets/promocion_card.dart';
import 'package:mobile_app/widgets/quick_filter_chip.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
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
    setState(() {
      esVeterinariaLogueada = AuthService.esVeterinaria;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await _loadData();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _loadData();
          return;
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      await _loadData();
    } catch (e) {
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (selectedTypeId == 'promociones') {
        List<dynamic> data = AuthService.esVeterinaria
            ? await AuthService.getMisPromociones()
            : await AuthService.getOfertasPromociones();

        setState(() {
          _promociones = data.map((e) => Promocion.fromJson(e)).toList();
          _posts = [];
          _isLoading = false;
        });
        return;
      }

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
          if (picked != null) setState(() => _imagen = File(picked.path));
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
              if (desde) _fechaDesde = picked;
              else _fechaHasta = picked;
            });
          }
        }

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Crear Promoción', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Ingrese un título' : null,
                      onSaved: (v) => _titulo = v,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Ingrese una descripción' : null,
                      onSaved: (v) => _descripcion = v,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Precio', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _precio = v,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _pickDate(desde: true, setState: setState),
                            child: Text(_fechaDesde != null
                                ? 'Desde: ${DateFormat('dd/MM/yyyy').format(_fechaDesde!)}'
                                : 'Seleccionar fecha desde'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _pickDate(desde: false, setState: setState),
                            child: Text(_fechaHasta != null
                                ? 'Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaHasta!)}'
                                : 'Seleccionar fecha hasta'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _imagen != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_imagen!, height: 120, fit: BoxFit.cover))
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
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text(success ? 'Éxito' : 'Error'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mensaje),
                          if (!success)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: IconButton(
                                icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 32),
                                onPressed: () async {
                                  final Uri whatsappUrl = Uri.parse(
                                      "https://wa.me/5492920601338?text=Hola%20WebAnimal%20quiero%20aumentar%20el%20límite%20de%20promociones");
                                  try {
                                    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                                  } catch (_) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (success) {
                              Navigator.pop(context);
                              _loadData();
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

  List<Post> get filteredPosts => _posts.toList();

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
        onApply: (typeId, petTypeId, cityId) {
          setState(() {
            selectedTypeId = typeId;
            selectedPetTypeId = petTypeId;
            selectedCityId = cityId;
          });
          _loadData();
        },
      ),
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

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        selectedTypeId != null || selectedPetTypeId != null || selectedCityId != null || selectedDateRange != null;

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
                gradient: const LinearGradient(colors: [Colors.purple, Colors.pink]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pets, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WebAnimal',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
            if (AuthService.currentUser != null)
              Text(
                'Hola ${AuthService.displayName}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.black),
              onPressed: () => GoRouter.of(context).push('/account/notifications')),
          IconButton(
              icon: const Icon(Icons.person_2_rounded, color: Colors.black),
              onPressed: () => GoRouter.of(context).push('/account/settings')),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        QuickFilterChip(
                          label: 'Todos',
                          icon: Icons.grid_view_rounded,
                          isSelected: selectedTypeId == null,
                          onTap: () {
                            setState(() => selectedTypeId = null);
                            _loadData();
                          },
                        ),
                        const SizedBox(width: 8),
                        QuickFilterChip(
                          label: AuthService.esVeterinaria ? 'Mis Promociones' : 'Ofertas',
                          icon: AuthService.esVeterinaria ? Icons.local_offer_rounded : Icons.local_fire_department,
                          isSelected: selectedTypeId == 'promociones',
                          onTap: () {
                            setState(() => selectedTypeId = 'promociones');
                            _loadData();
                          },
                        ),
                        const SizedBox(width: 8),
                        ..._postTypes.take(3).map(
                          (type) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: QuickFilterChip(
                              label: type.name,
                              icon: _getIconForType(type.name),
                              isSelected: selectedTypeId == type.id,
                              onTap: () {
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
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: _showFilterBottomSheet,
                  style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
                ),
              ],
            ),
          ),
          if (hasFilters)
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (selectedPetTypeId != null)
                    ActiveFilterChip(
                        label: _petTypes.firstWhere((p) => p.id == selectedPetTypeId).name,
                        onRemove: () {
                          setState(() => selectedPetTypeId = null);
                          _loadData();
                        }),
                  if (selectedDateRange != null)
                    ActiveFilterChip(label: 'Rango de fecha', onRemove: () => setState(() => selectedDateRange = null)),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Limpiar filtros'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: PostsFeed(
              posts: filteredPosts,
              promociones: _promociones,
              isLoading: _isLoading,
              error: _error,
              selectedTypeId: selectedTypeId,
              onRefresh: _loadData,
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDialCustom(
        onCrearPromocion: AuthService.esVeterinaria ? _mostrarCrearPromocionDialog : null,
        onCrearPost: () => GoRouter.of(context).push('/posts/create'),
      ),
    );
  }
}

/// -------------------------
/// SPEEDDIAL CON TU DISEÑO
/// -------------------------
class SpeedDialCustom extends StatefulWidget {
  final VoidCallback? onCrearPromocion;
  final VoidCallback? onCrearPost;

  const SpeedDialCustom({super.key, this.onCrearPromocion, this.onCrearPost});

  @override
  State<SpeedDialCustom> createState() => _SpeedDialCustomState();
}

class _SpeedDialCustomState extends State<SpeedDialCustom> with SingleTickerProviderStateMixin {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    List<Widget> buttons = [];

    if (widget.onCrearPromocion != null) {
      buttons.add(_buildActionButton(
        icon: Icons.local_offer_rounded,
        label: 'Crear Promoción',
        onTap: widget.onCrearPromocion!,
      ));
    }

    if (widget.onCrearPost != null) {
      buttons.add(_buildActionButton(
        icon: Icons.post_add,
        label: 'Crear Post',
        onTap: widget.onCrearPost!,
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...buttons.reversed,
        const SizedBox(height: 8),
        _buildMainButton(),
      ],
    );
  }

Widget _buildActionButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return AnimatedOpacity(
    opacity: _isOpen ? 1 : 0,
    duration: const Duration(milliseconds: 200),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        _fab(
          icon: icon,
          onTap: () {
            setState(() => _isOpen = false); // ✅ Cierra el menú
            onTap();
          },
          gradient: LinearGradient(colors: [Colors.purple.shade200, Colors.pink.shade200]),
        ),
      ],
    ),
  );
}


  Widget _buildMainButton() {
    return _fab(
      icon: _isOpen ? Icons.close : Icons.add,
      onTap: () => setState(() => _isOpen = !_isOpen),
      gradient: const LinearGradient(colors: [Colors.purple, Colors.pink]),
      isMain: true,
    );
  }

  Widget _fab({required IconData icon, required VoidCallback onTap, required Gradient gradient, bool isMain = false}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Center(child: Icon(icon, size: 28, color: Colors.white)),
        ),
      ),
    );
  }
}
