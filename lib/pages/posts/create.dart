import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_app/service/media_service.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile_app/pages/location/search.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/service/location_service.dart';

/// Representa un medio (foto o video) ya seleccionado.
class MediaItem {
  final File file;
  final bool isVideo;
  // Controller solo si es video. Se crea perezosamente.
  VideoPlayerController? controller;

  MediaItem({required this.file, required this.isVideo});

  Future<void> initController() async {
    if (!isVideo || controller != null) return;
    controller = VideoPlayerController.file(file);
    await controller!.initialize();
    controller!.setLooping(true);
  }

  void dispose() {
    controller?.dispose();
    controller = null;
  }
}

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
  final _pageController = PageController();

  List<PostType> _postTypes = [];
  List<PetType> _petTypes = [];
  String? _selectedPostTypeId;
  String? _selectedPetTypeId;

  final List<MediaItem> _selectedMedia = [];
  int _currentMediaIndex = 0;

  bool _isUploading = false;
  final ValueNotifier<double> _uploadProgress = ValueNotifier(0.0);

  static const int maxMedia = 3;

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
    _pageController.dispose();
    for (final m in _selectedMedia) {
      m.dispose();
    }
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

  // ============ SELECCIÓN DE MEDIOS ============

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Límite alcanzado'),
        content: Text('Solo podés agregar hasta $maxMedia archivos'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMediaPicker() async {
    if (_selectedMedia.length >= maxMedia) {
      _showLimitDialog();
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Agregar contenido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _pickerTile(
                icon: Icons.photo_library_outlined,
                title: 'Galería de fotos y videos',
                subtitle: 'Elegí múltiples archivos',
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              _pickerTile(
                icon: Icons.photo_camera_outlined,
                title: 'Tomar foto',
                subtitle: 'Usar la cámara',
                onTap: () => Navigator.pop(context, 'photo'),
              ),
              _pickerTile(
                icon: Icons.videocam_outlined,
                title: 'Grabar video',
                subtitle: 'Hasta 60 segundos',
                onTap: () => Navigator.pop(context, 'video'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (action == null) return;

    final picker = ImagePicker();
    final remaining = maxMedia - _selectedMedia.length;

    try {
      if (action == 'gallery') {
        // pickMultipleMedia permite fotos Y videos en la misma selección
        final files = await picker.pickMultipleMedia(
          imageQuality: 85,
          maxWidth: 1600,
        );
        if (files.isEmpty) return;

        if (files.length > remaining) _showLimitDialog();

        final toAdd = files.take(remaining).toList();
        final newItems = <MediaItem>[];
        for (final f in toAdd) {
          final isVideo = _isVideoPath(f.path);
          final item = MediaItem(file: File(f.path), isVideo: isVideo);
          if (isVideo) await item.initController();
          newItems.add(item);
        }
        if (!mounted) return;
        setState(() => _selectedMedia.addAll(newItems));
      } else if (action == 'photo') {
        final img = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1600,
        );
        if (img == null) return;
        setState(() {
          _selectedMedia.add(MediaItem(file: File(img.path), isVideo: false));
        });
      } else if (action == 'video') {
        final vid = await picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(seconds: 60),
        );
        if (vid == null) return;
        final item = MediaItem(file: File(vid.path), isVideo: true);
        await item.initController();
        if (!mounted) return;
        setState(() => _selectedMedia.add(item));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al seleccionar el archivo')),
      );
    }
  }

  bool _isVideoPath(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') ||
        p.endsWith('.mov') ||
        p.endsWith('.avi') ||
        p.endsWith('.mkv') ||
        p.endsWith('.webm') ||
        p.endsWith('.m4v');
  }

  void _removeMediaAt(int index) {
    final item = _selectedMedia[index];
    setState(() {
      _selectedMedia.removeAt(index);
      item.dispose();
      if (_currentMediaIndex >= _selectedMedia.length) {
        _currentMediaIndex = _selectedMedia.isEmpty
            ? 0
            : _selectedMedia.length - 1;
      }
    });
    if (_selectedMedia.isNotEmpty && _pageController.hasClients) {
      _pageController.animateToPage(
        _currentMediaIndex,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _pickerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.purple),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }

  // ============ SUBIDA ============

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregá al menos una foto o video')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress.value = 0.01;
    });

    try {
      final medias = await Future.wait(
        _selectedMedia.map((media) => MediaService.upload(media.file)),
      );

      await PostsService.createPost(
        postTypeId: _selectedPostTypeId!,
        petTypeId: _selectedPetTypeId!,
        description: _descriptionController.text,
        telefono: _telefonoController.text,
        lat: _currentLat!,
        lng: _currentLng!,
        locationLabel: _locationController.text,
        mediaIds: medias.map((media) => media.id ?? "").toList(),
      );

      _uploadProgress.value = 1.0;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al publicar: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ============ BUILD ============

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
          _isLoadingTypes
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildMediaSection(),
                      const SizedBox(height: 24),
                      _sectionTitle('Tipo de publicación'),
                      const SizedBox(height: 12),
                      _buildChips(
                        items: _postTypes
                            .map((t) => _ChipData(t.id, t.name))
                            .toList(),
                        selectedId: _selectedPostTypeId,
                        onSelected: (id) =>
                            setState(() => _selectedPostTypeId = id),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Tipo de mascota'),
                      const SizedBox(height: 12),
                      _buildChips(
                        items: _petTypes
                            .map((t) => _ChipData(t.id, t.name))
                            .toList(),
                        selectedId: _selectedPetTypeId,
                        onSelected: (id) =>
                            setState(() => _selectedPetTypeId = id),
                        withIcon: Icons.pets,
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Teléfono'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 10,
                        decoration: _inputDecoration('Ingresa tu teléfono'),
                      ),
                      const SizedBox(height: 8),
                      _sectionTitle('Descripción'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: _inputDecoration(
                          'Describe tu publicación...',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _sectionTitle('Ubicación'),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _openLocationSearch,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _locationController,
                            readOnly: true,
                            decoration: _inputDecoration(
                              'Buscar dirección...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
          if (_isUploading) _buildUploadOverlay(),
        ],
      ),
    );
  }

  // ============ MEDIA SECTION ============

  Widget _buildMediaSection() {
    if (_selectedMedia.isEmpty) {
      return GestureDetector(
        onTap: _openMediaPicker,
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 72,
                  color: Colors.grey,
                ),
                SizedBox(height: 12),
                Text(
                  'Agregá fotos y videos',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Hasta 10 archivos',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Colors.black,
            height: 380,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _selectedMedia.length,
                  onPageChanged: (i) {
                    // pausar todos los videos al cambiar
                    for (final m in _selectedMedia) {
                      if (m.isVideo && m.controller != null) {
                        m.controller!.pause();
                      }
                    }
                    setState(() => _currentMediaIndex = i);
                  },
                  itemBuilder: (context, index) {
                    final item = _selectedMedia[index];
                    return item.isVideo
                        ? _VideoPreview(item: item)
                        : Image.file(item.file, fit: BoxFit.cover);
                  },
                ),
                // Contador estilo IG (1/10)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentMediaIndex + 1}/${_selectedMedia.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Botón eliminar el medio actual
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: () => _removeMediaAt(_currentMediaIndex),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Indicadores (dots) estilo IG
                if (_selectedMedia.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_selectedMedia.length, (i) {
                        final active = i == _currentMediaIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 8 : 6,
                          height: active ? 8 : 6,
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Thumbnails + botón agregar
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedMedia.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == _selectedMedia.length) {
                // Botón agregar
                final atLimit = _selectedMedia.length >= maxMedia;
                return GestureDetector(
                  onTap: atLimit ? _showLimitDialog : _openMediaPicker,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: atLimit ? Colors.grey[300]! : Colors.purple,
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: atLimit ? Colors.grey : Colors.purple,
                      size: 28,
                    ),
                  ),
                );
              }
              final item = _selectedMedia[index];
              final isActive = index == _currentMediaIndex;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? Colors.purple : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: item.isVideo
                            ? Container(
                                color: Colors.black,
                                child:
                                    item.controller != null &&
                                        item.controller!.value.isInitialized
                                    ? FittedBox(
                                        fit: BoxFit.cover,
                                        clipBehavior: Clip.hardEdge,
                                        child: SizedBox(
                                          width:
                                              item.controller!.value.size.width,
                                          height: item
                                              .controller!
                                              .value
                                              .size
                                              .height,
                                          child: VideoPlayer(item.controller!),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.videocam,
                                          color: Colors.white54,
                                        ),
                                      ),
                              )
                            : Image.file(item.file, fit: BoxFit.cover),
                      ),
                      if (item.isVideo)
                        const Positioned(
                          bottom: 4,
                          right: 4,
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============ HELPERS UI ============

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  );

  InputDecoration _inputDecoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildChips({
    required List<_ChipData> items,
    required String? selectedId,
    required ValueChanged<String> onSelected,
    IconData? withIcon,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedId == item.id;
        return ChoiceChip(
          label: withIcon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(withIcon, size: 18),
                    const SizedBox(width: 6),
                    Text(item.name),
                  ],
                )
              : Text(item.name),
          selected: isSelected,
          onSelected: (_) => onSelected(item.id),
          selectedColor: Colors.purple[100],
          backgroundColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _buildUploadOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            width: 220,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: _uploadProgress,
                  builder: (_, value, __) => SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: value == 0 ? null : value,
                      strokeWidth: 4,
                      color: Colors.purple,
                      backgroundColor: Colors.purple[50],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Publicando...',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<double>(
                  valueListenable: _uploadProgress,
                  builder: (_, value, __) => Text(
                    value == 0 ? '' : '${(value * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipData {
  final String id;
  final String name;
  _ChipData(this.id, this.name);
}

class _VideoPreview extends StatefulWidget {
  final MediaItem item;
  const _VideoPreview({required this.item});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    // Si el controller todavía no se inicializó (por si pasó algo raro)
    widget.item.initController().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    final c = widget.item.controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _showControls = true;
        _hideTimer?.cancel();
      } else {
        c.play();
        _showControls = true;
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _showControls = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.item.controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: c.value.aspectRatio,
              child: VideoPlayer(c),
            ),
          ),
          AnimatedOpacity(
            opacity: _showControls || !c.value.isPlaying ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              color: Colors.black26,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    c.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          // Barrita de progreso del video
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              c,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.purple,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
