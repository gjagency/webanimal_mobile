import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/posts_service.dart';


class ModernPostCard extends StatefulWidget {
  final Post post;

  const ModernPostCard({super.key, required this.post});

  @override
  State<ModernPostCard> createState() => _ModernPostCardState();
}

class _ModernPostCardState extends State<ModernPostCard> {
  bool liked = false;
  int likesIncrement = 0;

  @override
  void initState() {
    super.initState();
    liked = widget.post.reacciones.isNotEmpty;
  }

  String _getTimeAgo() {
    final difference = DateTime.now().difference(widget.post.datetime);
    if (difference.inDays > 0) return 'hace ${difference.inDays}d';
    if (difference.inHours > 0) return 'hace ${difference.inHours}h';
    return 'hace ${difference.inMinutes}m';
  }

  Future<void> _toggleLike() async {
    await PostsService.addReaction(widget.post.id, "1");
    setState(() {
      liked = !liked;
      likesIncrement = liked ? likesIncrement + 1 : likesIncrement - 1;
    });
  }

  void _openImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(widget.post.postType.color.replaceAll('#', '0xff')));
    final icon = IconData(int.parse(widget.post.postType.icon), fontFamily: 'MaterialIcons');

    return InkWell(
      onTap: () => GoRouter.of(context).push('/posts/${widget.post.id}/view'),
      onDoubleTap: _toggleLike,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: widget.post.user.imageUrl != null
                        ? NetworkImage(widget.post.user.imageUrl!)
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: widget.post.user.imageUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.post.user.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(
                          '${_getTimeAgo()} - ${widget.post.location.label}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          widget.post.postType.name,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Imagen
            if (widget.post.imageUrl != null)
              GestureDetector(
                onTap: () => _openImagePopup(context, widget.post.imageUrl!),
                child: ClipRRect(
                  child: Image.network(
                    widget.post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(liked ? Icons.favorite : Icons.favorite_border,
                            color: liked ? Colors.red : null, size: 28),
                        const SizedBox(width: 4),
                        Text('${widget.post.likes + likesIncrement}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 28),
                      const SizedBox(width: 4),
                      Text('${widget.post.comments}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            // Descripción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.4),
                  children: [
                    TextSpan(text: widget.post.user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' ${widget.post.description}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
