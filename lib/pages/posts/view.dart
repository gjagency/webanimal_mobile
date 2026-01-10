import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/posts_service.dart';

class PagePostView extends StatefulWidget {
  final String postId;
  const PagePostView({super.key, required this.postId});

  @override
  State<PagePostView> createState() => _PagePostViewState();
}

class _PagePostViewState extends State<PagePostView> {
  Post? _post;
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
    await PostsService.addReaction(widget.postId, "1");
    await _loadPost();
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    try {
      await PostsService.addComment(widget.postId, _commentController.text);
      _commentController.clear();
      _loadPost();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Comentario agregado')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al comentar')));
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

    final color = Color(int.parse(post.postType.color.replaceAll('#', '0xff')));
    final colors = [color.withValues(alpha: 0.7), color];
    final icon = IconData(
      int.parse(post.postType.icon),
      fontFamily: 'MaterialIcons',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Publicación',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(16),
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
                            Text(
                              post.user.username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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

                // Imagen
                Image.network(
                  post.imageUrl ??
                      "https://via.placeholder.com/400x300?text=Sin+Imagen",
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 400,
                      color: Colors.grey[200],
                      child: Icon(Icons.pets, size: 100, color: Colors.grey),
                    );
                  },
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
                          Icon(Icons.chat_bubble_outline, size: 28),
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
                    ],
                  ),
                ),

                // Descripción
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
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
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No hay comentarios aún',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) =>
                            CommentCard(comment: _comments[index]),
                      ),
                SizedBox(height: 80),
              ],
            ),
          ),

          // Input comentario
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: Colors.grey[300]),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.pink],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _addComment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime datetime) {
    final diff = DateTime.now().difference(datetime);
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inMinutes}m';
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, backgroundColor: Colors.grey[300]),
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
                      Text(
                        comment.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
