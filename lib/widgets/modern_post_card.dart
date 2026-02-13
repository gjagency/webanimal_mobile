import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mobile_app/service/posts_service.dart';

class ModernPostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onEdit;

  const ModernPostCard({super.key, required this.post, this.onEdit});


  @override
  State<ModernPostCard> createState() => _ModernPostCardState();
}

class _ModernPostCardState extends State<ModernPostCard> {
  static const _channel = MethodChannel('share_to_facebook');
int _currentImageIndex = 0;
  bool liked = false;
  int likesIncrement = 0;

  @override
void initState() {
  super.initState();
  liked = widget.post.reacciones.isNotEmpty;
}

  // ================= TIEMPO =================
  String _getTimeAgo() {
    final diff = DateTime.now().difference(widget.post.datetime);
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inMinutes}m';
  }

  // ================= LIKE =================
  Future<void> _toggleLike() async {
    await PostsService.addReaction(int.parse(widget.post.id), 1);
    setState(() {
      liked = !liked;
      likesIncrement += liked ? 1 : -1;
    });
  }

  // ================= SHARE =================
  Future<File> _createImageWithTexts({
    required String imageUrl,
    required String topText,
    required String watermarkText,
  }) async {
    final response = await http.get(Uri.parse(imageUrl));
    final bytes = response.bodyBytes;

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final originalImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(originalImage, Offset.zero, Paint());

    final width = originalImage.width.toDouble();
    final height = originalImage.height.toDouble();

    // Banner superior
    final bannerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black.withOpacity(0.75), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, width, height * 0.18));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height * 0.18), bannerPaint);

    final titlePainter = TextPainter(
      text: TextSpan(
        text: '🐾 ${topText.toUpperCase()}',
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.07,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: width * 0.9);
    titlePainter.paint(canvas, Offset((width - titlePainter.width) / 2, height * 0.06));

    // Watermark
    final badgePainter = TextPainter(
      text: TextSpan(
        text: watermarkText,
        style: TextStyle(color: Colors.white, fontSize: width * 0.04),
      ),
      textDirection: TextDirection.ltr,
    );
    badgePainter.layout();
    badgePainter.paint(
      canvas,
      Offset(width - badgePainter.width - 24, height - badgePainter.height - 24),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(originalImage.width, originalImage.height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    final file = File('${(await getTemporaryDirectory()).path}/shared_${widget.post.id}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    return file;
  }

  Future<void> _shareToFacebookFeed() async {
    if (widget.post.imageUrls.isEmpty) return;

    final file = await _createImageWithTexts(
      imageUrl: widget.post.imageUrls.first,
      topText: widget.post.postType.name,
      watermarkText: '🐾 WeBaNiMaL',
    );

    await Share.shareXFiles([XFile(file.path)], text: '🐾 @WeBaNiMaL');
  }

  // ================= POPUP IMAGEN =================
void _openImagePopup(BuildContext context, int initialIndex) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.9),
    builder: (context) {
      double dragOffset = 0;

      return StatefulBuilder(
        builder: (context, setState) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                /// Fondo
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(color: Colors.transparent),
                  ),
                ),

                /// Contenido con swipe
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      dragOffset += details.delta.dy;
                    });
                  },
                  onVerticalDragEnd: (details) {
                    if (dragOffset > 150) {
                      Navigator.pop(context); // 👈 cerrar
                    } else {
                      setState(() {
                        dragOffset = 0; // vuelve a posición original
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(0, dragOffset, 0),
                    child: Center(
                      child: Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(12),
                        child: PageView.builder(
                          controller:
                              PageController(initialPage: initialIndex),
                          itemCount: widget.post.imageUrls.length,
                          itemBuilder: (context, index) {
                            final imageUrl =
                                widget.post.imageUrls[index];

                            return InteractiveViewer(
                              minScale: 1,
                              maxScale: 3,
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(16),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


Widget _buildHeader(Color color, IconData icon) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundImage:
              widget.post.user.imageUrl != null ? NetworkImage(widget.post.user.imageUrl!) : null,
          child: widget.post.user.imageUrl == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
       Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: () {
          context.push('/user-posts/${widget.post.user.id}');
        },
        child: Text(
          widget.post.user.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Text(
        '${_getTimeAgo()} - ${widget.post.location.label}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    ],
  ),
),

        // BOTÓN DE EDICIÓN
        if (widget.onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: widget.onEdit,
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
              Text(widget.post.postType.name,
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ),
      ],
    ),
  );
}

  // ================= BUILD =================
@override
Widget build(BuildContext context) {
  // 🔹 Manejo seguro de color
  final rawColor = widget.post.postType.color;
  final color = (rawColor is int)
      ? Color(rawColor as int)
      : Color(int.tryParse((rawColor ?? '0xFFCCCCCC').replaceAll('#', '0xFF')) ?? 0xFFCCCCCC);

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
    case '0xe3af':
      return Icons.image;
    default:
      return Icons.pets;
  }
}
final rawIcon = widget.post.postType.icon;
final iconData = _mapIcon(rawIcon);

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
            color: Colors.pink.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(color, iconData),
         if (widget.post.imageUrls.isNotEmpty)
  SizedBox(
    height: 350,
    child: Stack(
      children: [
        /// ================= PAGEVIEW =================
        PageView.builder(
          itemCount: widget.post.imageUrls.length,
          onPageChanged: (i) {
            setState(() => _currentImageIndex = i);
          },
          itemBuilder: (context, index) {
            final imageUrl = widget.post.imageUrls[index];

            return GestureDetector(
              onTap: () => _openImagePopup(context, index),
              onDoubleTap: _toggleLike,
              child: Hero(
                tag: '${widget.post.id}_$index',
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            );
          },
        ),

       

        /// ================= CONTADOR =================
        if (widget.post.imageUrls.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${_currentImageIndex + 1} / ${widget.post.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),

        /// ================= DOTS =================
        if (widget.post.imageUrls.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.post.imageUrls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentImageIndex ? 8 : 6,
                  height: i == _currentImageIndex ? 8 : 6,
                  decoration: BoxDecoration(
                    color: i == _currentImageIndex
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


          _buildActions(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(widget.post.description),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}


  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : null),
            onPressed: _toggleLike,
          ),
          Text('${widget.post.likes + likesIncrement}'),
          const SizedBox(width: 20),
          const Icon(Icons.chat_bubble_outline),
          const SizedBox(width: 4),
          Text('${widget.post.comments}'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF1877F2)),
            onPressed: _shareToFacebookFeed,
          ),
        ],
      ),
    );
  }
}
