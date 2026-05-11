import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:mobile_app/service/location_service.dart';
import 'package:mobile_app/service/posts_service.dart';

class PagePromotions extends StatefulWidget {
  const PagePromotions({super.key});

  @override
  State<PagePromotions> createState() => _PagePromotionsState();
}

class _PagePromotionsState extends State<PagePromotions> {
  bool loading = true;
  bool fetching = false;
  List<PromocionesPorVeterinaria> promotions = [];

  double? _lat;
  double? _lng;
  String _locationLabel = 'Mi ubicación';

  @override
  void initState() {
    super.initState();

    _initLocation();
  }

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
    } catch (_) {
      // sin permiso o error, carga sin coords
    }

    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      fetching = true;
    });

    List<Map<String, dynamic>> result = [];

    try {
      result = await AuthService.getOfertasPromociones(lat: _lat, lng: _lng);
    } finally {
      setState(() {
        fetching = false;
        loading = false;
        promotions = result
            .map((row) => PromocionesPorVeterinaria.fromJson(row))
            .toList();
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        titleSpacing: 0,
          title: Row(
          children: [
            Expanded(
              child: const Text(
                'WebAnimal',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,  ),
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _showChangeLocationSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.purple,
                  ),
                  Flexible(
                    child: Text(
                      _locationLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Icon(Icons.location_on, color: Colors.purple, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: Colors.purple,
          child: loading
              ? _LoadingView()
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: _HeroBanner()),
                    const SliverToBoxAdapter(child: _SectionDivider()),
                    SliverList.separated(
                      itemCount: promotions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          _VeterinariaSection(data: promotions[i]),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 90,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ============ LOCATION PICKER SHEET ============
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
          address?.city ?? "Ubicacion",
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
          // handle
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
          // usar ubicación actual
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
          // búsqueda manual
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
            ..._results.asMap().entries.map((e) {
              final p = e.value;
              return ListTile(
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
              );
            }),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              "No se encontraron resultados",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ============ HERO BANNER ============
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
          colors: [Color(0xFF8E2DE2), Color(0xFFE94057), Color(0xFFFF8A65)],
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
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🔥 OFERTAS DEL DÍA',
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
                  'Cuidá a tu mascota con descuentos únicos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 0.0,
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
            child: const Icon(Icons.local_offer, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }
}

// ============ SECCIÓN POR VETERINARIA ============
class _VeterinariaSection extends StatelessWidget {
  final PromocionesPorVeterinaria data;

  const _VeterinariaSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: data.avatar == null || data.avatar!.isEmpty
                      ? const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        )
                      : null,
                  color: Colors.grey.shade200,
                ),
                clipBehavior: Clip.antiAlias,
                child: data.avatar != null && data.avatar!.isNotEmpty
                    ? Image.network(
                        'https://webanimal.com.ar${data.avatar}',
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.push('/user-posts/${data.userId}');
                      },
                      child: Text(
                        data.nombreComercio,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_offer,
                          size: 12,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data.promociones.length} promociones disponibles',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: data.promociones.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                _PromocionCard(promocion: data.promociones[i]),
          ),
        ),
      ],
    );
  }
}

// ============ CARD DE PROMOCIÓN ============
class _PromocionCard extends StatelessWidget {
  final Promocion promocion;
  const _PromocionCard({required this.promocion});

  @override
  Widget build(BuildContext context) {
    final imageUrl = promocion.imagen != null && promocion.imagen!.isNotEmpty
        ? 'https://webanimal.com.ar${promocion.imagen}'
        : null;
    return GestureDetector(
      onTap: () {
        // navegar al detalle si tenés ruta
        // context.push('/promocion/${promocion.id}');
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // imagen + badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stackTrace) {
                              debugPrint('Error cargando imagen: $imageUrl');
                              return _placeholderImage();
                            },
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
                          )
                        : _placeholderImage(),
                  ),
                ),
                if (promocion.precio != null && promocion.precio!.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'OFERTA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promocion.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        promocion.descripcion,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (promocion.precio != null &&
                        promocion.precio!.isNotEmpty)
                      Text(
                        '\$${promocion.precio}',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    if (promocion.fechahasta != null &&
                        promocion.fechahasta!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 11,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'Hasta ${_formatDate(promocion.fechahasta!)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0BBE4), Color(0xFFFFC3A0)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.pets, size: 48, color: Colors.white70),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

// ============ DIVIDER DECORATIVO ============
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.purple, Colors.pink],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Veterinarias con ofertas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ============ ESTADOS ============
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        for (int i = 0; i < 2; i++) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
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
                        width: 150,
                        color: Colors.grey[200],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 100,
                        color: Colors.grey[200],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'No pudimos cargar las promociones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Verificá tu conexión e intentá de nuevo',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              size: 56,
              color: Colors.purple,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'No hay promociones disponibles',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Volvé pronto para ver nuevas ofertas',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}
