import 'dart:io';
import 'dart:typed_data';
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

  const ModernPostCard({super.key, required this.post});

  @override
  State<ModernPostCard> createState() => _ModernPostCardState();
}

class _ModernPostCardState extends State<ModernPostCard> {
  static const _channel = MethodChannel('share_to_facebook');

  bool liked = false;
  int likesIncrement = 0;

  @override
  void initState() {
    super.initState();
    liked = widget.post.reacciones.isNotEmpty;
  }

  String _getTimeAgo() {
    final diff = DateTime.now().difference(widget.post.datetime);
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inMinutes}m';
  }

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

    // ===== BANNER SUPERIOR =====
    final bannerHeight = height * 0.18;
    final bannerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.75),
          Colors.black.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, bannerHeight));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, bannerHeight), bannerPaint);

    final topPainter = TextPainter(
      text: TextSpan(
        text: '🐾 ${topText.toUpperCase()}',
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.07,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          shadows: const [
            Shadow(color: Color.fromARGB(255, 59, 55, 55), blurRadius: 10),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    topPainter.layout(maxWidth: width * 0.9);
    topPainter.paint(canvas, Offset((width - topPainter.width) / 2, height * 0.06));

    // ===== WATERMARK =====
    final badgePadding = width * 0.025;
    final badgeTextPainter = TextPainter(
      text: TextSpan(
        text: watermarkText,
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.04,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    badgeTextPainter.layout();
    final badgeRect = Rect.fromLTWH(
      width - badgeTextPainter.width - badgePadding * 2 - width * 0.04,
      height - badgeTextPainter.height - badgePadding * 2 - width * 0.04,
      badgeTextPainter.width + badgePadding * 2,
      badgeTextPainter.height + badgePadding * 2,
    );
    final badgePaint = Paint()..color = Colors.black.withOpacity(0.65);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, Radius.circular(20)), badgePaint);
    badgeTextPainter.paint(canvas, Offset(badgeRect.left + badgePadding, badgeRect.top + badgePadding));

    final picture = recorder.endRecording();
    final img = await picture.toImage(originalImage.width, originalImage.height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${(await getTemporaryDirectory()).path}/shared_${widget.post.id}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    return file;
  }

  Future<void> _toggleLike() async {
    await PostsService.addReaction(int.parse(widget.post.id), 1);
    setState(() {
      liked = !liked;
      likesIncrement += liked ? 1 : -1;
    });
  }

  Future<void> _shareToFacebookFeed() async {
    if (widget.post.imageUrl == null) return;
    final file = await _createImageWithTexts(
      imageUrl: widget.post.imageUrl!,
      topText: widget.post.postType.name,
      watermarkText: ' 🐾 WeBaNiMaL',
    );
    await Share.shareXFiles([XFile(file.path)], text: '🐾 @WeBaNiMaL');
  }

  void _openImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Hero(
                tag: widget.post.id,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                        height: 200,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.white, size: 60),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: widget.post.user.imageUrl != null ? NetworkImage(widget.post.user.imageUrl!) : null,
                    backgroundColor: Colors.grey[300],
                    child: widget.post.user.imageUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.post.user.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${_getTimeAgo()} - ${widget.post.location.label}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withOpacity(0.75), color]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(widget.post.postType.name,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================= IMAGEN =================
            if (widget.post.imageUrl != null)
              GestureDetector(
                onTap: () => _openImagePopup(context, widget.post.imageUrl!),
                child: Hero(
                  tag: widget.post.id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 400, // altura máxima de la imagen
                        minWidth: double.infinity,
                      ),
                      child: Image.network(
                        widget.post.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

            // ================= ACCIONES =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Icon(liked ? Icons.favorite : Icons.favorite_border,
                            color: liked ? Colors.red : null, size: 28),
                      ),
                      const SizedBox(width: 4),
                      Text('${widget.post.likes + likesIncrement}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 28),
                      const SizedBox(width: 4),
                      Text('${widget.post.comments}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 26, color: Color(0xFF1877F2)),
                    onPressed: _shareToFacebookFeed,
                  ),
                ],
              ),
            ),

            // ================= DESCRIPCIÓN =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.4),
                  children: [                   
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
