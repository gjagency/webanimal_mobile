import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/service/media_service.dart';
import 'package:mobile_app/widgets/avatar.dart';
import 'package:mobile_app/widgets/promociones_por_veterinaria_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/widgets/active_filter_chip.dart';
import 'package:mobile_app/widgets/filter_bottom_sheet.dart';
import 'package:mobile_app/widgets/posts_feed.dart';
import 'package:mobile_app/widgets/quick_filter_chip.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:intl/intl.dart';
class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _crearPostKey = GlobalKey();
  bool _canShowTutorial = false;
  bool _showcaseStarted = false;
  bool _hideTopSection = false;
  double _lastOffset = 0;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? selectedTypeId;
  String? selectedPetTypeId;
  String? selectedCityId;
  Position? _currentPosition;
  DateTimeRange? selectedDateRange;
  bool? esVeterinariaLogueada;
  List<PromocionesPorVeterinaria> _promocionesAgrupadas = [];
  List<File> _newImages = []; // imágenes nuevas elegidas
  List<String> _deleteImageIds = [];
  List<PostMedia> _existingMedias = []; // ids de imágenes a borrar (opcional)
  bool _isSavingEdit = false;

  List<Post> _posts = [];
  List<PostType> _postTypes = [];
  List<PetType> _petTypes = [];
  bool _isLoading = true;
  String? _error;
  String avatarUrl = '';
  bool loadingProfile = true;
  @override
  void initState() {
    super.initState();

    _checkShowcase();

    _init();
    _loadProfile();
    _loadData();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await AuthService.loadCurrentUser();
    setState(() {
      esVeterinariaLogueada = AuthService.esVeterinaria;
    });
  }
Future<void> _checkShowcase() async {
  final prefs = await SharedPreferences.getInstance();

  int count = prefs.getInt('home_showcase_count') ?? 0;

  if (count < 3) {
    setState(() {
      _canShowTutorial = true;
    });

    await prefs.setInt('home_showcase_count', count + 1);
  }
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

  Future<bool> _requestLocationForPost() async {
    try {
      /// GPS apagado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activá el GPS para crear un post')),
        );

        /// abre configuración
        await Geolocator.openLocationSettings();

        /// espera un poco al volver
        await Future.delayed(const Duration(seconds: 2));

        /// verifica nuevamente
        serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          return false;
        }
      }

      /// permisos
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Necesitamos ubicación para crear publicaciones'),
          ),
        );

        return false;
      }

      return true;
    } catch (e) {
      debugPrint('ERROR LOCATION: $e');
      return false;
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.getProfile();

      setState(() {
        avatarUrl = profile['avatar'] ?? 'https://i.pravatar.cc/150?img=10';
        loadingProfile = false;
      });
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
      setState(() {
        loadingProfile = false;
      });
    }
  }

  Future<void> _editarPost(Post post) async {
    final _formKey = GlobalKey<FormState>();
    String description = post.description;

    final ImagePicker _picker = ImagePicker();

    // Limpiar listas por si venían de otro edit
    _newImages = [];
    _deleteImageIds = [];
    _existingMedias = post.medias;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Editar Post',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Descripción
                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Ingrese una descripción'
                        : null,
                    onSaved: (v) => description = v ?? '',
                  ),
                  const SizedBox(height: 12),

                  // IMÁGENES
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // 🔹 Existentes
                      ..._existingMedias.map((img) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                img.url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    // Si tiene ID real, lo agregamos a deleteImageIds
                                    if (img.id != null &&
                                        !_deleteImageIds.contains(img.id)) {
                                      _deleteImageIds.add(img.id!);
                                    }
                                    // Removemos la imagen de la UI
                                    _existingMedias.remove(img);
                                  });
                                },

                                child: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),

                      // 🔹 Nuevas (local)
                      ..._newImages.map((file) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                file,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _newImages.remove(file);
                                  });
                                },
                                child: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Botón agregar imagen
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Agregar Imagen'),
                    onPressed: () async {
                      final totalImages =
                          _existingMedias.length + _newImages.length;
                      if (totalImages >= 3) {
                        showDialog(
                          context: context,
                          builder: (_) => const AlertDialog(
                            content: Text(
                              'Solo podés agregar hasta 3 imágenes',
                            ),
                          ),
                        );
                        return;
                      }

                      final XFile? picked = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (picked != null) {
                        setState(() {
                          _newImages.add(File(picked.path));
                        });
                      }
                    },
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
              onPressed: _isSavingEdit
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      _formKey.currentState!.save();

                      setState(() => _isSavingEdit = true);
                      try {
                        if (!context.mounted) return;

                        Navigator.pop(context);

                        // ===============================
                        // POPUP ÉXITO PRO
                        // ===============================
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (dialogContext) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 48,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Post actualizado',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Los cambios se guardaron correctamente',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  if (Navigator.canPop(dialogContext)) {
                                    Navigator.pop(dialogContext);
                                  }
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );

                        await _loadData();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al actualizar post: $e'),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isSavingEdit = false);
                      }
                    },
              child: _isSavingEdit
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    _currentPage = 1;
    _hasMore = true;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Promociones
      if (selectedTypeId == 'promociones') {
        final data = await AuthService.getMisPromociones();

        setState(() {
          _promocionesAgrupadas = data
              .map((e) => PromocionesPorVeterinaria.fromJson(e))
              .toList();
          _posts = [];
          _isLoading = false;
        });
        return;
      }

      // Mis Posts
      if (selectedTypeId == 'mis_posts') {
        final results = await PostsService.getMisPosts(); // nuevo método
        setState(() {
          _posts = results;
          _promocionesAgrupadas = [];
          _isLoading = false;
        });
        return;
      }

      // Solo para tipos de posts numéricos
      final results = await Future.wait([
        PostsService.getPosts(
          postType: selectedTypeId,
          petType: selectedPetTypeId,
          cityId: selectedCityId,
        ),
        PostsService.getPostTypes(),
        PostsService.getPetTypes(),
      ]);

      setState(() {
        final pagination = results[0] as PostsPagination;

        _posts = pagination.posts;
        _hasMore = pagination.hasNext;

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CrearPromocionSheet(),
    );
  }

  List<Post> get filteredPosts => _posts.toList();

  void _onScroll() {
    final offset = _scrollController.offset;

    /// ocultar apenas baja
    if (offset > 20 && !_hideTopSection) {
      setState(() {
        _hideTopSection = true;
      });
    }

    /// mostrar SOLO arriba del todo
    if (offset <= 0 && _hideTopSection) {
      setState(() {
        _hideTopSection = false;
      });
    }

    /// load more
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMorePosts();
    }
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
        selectedTypeId != null ||
        selectedPetTypeId != null ||
        selectedCityId != null ||
        selectedDateRange != null;
    return ShowCaseWidget(
      builder: (showcaseContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_canShowTutorial && !_showcaseStarted) {
        _showcaseStarted = true;

        ShowCaseWidget.of(
          showcaseContext,
        ).startShowCase([_crearPostKey]);
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo con gradiente
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.pink],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                "assets/logo6.png",
                width: 22,
                height: 22,
              ),
            ),

            const SizedBox(width: 10),

            // Texto que NO rompe el layout
            Expanded(
              child: Text(
                "WebAnimal",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Ejemplo de icono a la derecha
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.push('/search/users');
            },
          ),
          IconButton(
            onPressed: () =>
                context.push('/user-posts/${AuthService.currentUserId}'),
            icon: CustomAvatar(loading: loadingProfile, url: avatarUrl),
          ),

          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/account/settings');
            },
          ),

          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          /// =========================
          /// FILTROS (desaparecen al scrollear)
          /// =========================
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height:
                _scrollController.hasClients && _scrollController.offset > 10
                ? 0
                : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity:
                  _scrollController.hasClients && _scrollController.offset > 10
                  ? 0
                  : 1,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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

                                if (AuthService.esVeterinaria) ...[
                                  QuickFilterChip(
                                    label: 'Mis Descuentos',
                                    icon: Icons.local_offer_rounded,
                                    isSelected: selectedTypeId == 'promociones',
                                    onTap: () {
                                      setState(
                                        () => selectedTypeId = 'promociones',
                                      );
                                      _loadData();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                ..._postTypes
                                    .take(3)
                                    .map(
                                      (type) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: QuickFilterChip(
                                          label: type.name,
                                          icon: _getIconForType(type.name),
                                          isSelected: selectedTypeId == type.id,
                                          onTap: () {
                                            setState(
                                              () => selectedTypeId = type.id,
                                            );
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
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (hasFilters)
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (selectedPetTypeId != null)
                            ActiveFilterChip(
                              label: _petTypes
                                  .firstWhere((p) => p.id == selectedPetTypeId)
                                  .name,
                              onRemove: () {
                                setState(() => selectedPetTypeId = null);
                                _loadData();
                              },
                            ),

                          if (selectedDateRange != null)
                            ActiveFilterChip(
                              label: 'Rango de fecha',
                              onRemove: () =>
                                  setState(() => selectedDateRange = null),
                            ),

                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Limpiar filtros'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
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

          /// =========================
          /// DESCUENTOS (SIEMPRE FIJO)
          /// =========================
          if (selectedTypeId == null && !AuthService.esVeterinaria)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () {
                  context.push('/home/pet_spaces');
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 360;

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(
                        top: 8,
                        bottom: 10,
                        left: 10,
                        right: 10,
                      ),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.purple, Colors.pink],
                        ),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Busca Veterinarias, espacio Animal y descuentos',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmall ? 11 : 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                          ),

                          const SizedBox(width: 8),

                          Icon(Icons.map, color: Colors.white, size: 24),
                        ],
                        
                      ),
                      
                    );
                  },
                ),
              ),
            ),

      GestureDetector(
        onTap: () async {
          await launchUrl(
            Uri.parse('https://www.instagram.com/webanimalok/'),
            mode: LaunchMode.externalApplication,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            FaIcon(
              FontAwesomeIcons.instagram,
              color: Colors.pink,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Seguinos @webanimalok',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
          /// =========================
          /// FEED
          /// =========================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : selectedTypeId == 'promociones'
                ? PromocionesPorVeterinariaList(grupos: _promocionesAgrupadas)
                : PostsFeed(
                    controller: _scrollController,
                    posts: filteredPosts,
                    promociones: const [],
                    isLoading: false,
                    error: _error,
                    selectedTypeId: selectedTypeId,
                    onRefresh: _loadData,
                    onEditPost: _editarPost,
                    isLoadingMore: _isLoadingMore,
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 1,
          right: 0,
        ), // ajusta al borde inferior y derecho
        child: SpeedDialCustom(
          showcaseKey: _crearPostKey,
          onCrearPromocion: AuthService.esVeterinaria
              ? _mostrarCrearPromocionDialog
              : null,
          // función vacía evita que haga algo
          onCrearPost: () async {
            final hasPermission = await _requestLocationForPost();

            if (!hasPermission) return;

            if (!context.mounted) return;

            GoRouter.of(context).push('/posts/create/');
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        );
      },
    );
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
final response = await PostsService.getPosts(
  postType: selectedTypeId,
  petType: selectedPetTypeId,
  cityId: selectedCityId,
  page: _currentPage + 1,
);

final List<Post> newPosts = response.posts;

setState(() {
  _currentPage++;

  _hasMore = response.hasNext;

  final existingIds = _posts.map((e) => e.id).toSet();

  final uniquePosts = newPosts
      .where((post) => !existingIds.contains(post.id))
      .toList();

  _posts.addAll(uniquePosts);
});
    } catch (e) {
      debugPrint('Error load more: $e');
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }
}

/// -------------------------
/// SPEEDDIAL CON TU DISEÑO
/// -------------------------
class SpeedDialCustom extends StatefulWidget {
  final VoidCallback? onCrearPromocion;
  final VoidCallback? onCrearPost;
  final GlobalKey? showcaseKey;

  const SpeedDialCustom({
  super.key,
  this.onCrearPromocion,
  this.onCrearPost,
  this.showcaseKey, 
  });
  @override
  State<SpeedDialCustom> createState() => _SpeedDialCustomState();
}

class _SpeedDialCustomState extends State<SpeedDialCustom>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;

  void _toggleMenu() => setState(() => _isOpen = !_isOpen);
  void _closeMenu() => setState(() => _isOpen = false);

  @override
  Widget build(BuildContext context) {
    List<Widget> buttons = [];

    if (widget.onCrearPromocion != null) {
      buttons.add(
        _buildActionButton(
          icon: Icons.local_offer_rounded,
          label: 'Crear promoción',
          onTap: () {
            _closeMenu();
            widget.onCrearPromocion!();
          },
        ),
      );
    }

    if (widget.onCrearPost != null) {
        buttons.add(
        _buildActionButton(
          icon: Icons.post_add,
          label: 'Crear Post',
          onTap: () {
            _closeMenu();
            widget.onCrearPost!();
          },
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Fondo transparente que cierra el menú al tocar fuera
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
            right: 16,
          ), // pegado al borde
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Botones secundarios animados
              ...buttons.reversed.map(
                (btn) => AnimatedSlide(
                  offset: _isOpen ? Offset.zero : const Offset(0, 0.2),
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedOpacity(
                    opacity: _isOpen ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(ignoring: !_isOpen, child: btn),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Botón principal
Showcase(
  key: widget.showcaseKey ?? GlobalKey(),

  title: '🐾 CONCURSO WEBANIMAL 🐾',

  description:
      'Subí una foto de tu mascota desde el menú tipo de publicación (Concurso) y participá automáticamente. El post con más likes al final de ${DateFormat('MMMM', 'es_ES').format(DateTime.now())} gana un premio para su mascota 🎁',

  titleTextStyle: const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: Colors.black,
  ),

  descTextStyle: const TextStyle(
    fontSize: 15,
    height: 1.4,
    color: Colors.black87,
    fontWeight: FontWeight.w500,
  ),

  tooltipBackgroundColor: Colors.white,
  overlayColor: Colors.black54,
  textColor: Colors.black,

  targetBorderRadius: BorderRadius.circular(30),
  tooltipBorderRadius: BorderRadius.circular(24),

  tooltipPadding: const EdgeInsets.symmetric(
    horizontal: 22,
    vertical: 20,
  ),

  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _fab(
        icon: _isOpen ? Icons.close : Icons.add,
        onTap: _toggleMenu,
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.pink],
        ),
        isMain: true,
      ),
    ],
  ),
),
              
            ],
          ),
        ),
      ],
    );
  }

Widget _buildActionButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
        ),

        const SizedBox(width: 12),

        _fab(
          icon: icon,
          onTap: onTap,
          gradient: LinearGradient(
            colors: [Colors.purple.shade200, Colors.pink.shade200],
          ),
        ),
      ],
    ),
  );
}
  Widget _fab({
    required IconData icon,
    required VoidCallback onTap,
    required Gradient gradient,
    bool isMain = false,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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

class CrearPromocionSheet extends StatefulWidget {
  const CrearPromocionSheet({super.key});

  @override
  State<CrearPromocionSheet> createState() => _CrearPromocionSheetState();
}

class _CrearPromocionSheetState extends State<CrearPromocionSheet> {
  final _formKey = GlobalKey<FormState>();

  String? titulo;
  String? descripcion;
  String? precio;
  String? imageError;
  String? dateError;
  DateTime? fechaDesde;
  DateTime? fechaHasta;

  File? imagen;
  bool loading = false;

  final picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        imagen = File(picked.path);
        imageError = null;
      });
    }
  }

  Future<void> pickDate(bool desde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (desde) {
          fechaDesde = picked;
        } else {
          fechaHasta = picked;
        }

        if (fechaDesde != null &&
            fechaHasta != null &&
            !fechaHasta!.isBefore(fechaDesde!)) {
          dateError = null;
        }
      });
    }
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    final formValid = _formKey.currentState!.validate();

    setState(() {
      imageError = imagen == null ? 'Debés agregar una imagen' : null;

      if (fechaDesde == null || fechaHasta == null) {
        dateError = 'Seleccioná ambas fechas';
      } else if (fechaHasta!.isBefore(fechaDesde!)) {
        dateError = 'La fecha final debe ser posterior';
      } else {
        dateError = null;
      }
    });

    if (!formValid || imageError != null || dateError != null) {
      return;
    }

    _formKey.currentState!.save();
    setState(() => loading = true);

    try {
      final media = await MediaService.upload(imagen!);

      final success = await PromocionesService.crearPromocion(
        titulo: titulo!,
        descripcion: descripcion!,
        precio: precio,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        imagenId: media.id,
      );

      if (!mounted) return;

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(success ? 'Promoción creada 🎉' : 'Error'),
          content: Text(
            success
                ? 'Tu promoción fue publicada correctamente'
                : 'Excediste el límite de promociones',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * .92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, bottom + 16),
          child: Column(
            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Nueva promoción',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        /// IMAGEN
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: imageError != null
                                        ? Colors.red
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: imagen != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.file(
                                          imagen!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 42,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text('Agregar imagen'),
                                        ],
                                      ),
                              ),
                            ),

                            if (imageError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Text(
                                  imageError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// TITULO
                        TextFormField(
                          decoration: deco('Título', Icons.title),
                          maxLength: 30,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresá un título';
                            }
                            if (value.trim().length < 3) {
                              return 'Mínimo 3 caracteres';
                            }
                            return null;
                          },
                          onSaved: (value) => titulo = value!.trim(),
                        ),

                        const SizedBox(height: 12),

                        /// DESCRIPCION
                        TextFormField(
                          decoration: deco(
                            'Descripción',
                            Icons.description_outlined,
                          ),
                          maxLines: 3,
                          maxLength: 120,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresá una descripción';
                            }
                            if (value.trim().length < 5) {
                              return 'Mínimo 5 caracteres';
                            }
                            return null;
                          },
                          onSaved: (value) => descripcion = value!.trim(),
                        ),

                        const SizedBox(height: 12),

                        /// PRECIO
                        TextFormField(
                          decoration: deco(
                            'Precio',
                            Icons.attach_money_rounded,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*[.,]?\d{0,2}'),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresá un precio';
                            }

                            final parsed = double.tryParse(
                              value.replaceAll(',', '.'),
                            );

                            if (parsed == null) {
                              return 'Precio inválido';
                            }

                            if (parsed <= 0) {
                              return 'Debe ser mayor a 0';
                            }

                            return null;
                          },
                          onSaved: (value) =>
                              precio = value!.replaceAll(',', '.'),
                        ),

                        const SizedBox(height: 16),

                        /// FECHAS
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => pickDate(true),
                                icon: const Icon(Icons.calendar_month),
                                label: Text(
                                  fechaDesde == null
                                      ? 'Desde'
                                      : DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(fechaDesde!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => pickDate(false),
                                icon: const Icon(Icons.event),
                                label: Text(
                                  fechaHasta == null
                                      ? 'Hasta'
                                      : DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(fechaHasta!),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (dateError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                dateError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// BOTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Crear promoción',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
