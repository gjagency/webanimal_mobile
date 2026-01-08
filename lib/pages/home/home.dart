import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/posts_service.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  String? selectedTypeId;
  String? selectedPetTypeId;
  Position? _currentPosition;
  DateTimeRange? selectedDateRange;

  List<Post> _posts = [];
  List<PostType> _postTypes = [];
  List<PetType> _petTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      _loadData();
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        PostsService.getPosts(
          postType: selectedTypeId,
          petType: selectedPetTypeId,
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

  List<Post> get filteredPosts {
    return _posts.toList();
  }

  void _clearFilters() {
    setState(() {
      selectedTypeId = null;
      selectedPetTypeId = null;
      selectedDateRange = null;
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
        hasLocation: _currentPosition != null,
        onApply: (typeId, petTypeId) {
          setState(() {
            selectedTypeId = typeId;
            selectedPetTypeId = petTypeId;
          });
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        selectedTypeId != null ||
        selectedPetTypeId != null ||
        selectedDateRange != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.purple, Colors.pink]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.pets, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
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
                        SizedBox(width: 8),
                        ..._postTypes
                            .take(3)
                            .map(
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
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
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
                ? Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error: $_error'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : filteredPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No se encontraron posts',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        return ModernPostCard(post: filteredPosts[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
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
              color: Colors.purple.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => GoRouter.of(context).push('/posts/create'),
            borderRadius: BorderRadius.circular(30),
            child: Center(
              child: Icon(Icons.add, size: 28, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String typeName) {
    switch (typeName.toLowerCase()) {
      case 'adopción':
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

class ModernPostCard extends StatelessWidget {
  final Post post;

  const ModernPostCard({super.key, required this.post});

  PostTypeConfig _getTypeConfig() {
    final typeName = post.postType.name.toLowerCase();

    if (typeName.contains('adopción') || typeName.contains('adopcion')) {
      return PostTypeConfig(
        color: Colors.blue,
        icon: Icons.favorite,
        label: 'EN ADOPCIÓN',
        gradient: [Colors.blue[400]!, Colors.blue[600]!],
      );
    } else if (typeName.contains('perdido')) {
      return PostTypeConfig(
        color: Colors.orange,
        icon: Icons.search,
        label: 'PERDIDO',
        gradient: [Colors.orange[400]!, Colors.red[400]!],
      );
    } else if (typeName.contains('denuncia')) {
      return PostTypeConfig(
        color: Colors.red,
        icon: Icons.report,
        label: 'DENUNCIA',
        gradient: [Colors.red[400]!, Colors.red[700]!],
      );
    } else if (typeName.contains('veterinaria')) {
      return PostTypeConfig(
        color: Colors.purple,
        icon: Icons.medical_services,
        label: 'VETERINARIA',
        gradient: [Colors.purple[400]!, Colors.purple[700]!],
      );
    } else if (typeName.contains('refugio')) {
      return PostTypeConfig(
        color: Colors.teal,
        icon: Icons.home,
        label: 'REFUGIO',
        gradient: [Colors.teal[400]!, Colors.teal[700]!],
      );
    } else {
      return PostTypeConfig(
        color: Colors.green,
        icon: Icons.pets,
        label: post.postType.name.toUpperCase(),
        gradient: [Colors.green[400]!, Colors.green[700]!],
      );
    }
  }

  String _getTimeAgo() {
    final difference = DateTime.now().difference(post.datetime);
    if (difference.inDays > 0) {
      return 'hace ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours}h';
    } else {
      return 'hace ${difference.inMinutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getTypeConfig();

    return InkWell(
      onTap: () => GoRouter.of(context).push('/posts/${post.id}/view'),
      child: Container(
        margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: config.gradient),
                    ),
                    padding: EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: post.user.imageUrl != null
                          ? NetworkImage(post.user.imageUrl!)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: post.user.imageUrl == null
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
                          post.user.username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                post.location.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _getTimeAgo(),
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: config.gradient),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(config.icon, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          config.label,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Image.network(
                post.imageUrl ??
                    "https://via.placeholder.com/400x300?text=Sin+Imagen",
                width: double.infinity,
                height: 350,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 350,
                    color: Colors.grey[200],
                    child: Icon(Icons.pets, size: 100, color: Colors.grey),
                  );
                },
              ),
            ),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildActionButton(
                    Icons.favorite_border,
                    post.likes.toString(),
                  ),
                  SizedBox(width: 20),
                  _buildActionButton(
                    Icons.chat_bubble_outline,
                    post.comments.toString(),
                  ),
                  SizedBox(width: 20),
                  _buildActionButton(Icons.share_outlined, ''),
                  Spacer(),
                  Icon(Icons.bookmark_border, size: 26),
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
                      text: post.user.username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' ${post.description}'),
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

  Widget _buildActionButton(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 26),
        if (count.isNotEmpty) ...[
          SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ],
    );
  }
}

class PostTypeConfig {
  final Color color;
  final IconData icon;
  final String label;
  final List<Color> gradient;

  PostTypeConfig({
    required this.color,
    required this.icon,
    required this.label,
    required this.gradient,
  });
}

class FilterBottomSheet extends StatefulWidget {
  final String? selectedTypeId;
  final String? selectedPetTypeId;
  final List<PostType> postTypes;
  final List<PetType> petTypes;
  final bool hasLocation;
  final Function(String?, String?) onApply;

  const FilterBottomSheet({
    super.key,
    this.selectedTypeId,
    this.selectedPetTypeId,
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

  @override
  void initState() {
    super.initState();
    tempTypeId = widget.selectedTypeId;
    tempPetTypeId = widget.selectedPetTypeId;
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
            padding: const EdgeInsets.all(20.0),
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
                          widget.onApply(tempTypeId, tempPetTypeId);
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
