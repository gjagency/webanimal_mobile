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

    final avatar = _profile?['avatar'];
    final displayName =
        "${_profile?['first_name'] ?? ''} ${_profile?['last_name'] ?? ''}"
            .trim()
            .isNotEmpty
        ? "${_profile?['first_name'] ?? ''} ${_profile?['last_name'] ?? ''}"
        : _profile?['username'] ?? "Perfil";
final avatarUrl = _profile?['avatar'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(displayName),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            /// ================= HEADER PERFIL =================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    /// AVATAR
CircleAvatar(
  radius: 40,
  backgroundColor: Colors.grey[300],
  backgroundImage: avatarUrl != null && avatarUrl.toString().isNotEmpty
      ? NetworkImage(avatarUrl)
      : null,
  child: (avatarUrl == null || avatarUrl.toString().isEmpty)
      ? const Icon(Icons.person, color: Colors.white, size: 40)
      : null,
),

           


                    const SizedBox(width: 20),

                    /// STATS
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat(_posts.length.toString(), "Posts"),
                          _stat(
                              (_profile?['followers'] ?? 0).toString(),
                              "Seguidores"),
                          _stat(
                              (_profile?['following'] ?? 0).toString(),
                              "Siguiendo"),
                        ],
                      ),
                    ),
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
                    onTap: () => context.push('/post/${post.id}'),
                    child: Hero(
                      tag: 'post_${post.id}',
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child:
                              const Icon(Icons.pets, color: Colors.grey),
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
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
