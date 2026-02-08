import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/service/auth_service.dart';

class UserPostsPage extends StatefulWidget {
  final String userId;
  const UserPostsPage({super.key, required this.userId});

  @override
  State<UserPostsPage> createState() => _UserPostsPageState();
}

class _UserPostsPageState extends State<UserPostsPage> {
  List<Post> _posts = [];
  Map<String, dynamic>? _profile;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        PostsService.getPostsByUser(widget.userId),
        AuthService.getUserById(widget.userId),
      ]);

      _posts = results[0] as List<Post>;
      _profile = results[1] as Map<String, dynamic>?;

      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: Center(child: Text(_error!)),
      );
    }

    final avatarUrl = _profile?['avatar'];
    final bio = _profile?['bio'] ?? "";

    final bool isVet = _profile?['es_veterinaria'] == true;
    final String nombreComercial = _profile?['nombre_comercial'] ?? "";

    final String displayName =
        (_profile?['display_name'] ?? "").toString().isNotEmpty
            ? _profile!['display_name']
            : _profile?['username'] ?? "Perfil";

    final String nombreFinal =
        isVet && nombreComercial.isNotEmpty ? nombreComercial : displayName;

    return Scaffold(
      backgroundColor: Colors.white,
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            /// ================= HEADER PERFIL =================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        /// AVATAR
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              avatarUrl != null && avatarUrl.toString().isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                          child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                              ? const Icon(Icons.person,
                                  color: Colors.white, size: 40)
                              : null,
                        ),

                        const SizedBox(width: 20),

                        /// STATS
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _stat(
                                  _profile?['posts_count']?.toString() ?? "0",
                                  "Posts"),
                              _stat(
                                  _profile?['followers_count']?.toString() ??
                                      "0",
                                  "Seguidores"),
                              _stat(
                                  _profile?['following_count']?.toString() ??
                                      "0",
                                  "Siguiendo"),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// NOMBRE + BADGE
                    Row(
                      children: [
                        Text(
                          nombreFinal,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (isVet) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              color: Colors.blue, size: 18),
                        ],
                      ],
                    ),

                    /// BIO
                    if (bio.toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            /// ================= GRID POSTS =================
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _posts[index];

                  final imageUrl = post.imageUrls.isNotEmpty
                      ? post.imageUrls.first
                      : "https://via.placeholder.com/300";

                  return GestureDetector(
                    onTap: () => _openImageViewer(post, imageUrl),
                    child: Hero(
                      tag: 'post_${post.id}',
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.pets, color: Colors.grey),
                        ),
                      ),
                    ),
                  );

                },
                childCount: _posts.length,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style:
              const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
  
void _openImageViewer(Post post, String imageUrl) {
  showDialog(
    context: context,
    barrierColor: Colors.black,
    builder: (_) {
      return GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta != null && details.primaryDelta! > 10) {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: Hero(
                  tag: 'post_${post.id}',
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              /// BOTON CERRAR
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
}
