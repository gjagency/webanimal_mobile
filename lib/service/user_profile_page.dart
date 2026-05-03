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
  
  bool loadingProfile = true;

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
  titleSpacing: 8,
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
        child: const Icon(
          Icons.pets,
          color: Colors.white,
          size: 20,
        ),
      ),
      const SizedBox(width: 8),

      Expanded(
        child: const Text(
          'WebAnimal',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () {
        context.push('/account/notifications');
      },
    ),

    // ir a perfil
    IconButton(
      onPressed: () {
        context.push('/user-posts/${AuthService.currentUserId}');
      },
      icon: loadingProfile
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey,
                    )
                  : null,
            ),
    ),


    // configuraciones 3 puntitos
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'settings') {
          context.push('/account/settings');
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, size: 20),
              SizedBox(width: 8),
              Text('Configuración'),
            ],
          ),
        ),
      ],
    ),

    const SizedBox(width: 4),
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
                    onTap: () => _openImageViewer(post, 0),
                    child: Stack(
                      children: [
                        /// IMAGEN
                        Positioned.fill(
                          child: Hero(
                            tag: '${post.id}_0',
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        /// OVERLAY +X IMAGENES
                        if (post.imageUrls.length > 1)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+${post.imageUrls.length - 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
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
  
void _openImageViewer(Post post, int initialIndex) {
  final PageController controller = PageController(initialPage: initialIndex);
  int currentIndex = initialIndex;
  bool showHeart = false;

  /// PRECARGA IMAGENES (ULTRA SMOOTH)
  for (var url in post.imageUrls) {
    precacheImage(NetworkImage(url), context);
  }

  showDialog(
    context: context,
    barrierColor: Colors.black,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          return GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! > 12) {
                Navigator.pop(context);
              }
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  /// ================= PAGEVIEW =================
                  PageView.builder(
                    controller: controller,
                    itemCount: post.imageUrls.length,
                    onPageChanged: (i) =>
                        setState(() => currentIndex = i),
                    itemBuilder: (context, index) {
                      final imageUrl = post.imageUrls[index];

                      return GestureDetector(
                        onDoubleTap: () async {
                          setState(() => showHeart = true);
                          await Future.delayed(
                              const Duration(milliseconds: 700));
                          if (mounted) setState(() => showHeart = false);
                        },
                        child: Center(
                          child: Hero(
                            tag: '${post.id}_$index',
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 250),
                                opacity: 1,
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  /// ================= HEART ANIMATION =================
                  if (showHeart)
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.4, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 110,
                            ),
                          );
                        },
                      ),
                    ),

                  /// ================= CLOSE =================
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  /// ================= DOTS =================
                  if (post.imageUrls.length > 1)
                    Positioned(
                      bottom: 35,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          post.imageUrls.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            width: i == currentIndex ? 10 : 6,
                            height: i == currentIndex ? 10 : 6,
                            decoration: BoxDecoration(
                              color: i == currentIndex
                                  ? Colors.white
                                  : Colors.white38,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}



}
