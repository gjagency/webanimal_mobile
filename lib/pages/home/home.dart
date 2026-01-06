import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum PostType { adopcion, perdido, denuncia, veterinaria, refugio, miMascota }
enum PetType { perro, gato, ave, otros }

class Post {
  final String id;
  final String username;
  final String userAvatar;
  final PostType type;
  final PetType petType;
  final String imageUrl;
  final String description;
  final String? location;
  final DateTime timestamp;
  final int likes;
  final int comments;

  Post({
    required this.id,
    required this.username,
    required this.userAvatar,
    required this.type,
    required this.petType,
    required this.imageUrl,
    required this.description,
    this.location,
    required this.timestamp,
    this.likes = 0,
    this.comments = 0,
  });
}

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  PostType? selectedType;
  PetType? selectedPetType;
  String? selectedLocation;
  DateTimeRange? selectedDateRange;

  final List<Post> allPosts = [
    Post(
      id: "b3a6d43c-012e-45c1-82e6-a1b2320c9f84",
      username: 'maria_rodriguez',
      userAvatar: 'https://i.pravatar.cc/150?img=1',
      type: PostType.perdido,
      petType: PetType.perro,
      imageUrl: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1',
      description:
          '¡URGENTE! Se perdió mi golden retriever "Max" en zona Centro. Por favor ayúdenme a encontrarlo 🙏',
      location: 'Centro',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      likes: 45,
      comments: 12,
    ),
    Post(
      id: "1df17a27-b449-4147-857d-04480e11d888",
      username: 'refugio_patitas',
      userAvatar: 'https://i.pravatar.cc/150?img=2',
      type: PostType.adopcion,
      petType: PetType.perro,
      imageUrl: 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e',
      description:
          'Luna busca familia ❤️ Es una cachorra muy cariñosa de 6 meses. Esterilizada y vacunada.',
      location: 'Palermo',
      timestamp: DateTime.now().subtract(Duration(hours: 5)),
      likes: 128,
      comments: 23,
    ),
    Post(
      id: "85d7ae38-7a29-4c82-90c8-b5d663d0d93b",
      username: 'carlos_mendez',
      userAvatar: 'https://i.pravatar.cc/150?img=3',
      type: PostType.denuncia,
      petType: PetType.perro,
      imageUrl: 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b',
      description:
          'Denuncio maltrato animal en calle San Martin 1234. Por favor ayuden a estos animales.',
      location: 'Recoleta',
      timestamp: DateTime.now().subtract(Duration(hours: 8)),
      likes: 89,
      comments: 34,
    ),
    Post(
      id: "817023fa-c52c-490f-be38-7a551c4c0683",
      username: 'vet_saludable',
      userAvatar: 'https://i.pravatar.cc/150?img=4',
      type: PostType.veterinaria,
      petType: PetType.gato,
      imageUrl: 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97',
      description:
          '🏥 Campaña de vacunación gratuita este sábado de 9 a 17hs. ¡Traé a tu mascota!',
      location: 'Belgrano',
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      likes: 234,
      comments: 56,
    ),
    Post(
      id: "2be2ebd4-3027-464f-b626-b401ab861f1d",
      username: 'ana_garcia',
      userAvatar: 'https://i.pravatar.cc/150?img=5',
      type: PostType.miMascota,
      petType: PetType.gato,
      imageUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba',
      description: 'Mi gato Simón disfrutando el solcito de la tarde 🌞😺',
      location: 'Caballito',
      timestamp: DateTime.now().subtract(Duration(days: 2)),
      likes: 167,
      comments: 18,
    ),
    Post(
      id: "c61fd993-aeaa-4c55-b9cc-8b671e724248",
      username: 'hogar_perruno',
      userAvatar: 'https://i.pravatar.cc/150?img=6',
      type: PostType.refugio,
      petType: PetType.perro,
      imageUrl: 'https://images.unsplash.com/photo-1587300003388-59208cc962cb',
      description:
          'Necesitamos donaciones de alimento balanceado 🙏 Actualmente tenemos 45 perritos en el refugio.',
      location: 'Flores',
      timestamp: DateTime.now().subtract(Duration(days: 3)),
      likes: 312,
      comments: 67,
    ),
  ];

  List<Post> get filteredPosts {
    return allPosts.where((post) {
      if (selectedType != null && post.type != selectedType) return false;
      if (selectedPetType != null && post.petType != selectedPetType) return false;
      if (selectedLocation != null && post.location != selectedLocation) return false;
      if (selectedDateRange != null) {
        if (post.timestamp.isBefore(selectedDateRange!.start) ||
            post.timestamp.isAfter(selectedDateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      selectedType = null;
      selectedPetType = null;
      selectedLocation = null;
      selectedDateRange = null;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        selectedType: selectedType,
        selectedPetType: selectedPetType,
        selectedLocation: selectedLocation,
        selectedDateRange: selectedDateRange,
        onApply: (type, petType, location, dateRange) {
          setState(() {
            selectedType = type;
            selectedPetType = petType;
            selectedLocation = location;
            selectedDateRange = dateRange;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        selectedType != null || selectedPetType != null || selectedLocation != null || selectedDateRange != null;

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
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () => GoRouter.of(context).push('/account/notifications'),
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
                        _buildQuickFilter('Todos', Icons.grid_view_rounded, selectedType == null, () => setState(() => selectedType = null)),
                        SizedBox(width: 8),
                        _buildQuickFilter('Adopción', Icons.favorite, selectedType == PostType.adopcion, () => setState(() => selectedType = PostType.adopcion)),
                        SizedBox(width: 8),
                        _buildQuickFilter('Perdidos', Icons.search, selectedType == PostType.perdido, () => setState(() => selectedType = PostType.perdido)),
                        SizedBox(width: 8),
                        _buildQuickFilter('Denuncias', Icons.report, selectedType == PostType.denuncia, () => setState(() => selectedType = PostType.denuncia)),
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
                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (hasFilters)
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (selectedPetType != null)
                    _buildActiveFilterChip(_getPetTypeLabel(selectedPetType!), () => setState(() => selectedPetType = null)),
                  if (selectedLocation != null)
                    _buildActiveFilterChip(selectedLocation!, () => setState(() => selectedLocation = null)),
                  if (selectedDateRange != null)
                    _buildActiveFilterChip('Rango de fecha', () => setState(() => selectedDateRange = null)),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: Icon(Icons.clear_all, size: 16),
                    label: Text('Limpiar filtros'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red, padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: filteredPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No se encontraron posts', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) => ModernPostCard(post: filteredPosts[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => GoRouter.of(context).push('/posts/uuid/edit'),
        backgroundColor: Colors.purple,
        child: Icon(Icons.add),
      ),
    );
  }

  // Filtros y chips
  Widget _buildQuickFilter(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: [Colors.purple, Colors.pink]) : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black87),
            SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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
}

// ------------------ MODERN POST CARD -----------------
class ModernPostCard extends StatelessWidget {
  final Post post;

  const ModernPostCard({super.key, required this.post});

  PostTypeConfig _getTypeConfig() {
    switch (post.type) {
      case PostType.adopcion:
        return PostTypeConfig(color: Colors.blue, icon: Icons.favorite, label: 'EN ADOPCIÓN', gradient: [Colors.blue[400]!, Colors.blue[600]!]);
      case PostType.perdido:
        return PostTypeConfig(color: Colors.orange, icon: Icons.search, label: 'PERDIDO', gradient: [Colors.orange[400]!, Colors.red[400]!]);
      case PostType.denuncia:
        return PostTypeConfig(color: Colors.red, icon: Icons.report, label: 'DENUNCIA', gradient: [Colors.red[400]!, Colors.red[700]!]);
      case PostType.veterinaria:
        return PostTypeConfig(color: Colors.purple, icon: Icons.medical_services, label: 'VETERINARIA', gradient: [Colors.purple[400]!, Colors.purple[700]!]);
      case PostType.refugio:
        return PostTypeConfig(color: Colors.teal, icon: Icons.home, label: 'REFUGIO', gradient: [Colors.teal[400]!, Colors.teal[700]!]);
      case PostType.miMascota:
        return PostTypeConfig(color: Colors.green, icon: Icons.pets, label: 'MI MASCOTA', gradient: [Colors.green[400]!, Colors.green[700]!]);
    }
  }

  String _getTimeAgo() {
    final difference = DateTime.now().difference(post.timestamp);
    if (difference.inDays > 0) return 'hace ${difference.inDays}d';
    if (difference.inHours > 0) return 'hace ${difference.inHours}h';
    return 'hace ${difference.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final config = _getTypeConfig();
    return InkWell(
      onTap: () => GoRouter.of(context).push('/posts/${post.id}/view'),
      child: Container(
        margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(children: [
              CircleAvatar(radius: 22, backgroundImage: NetworkImage(post.userAvatar), backgroundColor: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post.username, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Row(
                    children: [
                      if (post.location != null) ...[
                        Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(post.location!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        SizedBox(width: 8),
                      ],
                      Text(_getTimeAgo(), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ]),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(gradient: LinearGradient(colors: config.gradient), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(config.icon, color: Colors.white, size: 14), SizedBox(width: 4), Text(config.label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))],
                ),
              ),
            ]),
          ),
          // IMAGEN
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: Image.network(post.imageUrl, width: double.infinity, height: 350, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
              return Container(width: double.infinity, height: 350, color: Colors.grey[200], child: Icon(Icons.pets, size: 100, color: Colors.grey));
            }),
          ),
          SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class PostTypeConfig {
  final Color color;
  final IconData icon;
  final String label;
  final List<Color> gradient;

  PostTypeConfig({required this.color, required this.icon, required this.label, required this.gradient});
}

// ------------------ FILTER BOTTOM SHEET -----------------
class FilterBottomSheet extends StatefulWidget {
  final PostType? selectedType;
  final PetType? selectedPetType;
  final String? selectedLocation;
  final DateTimeRange? selectedDateRange;
  final Function(PostType?, PetType?, String?, DateTimeRange?) onApply;

  const FilterBottomSheet({
    super.key,
    this.selectedType,
    this.selectedPetType,
    this.selectedLocation,
    this.selectedDateRange,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  PostType? tempSelectedType;
  PetType? tempSelectedPetType;
  String? tempSelectedLocation;
  DateTimeRange? tempSelectedDateRange;

  @override
  void initState() {
    super.initState();
    tempSelectedType = widget.selectedType;
    tempSelectedPetType = widget.selectedPetType;
    tempSelectedLocation = widget.selectedLocation;
    tempSelectedDateRange = widget.selectedDateRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, color: Colors.grey[300], margin: EdgeInsets.only(bottom: 16))),
          Text('Filtrar publicaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 16),
          // Aquí podés agregar dropdowns, selects y datepickers
          ElevatedButton(
            onPressed: () {
              widget.onApply(tempSelectedType, tempSelectedPetType, tempSelectedLocation, tempSelectedDateRange);
              Navigator.pop(context);
            },
            child: Text('Aplicar filtros'),
          ),
        ],
      ),
    );
  }
}
