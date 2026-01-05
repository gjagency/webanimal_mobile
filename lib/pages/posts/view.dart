import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PagePostView extends StatefulWidget {
  final String postId;

  const PagePostView({super.key, required this.postId});

  @override
  State<PagePostView> createState() => _PagePostViewState();
}

class _PagePostViewState extends State<PagePostView> {
  bool isLiked = false;
  bool isSaved = false;
  int likes = 128;
  final TextEditingController _commentController = TextEditingController();

  final List<Comment> comments = [
    Comment(
      username: 'maria_rodriguez',
      userAvatar: 'https://i.pravatar.cc/150?img=1',
      comment: 'Hermosa mascota! ❤️',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      likes: 12,
    ),
    Comment(
      username: 'carlos_mendez',
      userAvatar: 'https://i.pravatar.cc/150?img=3',
      comment: 'Espero que encuentres familia pronto 🙏',
      timestamp: DateTime.now().subtract(Duration(hours: 5)),
      likes: 8,
    ),
    Comment(
      username: 'ana_garcia',
      userAvatar: 'https://i.pravatar.cc/150?img=5',
      comment: 'Qué linda! Me interesa adoptar',
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      likes: 5,
    ),
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likes += isLiked ? 1 : -1;
    });
  }

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        comments.insert(
          0,
          Comment(
            username: 'tu_usuario',
            userAvatar: 'https://i.pravatar.cc/150?img=10',
            comment: _commentController.text,
            timestamp: DateTime.now(),
            likes: 0,
          ),
        );
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Editar'),
                  ],
                ),
                onTap: () => context.push('/posts/${widget.postId}/edit'),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 12),
                    Text('Compartir'),
                  ],
                ),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.report, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Reportar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Header del post
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profiles/refugio_patitas'),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.blue[400]!, Colors.blue[600]!],
                            ),
                          ),
                          padding: EdgeInsets.all(2),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=2',
                            ),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'refugio_patitas',
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
                                Text(
                                  'Palermo • hace 5h',
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'ADOPCIÓN',
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
                  'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e',
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

                // Botones de acción
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 28,
                              color: isLiked ? Colors.red : Colors.black,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '$likes',
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
                            '${comments.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 20),
                      Icon(Icons.share_outlined, size: 28),
                      Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => isSaved = !isSaved),
                        child: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 28,
                          color: isSaved ? Colors.purple : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // Descripción
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'refugio_patitas',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  ' Luna busca familia ❤️ Es una cachorra muy cariñosa de 6 meses. Esterilizada y vacunada.',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            avatar: Icon(Icons.pets, size: 16),
                            label: Text(
                              'Perro',
                              style: TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.purple[50],
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(
                              '6 meses',
                              style: TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue[50],
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(
                              'Vacunada',
                              style: TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.green[50],
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
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
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return CommentCard(comment: comments[index]);
                  },
                ),
                SizedBox(height: 80),
              ],
            ),
          ),

          // Input de comentario
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=10',
                  ),
                ),
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
}

class Comment {
  final String username;
  final String userAvatar;
  final String comment;
  final DateTime timestamp;
  final int likes;

  Comment({
    required this.username,
    required this.userAvatar,
    required this.comment,
    required this.timestamp,
    required this.likes,
  });
}

class CommentCard extends StatelessWidget {
  final Comment comment;

  const CommentCard({super.key, required this.comment});

  String _getTimeAgo() {
    final difference = DateTime.now().difference(comment.timestamp);
    if (difference.inDays > 0) return 'hace ${difference.inDays}d';
    if (difference.inHours > 0) return 'hace ${difference.inHours}h';
    if (difference.inMinutes > 0) return 'hace ${difference.inMinutes}m';
    return 'ahora';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(comment.userAvatar),
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
                      Text(
                        comment.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(comment.comment, style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      Text(
                        _getTimeAgo(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(width: 16),
                      Text(
                        '${comment.likes} Me gusta',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Responder',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
