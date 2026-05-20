import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_app/service/location_service.dart';
import 'package:mobile_app/service/pet_spaces.dart';
import 'package:mobile_app/config.dart';
import 'package:url_launcher/url_launcher.dart';
// ============================================================
// ENUM DE VISTA
// ============================================================
String getFullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '${Config.baseUrl}$path';
}
enum _ViewMode { list, map }

// ============================================================
// PÁGINA PRINCIPAL
// ============================================================

class PagePetSpace extends StatefulWidget {
  const PagePetSpace({super.key});

  @override
  State<PagePetSpace> createState() => _PagePetSpaceState();
}

class _PagePetSpaceState extends State<PagePetSpace>
  with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<NegocioAnimal> _negocios = [];
  int _selectedTab = 0; 
  double? _lat;
  double? _lng;
  String _locationLabel = 'Mi ubicación';

  _ViewMode _viewMode = _ViewMode.list;

  late final AnimationController _toggleAnim;

  @override
  void initState() {
    super.initState();
    _toggleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _initLocation();
  }

  @override
  void dispose() {
    _toggleAnim.dispose();
    super.dispose();
  }

  // ---------- LOCATION ----------

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      _lat = pos.latitude;
      _lng = pos.longitude;

      final address = await LocationService.reverseGeocodeLocation(
        _lat!,
        _lng!,
      );
      if (address != null) {
        setState(() => _locationLabel = address.city);
      }
    } catch (_) {}

    await _loadData();
  }



  Future<void> _loadData() async {
    List<NegocioAnimal> result = [];
    try {
      result = await PetSpacesService.getPetSpaces(lat: _lat, lng: _lng);
    } finally {
      setState(() {
        _loading = false;
        _negocios = result;
      });
    }
  }

  Future<void> _onRefresh() => _loadData();

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == _ViewMode.list ? _ViewMode.map : _ViewMode.list;
      _viewMode == _ViewMode.map
          ? _toggleAnim.forward()
          : _toggleAnim.reverse();
    });
  }

  void _showChangeLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationPickerSheet(
        currentLat: _lat,
        currentLng: _lng,
        currentLabel: _locationLabel,
        onLocationSelected: (lat, lng, label) {
          setState(() {
            _lat = lat;
            _lng = lng;
            _locationLabel = label;
          });
          _loadData();
        },
      ),
    );
  }

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: SafeArea(
        bottom: true,
        child: _loading
            ? const _LoadingView()
            : Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _viewMode == _ViewMode.list
                        ? _buildListView()
                        : _buildMapView(),
                  ),
                 
                ],
              ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
     title: Row(
  children: [
    Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.pink],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Image.asset(
        "assets/logo6.png",
        width: 22,
        height: 22,
      ),
    ),

    const SizedBox(width: 10),

    const Expanded(
      child: Text(
        'WeBaNiMaL',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),
      actions: [
        // Ubicación
        GestureDetector(
          onTap: _showChangeLocationSheet,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.purple,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    _locationLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.location_on, color: Colors.purple, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- LISTA ----------

  Widget _buildListView() {
    return RefreshIndicator(
      key: const ValueKey('list'),
      onRefresh: _onRefresh,
      color: Colors.purple,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _HeroBanner()),
          SliverToBoxAdapter(
            child: _SectionHeader(
              selectedIndex: _selectedTab,
              onChanged: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
            ),
          ),
            SliverList.separated(
            itemCount: _negocios.length,
            separatorBuilder: (_, __) => const SizedBox(height: 1),
            itemBuilder: (context, i) => _NegocioSection(
            data: _negocios[i],
            selectedTab: _selectedTab,
          ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
          ),
        ],
      ),
    );
  }

  // ---------- MAPA ----------

  Widget _buildMapView() {
    final center = LatLng(_lat ?? -34.6, _lng ?? -58.4);
    return Stack(
      key: const ValueKey('map'),
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mobile_app',
            ),
            MarkerLayer(
              markers: _negocios
                  .where((n) => n.lat != null && n.lng != null)
                  .map(
                    (negocio) => Marker(
                      point: LatLng(negocio.lat!, negocio.lng!),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _showNegocioSheet(negocio),
                        child: _MapMarker(negocio: negocio),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        // Mi ubicación
        if (_lat != null && _lng != null)
          Positioned(
            bottom: 20 + MediaQuery.of(context).padding.bottom,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              backgroundColor: Colors.white,
              onPressed: () {},
              child: const Icon(Icons.my_location, color: Colors.purple),
            ),
          ),
        // Contador
        Positioned(
          top: 12,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                const Icon(Icons.storefront, size: 14, color: Colors.purple),
                Text(
                  '${_negocios.length} negocios',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showNegocioSheet(NegocioAnimal negocio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NegocioMapSheet(negocio: negocio),
    );
  }
}

// ============================================================
// MARCADOR DEL MAPA
// ============================================================

class _MapMarker extends StatelessWidget {
  final NegocioAnimal negocio;
  const _MapMarker({required this.negocio});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = getFullImageUrl(negocio.avatar);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.purple, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.storefront,
                      size: 18,
                      color: Colors.purple,
                    ),
                  )
                : const Icon(
                    Icons.storefront,
                    size: 18,
                    color: Colors.purple,
                  ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePainter(color: Colors.purple),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ============================================================
// BOTTOM SHEET DEL MAPA
// ============================================================

class _NegocioMapSheet extends StatelessWidget {
  final NegocioAnimal negocio;
  const _NegocioMapSheet({required this.negocio});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header negocio
          Row(
            children: [
              _AvatarWidget(avatar: negocio.avatar, size: 52, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      negocio.nombreComercio,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    if (negocio.categoria != null) ...[
                      const SizedBox(height: 2),
                      _CategoriaBadge(categoria: negocio.categoria!),
                    ],
                    if (negocio.direccion != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              negocio.direccion!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (negocio.descripcion != null) ...[
            const SizedBox(height: 12),
            Text(
              negocio.descripcion!,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.push('/user-posts/${negocio.userId}');
              },
              child: const Text('Ver perfil y servicios'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HERO BANNER
// ============================================================

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🐾 ESPACIO ANIMAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Negocios y servicios\npara tu mascota',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Veterinarias, tiendas de alimentos y más',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

class _SectionHeader extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;

  const _SectionHeader({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.pink],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Negocios cercanos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    title: 'Promociones',
                    selected: selectedIndex == 0,
                    onTap: () => onChanged(0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    title: 'Direcciones',
                    selected: selectedIndex == 1,
                    onTap: () => onChanged(1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: selected ? Colors.purple : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NEGOCIO SECTION (lista)
// ============================================================

class _NegocioSection extends StatelessWidget {
  final NegocioAnimal data;
  final int selectedTab;
  const _NegocioSection({
    required this.data,
    required this.selectedTab,
  });
Future<void> _openMaps() async {
  if (data.lat == null || data.lng == null) return;

  final url =
      'https://www.google.com/maps/search/?api=1&query=${data.lat},${data.lng}';

  final uri = Uri.parse(url);

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              _AvatarWidget(avatar: data.avatar, size: 46, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/user-posts/${data.userId}'),
                      child: Text(
                        data.nombreComercio,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (selectedTab == 1)
                    Row(
                      spacing: 6,
                      children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 2,
                            children: [
                              Icon(
                                Icons.near_me,
                                size: 11,
                                color: Colors.grey[500],
                              ),
                              Text(
                                'Horarios de Atención: 7:40 a 20:00',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                               
                            ],
                          ),
                      ],
                    ),
                     if (selectedTab == 1)
  Row(
    spacing: 6,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Icon(
            Icons.near_me,
            size: 11,
            color: Colors.grey[500],
          ),
          Flexible(
            child: Text(
              'Dirección: ${data.direccion ?? "Sin dirección disponible"}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ],
  ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/user-posts/${data.userId}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
if (selectedTab == 0 && data.servicios.isNotEmpty)
  SizedBox(
    height: 220,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: data.servicios.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, i) =>
          _ServicioCard(servicio: data.servicios[i]),
    ),
  ),


      ],
    );
  }
}

// ============================================================
// SERVICIO CARD
// ============================================================

class _ServicioCard extends StatelessWidget {
  final ServicioItem servicio;
  const _ServicioCard({required this.servicio});

  @override
  Widget build(BuildContext context) {
    final imageUrl = servicio.imagen;

final screenWidth = MediaQuery.of(context).size.width;
final cardWidth = screenWidth * 0.34;

return Container(
width: cardWidth.clamp(120, 145),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // imagen
          GestureDetector(
  onTap: () {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.82,
                    heightFactor: 0.65,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
                ),
              ),
            ),

              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  },
  child: ClipRRect(
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(14),
    ),
    child: SizedBox(
      height: MediaQuery.of(context).size.height * 0.14,
      width: double.infinity,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Hero(
              tag: imageUrl,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
            )
          : _placeholder(),
    ),
  ),
),
          // contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    servicio.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      servicio.descripcion,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (servicio.precio != null &&
                      servicio.precio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '\$${servicio.precio}',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0BBE4), Color(0xFFBBC8E4)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.storefront, size: 40, color: Colors.white70),
      ),
    );
  }
}

// ============================================================
// WIDGETS REUTILIZABLES
// ============================================================
class _AvatarWidget extends StatelessWidget {
  final String? avatar;
  final double size;
  final double radius;

  const _AvatarWidget({
    required this.avatar,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = getFullImageUrl(avatar);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.grey.shade200,
        gradient: avatarUrl.isEmpty
            ? const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl.isNotEmpty
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.storefront,
                color: Colors.white,
                size: 22,
              ),
            )
          : const Icon(
              Icons.storefront,
              color: Colors.white,
              size: 22,
            ),
    );
  }
}

class _CategoriaBadge extends StatelessWidget {
  final String categoria;
  const _CategoriaBadge({required this.categoria});

  Color get _color {
    switch (categoria.toLowerCase()) {
      case 'veterinaria':
        return Colors.teal;
      case 'alimentos':
        return Colors.orange;
      case 'tienda':
        return Colors.blue;
      case 'peluquería':
      case 'peluqueria':
        return Colors.pink;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        categoria,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

// ============================================================
// LOCATION PICKER SHEET
// ============================================================

class _LocationPickerSheet extends StatefulWidget {
  final double? currentLat;
  final double? currentLng;
  final String currentLabel;
  final void Function(double lat, double lng, String label) onLocationSelected;

  const _LocationPickerSheet({
    required this.currentLat,
    required this.currentLng,
    required this.currentLabel,
    required this.onLocationSelected,
  });

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _controller = TextEditingController();
  bool _searching = false;
  String? _error;
  List<LocationResult> _results = [];

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
      _results = [];
    });
    final results = await LocationService.searchLocation(query);
    setState(() {
      _results = results;
      _searching = false;
      if (results.isEmpty) _error = 'No se encontraron resultados';
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _searching = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      final address = await LocationService.reverseGeocodeLocation(
        pos.latitude,
        pos.longitude,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onLocationSelected(
          pos.latitude,
          pos.longitude,
          address?.city ?? 'Ubicación',
        );
      }
    } catch (_) {
      setState(() {
        _error = 'No se pudo obtener la ubicación';
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cambiar ubicación',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.my_location, color: Colors.purple),
            ),
            title: const Text('Usar mi ubicación actual'),
            onTap: _useCurrentLocation,
          ),
          const Divider(),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Buscar ciudad o barrio...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: _search,
            textInputAction: TextInputAction.search,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._results.map(
              (p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.purple,
                ),
                title: Text(p.displayName.isNotEmpty ? p.displayName : '-'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onLocationSelected(p.lat, p.lng, p.city);
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ============================================================
// LOADING VIEW
// ============================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          height: 130,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        for (int i = 0; i < 2; i++) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 140,
                        color: Colors.grey[200],
                      ),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 90, color: Colors.grey[200]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => Container(
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
