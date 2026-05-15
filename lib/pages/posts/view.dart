import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/utils/share_post_helper.dart';
import 'package:mobile_app/widgets/modern_post_card.dart';
class PagePostView extends StatefulWidget {
  final String postId;
  const PagePostView({super.key, required this.postId});

  @override
  State<PagePostView> createState() => _PagePostViewState();
}

class _PagePostViewState extends State<PagePostView> {
  int _visibleComments = 10;
  String avatarUrl = '';
  bool loadingProfile = true;
  Post? _post;
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadProfile();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _shareToFacebookFeed() async {
    if (_post == null || _post!.medias.isEmpty) return;

    await SharePostHelper.sharePost(
      imageUrl: _post!.medias.first.url,
      postType: _post!.postType.name,
      fileName: 'shared_${widget.postId}',
    );
  }

  Future<void> _loadPost() async {
    try {
      final results = await Future.wait([
        PostsService.getPost(widget.postId),
        PostsService.getComments(widget.postId),
      ]);

      setState(() {
        _post = results[0] as Post;
        _comments = results[1] as List<Comment>;
        _visibleComments = 10;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    await PostsService.addReaction(int.parse(widget.postId), 1);
    await _loadPost();
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    try {
      await PostsService.addComment(widget.postId, _commentController.text);
      _commentController.clear();
      FocusScope.of(context).unfocus(); // 👈 cierra teclado
      _loadPost();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comentario agregado')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al comentar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Cargando...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Error: $_error'),
              ElevatedButton(onPressed: _loadPost, child: Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final post = _post!;

    final colorHex = post.postType.color ?? '#9E9E9E'; // gris default

    final color = Color(int.parse(colorHex.replaceAll('#', '0xff')));

    final colors = [color.withValues(alpha: 0.7), color];

    IconData _mapIcon(String? iconCode) {
      switch (iconCode) {
        case '0xe87c':
          return Icons.pets;
        case '0xe7fd':
          return Icons.person;
        case '0xe87d':
          return Icons.favorite;
        case '0xe0b7':
          return Icons.chat;
        default:
          return Icons.pets;
      }
    }

    final icon = _mapIcon(post.postType.icon);
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
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
              child: const Icon(Icons.pets, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: const Text(
                'WebAnimal',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                        ? const Icon(Icons.person, size: 16, color: Colors.grey)
                        : null,
                  ),
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.only(bottom: 6),
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: colors),
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
                            GestureDetector(
                              onTap: () {
                                context.push('/user-posts/${post.user.id}');
                              },
                              child: Text(
                                post.user.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),

                            Text(
                              "${_getTimeAgo(post.datetime)} - ${post.location.label}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: colors),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              post.postType.name,
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

// Descripción
if (post.description.isNotEmpty)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      post.description,
      style: const TextStyle(
        fontSize: 14,
        height: 1.4,
      ),
    ),
  ),

const SizedBox(height: 12),
// Teléfono
if (post.telefono != null && post.telefono!.isNotEmpty)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Icon(
          Icons.phone,
          size: 16,
          color: Colors.green.shade700,
        ),
        const SizedBox(width: 6),
        Text(
          post.telefono!,
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  ),

const SizedBox(height: 14),

// MEDIA
GestureDetector(

child: post.medias.first.isVideo
    ? Container(
        width: double.infinity,
        height: 400,
        color: Colors.black,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: FeedVideoPlayer(
            url: post.medias.first.url,
          ),
        ),
      )
      : Image.network(
          post.medias.isNotEmpty
              ? post.medias.first.url
              : "https://via.placeholder.com/400x300?text=Sin+Imagen",
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Icon(
                Icons.pets,
                size: 100,
                color: Colors.grey,
              ),
            );
          },
        ),
),
                // Acciones
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Row(
                          children: [
                            post.reacciones.isNotEmpty
                                ? Icon(
                                    Icons.favorite,
                                    size: 28,
                                    color: Colors.red,
                                  )
                                : Icon(Icons.favorite_border, size: 28),
                            SizedBox(width: 4),
                            Text(
                              '${post.likes}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 20),

                      Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 26,
                            color: Colors.grey[700],
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${post.comments}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      IconButton(
                        onPressed: _shareToFacebookFeed,
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Color(0xFF1877F2),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

               

                Divider(height: 32, thickness: 8, color: Colors.grey[100]),

                // Comentarios
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Comentarios',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 16),

                _comments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No hay comentarios aún',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _comments.length > _visibleComments
                                ? _visibleComments
                                : _comments.length,
                            itemBuilder: (context, index) {
                              return CommentCard(comment: _comments[index]);
                            },
                          ),

                          if (_comments.length > _visibleComments)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _visibleComments += 10;
                                  });
                                },
                                child: Text(
                                  'Mostrar más comentarios',
                                  style: TextStyle(
                                    color: Colors.pink.shade400,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                SizedBox(height: 80), // para que no quede pegado al bottom
              ],
            ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: TextField(
                    controller: _commentController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.pink],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _addComment,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime datetime) {
    final diff = DateTime.now().difference(datetime);
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inMinutes}m';
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.getProfile();

      setState(() {
        avatarUrl = profile['avatar'] ?? '';
        loadingProfile = false;
      });
    } catch (e) {
      setState(() {
        loadingProfile = false;
      });
    }
  }
}

class CommentCard extends StatelessWidget {
  final Comment comment;
  const CommentCard({super.key, required this.comment});

  String _getTimeAgo() {
    final diff = DateTime.now().difference(comment.timestamp);
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'hace ${diff.inMinutes}m';
    return 'ahora';
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('COMMENT AVATAR (UI) → ${comment.avatar}');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: comment.avatar != null
                ? NetworkImage(comment.avatar!)
                : null,
            backgroundColor: Colors.grey[300],
            child: comment.avatar == null
                ? Icon(Icons.person, color: Colors.white)
                : null,
          ),

          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (comment.userId != null) {
                            context.push('/user-posts/${comment.userId}');
                          }
                        },
                        child: Text(
                          comment.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      SizedBox(height: 4),
                      Text(comment.text, style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    _getTimeAgo(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
