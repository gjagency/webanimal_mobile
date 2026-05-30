import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/widgets/avatar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/utils/share_post_helper.dart';

import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
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

  HapticFeedback.lightImpact();

  setState(() {
    liked = !liked;
    likesIncrement += liked ? 1 : -1;
  });

  try {
    await PostsService.addReaction(
      int.parse(widget.post.id),
      1,
    );
  } catch (e) {

    if (!mounted) return;

    setState(() {
      liked = !liked;
      likesIncrement += liked ? 1 : -1;
    });
  }
}

  // ================= SHARE =================
  Future<File> _createImageWithTexts({
    required String imageUrl,
    required String topText,
    required String watermarkText,
  }) async {
    final response = await http.get(Uri.parse(imageUrl));
    final bytes = response.bodyBytes;

    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1080);
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
    titlePainter.paint(
      canvas,
      Offset((width - titlePainter.width) / 2, height * 0.06),
    );

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
      Offset(
        width - badgePainter.width - 24,
        height - badgePainter.height - 24,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      originalImage.width,
      originalImage.height,
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    final file = File(
      '${(await getTemporaryDirectory()).path}/shared_${widget.post.id}.png',
    );
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    return file;
  }

  Future<void> _shareToFacebookFeed() async {
    if (widget.post.medias.isEmpty) return;

    final media = widget.post.medias.first;

    try {
      /// MOSTRAR loader instantáneo
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      /// =========================
      /// VIDEO
      /// =========================
      if (media.isVideo) {
        final dir = await getTemporaryDirectory();

        final filePath = '${dir.path}/video_${widget.post.id}.mp4';

        final file = File(filePath);

        /// SOLO descarga si no existe
        if (!await file.exists()) {
          final request = await HttpClient().getUrl(Uri.parse(media.url));

          final response = await request.close();

          await response.pipe(file.openWrite());
        }

        if (context.mounted) Navigator.pop(context);

        await Share.shareXFiles([XFile(file.path)], text: '🐾 @WeBaNiMaL');

        return;
      }

      /// =========================
      /// IMAGEN
      /// =========================
      final file = await SharePostHelper.createImageWithTexts(
        imageUrl: media.url,
        topText: widget.post.postType.name,
        watermarkText: '🐾 WeBaNiMaL',
        fileName: 'shared_${widget.post.id}',
      );

      if (context.mounted) Navigator.pop(context);

      await Share.shareXFiles([XFile(file.path)], text: '🐾 @WeBaNiMaL');
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      debugPrint('ERROR SHARE: $e');
    }
  }

  // ================= POPUP IMAGEN =================
void _openImagePopup(BuildContext context, int initialIndex) {
    FeedVideoPlayer.pauseAll();
  final pageController = PageController(
    initialPage: initialIndex,
  );

  int currentIndex = initialIndex;

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.95),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Material(
            color: Colors.black,
            child: SafeArea(
              child: Stack(
                children: [

                  /// SLIDER
                  Positioned.fill(
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: widget.post.medias.length,

                      onPageChanged: (i) {
                        setModalState(() {
                          currentIndex = i;
                        });
                      },

                      itemBuilder: (_, index) {
                        final media = widget.post.medias[index];

                        /// VIDEO
                        if (media.isVideo) {
                          return FeedVideoPlayer(
                            url: media.url,
                            autoplay: true,
                          );
                        }

                        /// IMAGEN
                        return InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                            child: CachedNetworkImage(
                              imageUrl: media.url,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,

                              memCacheWidth: 1600,
                              maxWidthDiskCache: 1600,

                              placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),

                              errorWidget: (_, __, ___) =>
                                  const Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  /// LOGO TOP CENTER
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.purple,
                                  Colors.pink,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.asset(
                              "assets/logo6.png",
                              width: 18,
                              height: 18,
                            ),
                          ),

                          const SizedBox(width: 8),

                          const Text(
                            "WeBaNiMaL",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// CLOSE
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  /// CONTADOR
                  if (widget.post.medias.length > 1)
                    Positioned(
                      top: 60,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${widget.post.medias.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  /// INFO
                  Positioned(
                    left: 16,
                    right: 90,
                    bottom: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// USER
                        Row(
                          children: [
                            CustomAvatar(
                              url: widget.post.user.imageUrl ??
                                  'https://i.pravatar.cc/300',
                            ),

                            const SizedBox(width: 10),

                            GestureDetector(
                              onTap: () {
                                FeedVideoPlayer.pauseAll();

                                Navigator.pop(context);

                                Future.microtask(() {
                                  if (mounted) {
                                    context.push('/user-posts/${widget.post.user.id}');
                                  }
                                });
                              },

                              child: Text(
                                widget.post.user.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                                                      ],
                                                    ),

                                                    const SizedBox(height: 12),

                                                Text(
                              widget.post.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                                                  

                            const SizedBox(height: 14),

                        /// VER POST
                        GestureDetector(
                          onTap: () {
                            FeedVideoPlayer.pauseAll();

                            Navigator.pop(context);

                            Future.microtask(() {
                              if (mounted) {
                                GoRouter.of(context).push(
                                  '/posts/${widget.post.id}/view',
                                );
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white24,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.link,
                                  color: Colors.white,
                                  size: 18,
                                ),

                                SizedBox(width: 8),

                                Text(
                                  'Ver publicación',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  /// ACTIONS INSTAGRAM STYLE
Positioned(
  right: 20,
  bottom: 120,
  child: Column(
    children: [

      /// LIKE
      GestureDetector(
        onTap: () {
          _toggleLike();
          setModalState(() {});
        },

        child: Column(
          children: [
            Icon(
              liked
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: liked
                  ? Colors.red
                  : Colors.white,
              size: 32,
            ),

            const SizedBox(height: 4),

            Text(
              '${widget.post.likes + likesIncrement}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 26),

      /// COMMENTS
      GestureDetector(
        onTap: () {
          FeedVideoPlayer.pauseAll();

          Navigator.pop(context);

          Future.microtask(() {
            if (mounted) {
              GoRouter.of(context).push(
                '/posts/${widget.post.id}/view',
              );
            }
          });
        },

        child: Column(
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 30,
            ),

            const SizedBox(height: 4),

            Text(
              '${widget.post.comments}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 26),

      /// SHARE
      GestureDetector(
        onTap: _shareToFacebookFeed,

        child: Column(
          children: const [
            Icon(
              Icons.share,
              color: Colors.white,
              size: 30,
            ),

            SizedBox(height: 4),

            Text(
              'Compartir',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
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
GestureDetector(
  onTap: () {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "avatar",
      barrierColor: Colors.black.withOpacity(0.92),
      transitionDuration: const Duration(milliseconds: 250),

      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Stack(
            children: [
            

              /// IMAGEN
              Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        widget.post.user.imageUrl ??
                            'https://i.pravatar.cc/300',
                        fit: BoxFit.cover,

                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white,
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

      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  },

  child: CustomAvatar(
    url: widget.post.user.imageUrl ??
        'https://i.pravatar.cc/300',
  ),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${_getTimeAgo()} - ${widget.post.location.label}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
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
        : Color(
            int.tryParse((rawColor ?? '0xFFCCCCCC').replaceAll('#', '0xFF')) ??
                0xFFCCCCCC,
          );

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
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(color, iconData),

            /// DESCRIPCION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(widget.post.description),
            ),

            /// TELEFONO
            if (widget.post.telefono != null &&
                widget.post.telefono!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.green),
                    const SizedBox(width: 6),

                    Text(
                      widget.post.telefono!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            if (widget.post.medias.isNotEmpty)
            AutoAdaptiveMediaSlider(
                medias: widget.post.medias,
                postId: widget.post.id,
                currentIndex: _currentImageIndex,
                description: widget.post.description,

                onPageChanged: (i) {
                  setState(() {
                    _currentImageIndex = i;
                  });
                },

                onImageTap: (index) {
                  _openImagePopup(context, index);
                },

                onDoubleTap: _toggleLike,

                liked: liked,
                likes: widget.post.likes + likesIncrement,
                comments: widget.post.comments,

                onLike: _toggleLike,

                userName: widget.post.user.displayName,

                userAvatar:
                    widget.post.user.imageUrl ??
                    'https://i.pravatar.cc/300',

                userId: widget.post.user.id,
              ),
            _buildActions(),
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
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? Colors.red : null,
            ),
            onPressed: _toggleLike,
          ),
          Text('${widget.post.likes + likesIncrement}'),
          const SizedBox(width: 20),
          GestureDetector(
  child: Row(
    children: [
      const Icon(Icons.chat_bubble_outline),
    ],
  ),
),
          const SizedBox(width: 4),
          Text('${widget.post.comments}'),
          const Spacer(),
          IconButton(
            onPressed: () async {
              await _shareToFacebookFeed();
            },
            icon: const Icon(
              Icons.share_outlined,
              color: Color(0xFF1877F2),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class AutoAdaptiveMediaSlider extends StatefulWidget {
  final String description;
  final List<dynamic> medias;
  final String postId;

  final String userName;
  final String userAvatar;

  final int currentIndex;

  final Function(int) onPageChanged;
  final Function(int) onImageTap;

  final VoidCallback onDoubleTap;

  final bool liked;
  final int likes;
  final int comments;
  final String userId;
  final VoidCallback onLike;

  const AutoAdaptiveMediaSlider({
    super.key,
    required this.description,
    required this.medias,
    required this.postId,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onImageTap,
    required this.onDoubleTap,
    required this.liked,
    required this.likes,
    required this.comments,
    required this.onLike,
    required this.userName,
    required this.userAvatar,
    required this.userId,
  });

  @override
  State<AutoAdaptiveMediaSlider> createState() =>
      _AutoAdaptiveMediaSliderState();
}

class _AutoAdaptiveMediaSliderState
    extends State<AutoAdaptiveMediaSlider> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            allowImplicitScrolling: false,
            padEnds: false,
            pageSnapping: true,
            itemCount: widget.medias.length,

            onPageChanged: widget.onPageChanged,

            itemBuilder: (context, index) {
              final media = widget.medias[index];

              /// ================= VIDEO =================
              if (media.isVideo) {
                return GestureDetector(
                  onTap: () async {
                    /// PAUSAR TODOS LOS VIDEOS DEL FEED
                    FeedVideoPlayer.pauseAll();
                    FeedVideoPlayer.fullscreenOpen = true;

                    await Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) =>
                            FullScreenVideoPage(
                          videoUrl: media.url,

                          liked: widget.liked,
                          likes: widget.likes,
                          comments: widget.comments,

                          userName: widget.userName,
                          userAvatar: widget.userAvatar,
                          userId: widget.userId,
                          description: widget.description,

                          onLike: widget.onLike,

                          onOpenPost: () {
                            GoRouter.of(context).push(
                              '/posts/${widget.postId}/view',
                            );
                          },
                        ),
                      ),
                    );
                  },

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FeedVideoPlayer(
                          url: media.url,
                          autoplay: false,
                        ),

                        Container(
                          color: Colors.black.withOpacity(0.12),
                        ),

                        const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              /// ================= IMAGEN =================
              return GestureDetector(
                onTap: () {
                  widget.onImageTap(index);
                },

                onDoubleTap: widget.onDoubleTap,

                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),

                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,

                      child: CachedNetworkImage(
                        imageUrl: media.url,
                        fit: BoxFit.cover,

                        width: double.infinity,
                        height: double.infinity,

                        memCacheWidth: 1200,
                        maxWidthDiskCache: 1200,

                        fadeInDuration:
                            const Duration(milliseconds: 120),

                        fadeOutDuration: Duration.zero,

                        placeholder: (_, __) => Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),

                        errorWidget: (_, __, ___) =>
                            const Icon(
                          Icons.broken_image,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          /// CONTADOR
          if (widget.medias.length > 1)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Text(
                  '${widget.currentIndex + 1} / ${widget.medias.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// =======================================================
/// FEED VIDEO PLAYER
/// =======================================================

class FeedVideoPlayer extends StatefulWidget {
  final String url;

  final bool autoplay;

  final VoidCallback? onPause;
  final VoidCallback? onPlay;

  const FeedVideoPlayer({
    super.key,
    required this.url,
    this.autoplay = true,
    this.onPause,
    this.onPlay,
  });

  /// TODOS LOS VIDEOS ACTIVOS
  static final List<FeedVideoPlayerState> _instances = [];
    static bool fullscreenOpen = false;
  /// PAUSAR TODOS
static void pauseAll([FeedVideoPlayerState? except]) {
  for (final instance in _instances) {
    if (instance != except) {
      instance.pauseVideo();
    }
  }
}
  @override
  State<FeedVideoPlayer> createState() =>
      FeedVideoPlayerState();
}

class FeedVideoPlayerState
    extends State<FeedVideoPlayer> {
  VideoPlayerController? _controller;

  bool _initialized = false;

  bool _isVisible = false;

  bool _muted = true;

  bool _disposed = false;

  bool _showPlayIcon = false;
    bool _initializing = false;


  @override
  void initState() {
    super.initState();

    FeedVideoPlayer._instances.add(this);
  }

Future<void> _initialize() async {

  if (_controller != null ||
      _disposed ||
      _initializing) {
    return;
  }

  _initializing = true;

  try {

    debugPrint("🎥 INIT VIDEO ${widget.url}");

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    );

    await controller.initialize();

    // 👇 AGREGAR ACÁ
    debugPrint(
      "VIDEO SIZE: "
      "${controller.value.size.width}x"
      "${controller.value.size.height}"
    );

    debugPrint(
      "ASPECT: ${controller.value.aspectRatio}"
    );

    if (_disposed) {
      await controller.dispose();
      return;
    }

    await controller.setLooping(true);
    await controller.setVolume(0);

    _controller = controller;

    if (!mounted) return;

    setState(() {
      _initialized = true;
    });

  } catch (e) {
    debugPrint("VIDEO INIT ERROR: $e");
  } finally {
    _initializing = false;
  }
}
Future<void> playVideo() async {
  final c = _controller;

  if (c == null) return;

  FeedVideoPlayer.pauseAll(this);

  await c.play();

  if (mounted) {
    
    setState(() {
      _showPlayIcon = false;
    });
  }
}


  Future<void> pauseVideo() async {
      debugPrint("⏸️ PAUSE ${widget.url}");

    final c = _controller;

    if (c == null) return;

    await c.pause();

    if (mounted) {
      setState(() {
        _showPlayIcon = true;
      });
    }
  }

  void _onVisibilityChanged(
    VisibilityInfo info,
  ) async {
      debugPrint(
    "👀 VISIBILITY ${widget.url} "
    "fraction=${info.visibleFraction}"
  );
    final visible = info.visibleFraction > 0.40;

    _isVisible = visible;

    if (!visible) {
      await pauseVideo();
      return;
    }

    if (_controller == null) {
        debugPrint("▶️ PLAY ${widget.url}");
     
      await _initialize();
    }

   if (FeedVideoPlayer.fullscreenOpen) {
    await pauseVideo();
      return;
    }

    if (widget.autoplay) {
      await playVideo();
    } else {
      await pauseVideo();
    }
  }

  Future<void> _togglePlayPause() async {
    final c = _controller;

    if (c == null) return;

    if (c.value.isPlaying) {
      await pauseVideo();
    } else {
      await playVideo();
    }
  }

  Future<void> _toggleMute() async {
    final c = _controller;

    if (c == null) return;

    _muted = !_muted;

    await c.setVolume(_muted ? 0 : 1);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
debugPrint("🗑️ DISPOSE VIDEO ${widget.url}");
  debugPrint(
    "🗑️ CONTROLLER EXISTS "
    "${_controller != null}"
  );

    _disposed = true;

    FeedVideoPlayer._instances.remove(this);

    final controller = _controller;

    _controller = null;

    controller?.pause();

    controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      debugPrint(
    "🏗️ BUILD VIDEO "
    "initialized=$_initialized "
    "controller=${_controller != null}"
  );
    final c = _controller;

    return VisibilityDetector(
      key: Key(widget.url),

      onVisibilityChanged: _onVisibilityChanged,

      child: Container(
        color: Colors.black,

        child: !_initialized || c == null
            ? Container(
                color: Colors.black,

                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                 AspectRatio(
  aspectRatio: c.value.aspectRatio,
  child: VideoPlayer(c),
),

                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),

                  AnimatedOpacity(
                    duration:
                        const Duration(milliseconds: 180),

                    opacity: _showPlayIcon ? 1 : 0,

                    child: const IgnorePointer(
                      child: Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 70,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 12,
                    bottom: 12,

                    child: GestureDetector(
                      onTap: _toggleMute,

                      child: Container(
                        padding: const EdgeInsets.all(8),

                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),

                        child: Icon(
                          _muted
                              ? Icons.volume_off
                              : Icons.volume_up,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
class FullScreenVideoPage extends StatefulWidget {
  final String videoUrl;

  final bool liked;
  final int likes;
  final int comments;
  final String userName;
  final String userAvatar;
  final String description;
  final VoidCallback onLike;
  final VoidCallback onOpenPost;
  final String userId;
  const FullScreenVideoPage({
    super.key,
    required this.videoUrl,
    required this.liked,
    required this.likes,
    required this.comments,
    required this.userName,
    required this.userAvatar,
    required this.description,
    required this.onLike,
    required this.userId,
    required this.onOpenPost,

  });

  @override
  State<FullScreenVideoPage> createState() =>
      _FullScreenVideoPageState();
}

class _FullScreenVideoPageState
    extends State<FullScreenVideoPage> {

   late VideoPlayerController _controller;

  bool _initialized = false;
  bool _muted = false;

  bool _showPlayIcon = false;

  bool localLiked = false;
  int localLikes = 0;

  @override
  void initState() {
    super.initState();

    localLiked = widget.liked;
    localLikes = widget.likes;

    _initialize();
  }
void _handleLike() {
  HapticFeedback.lightImpact();

  setState(() {
    localLiked = !localLiked;
    localLikes += localLiked ? 1 : -1;
  });

  widget.onLike();
}
Future<void> _shareVideo() async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final dir = await getTemporaryDirectory();

    final filePath =
        '${dir.path}/fullscreen_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final file = File(filePath);

    if (!await file.exists()) {
      final request = await HttpClient().getUrl(
        Uri.parse(widget.videoUrl),
      );

      final response = await request.close();

      await response.pipe(file.openWrite());
    }

    if (mounted) Navigator.pop(context);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '🐾 @WeBaNiMaL',
    );
  } catch (e) {
    if (mounted) Navigator.pop(context);

    debugPrint('ERROR SHARE VIDEO: $e');
  }
}
  Future<void> _initialize() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    );

    await _controller.initialize();

    await _controller.setLooping(true);
    await _controller.play();

    if (!mounted) return;

    setState(() {
      _initialized = true;
    });
  }
Future<void> _togglePlayPause() async {
  final c = _controller;

  if (c == null) return;

  if (c.value.isPlaying) {
    await c.pause();

    if (mounted) {
      setState(() {
        _showPlayIcon = true;
      });
    }
  } else {
    await c.play();

    if (mounted) {
      setState(() {
        _showPlayIcon = false;
      });
    }
  }
}
  Future<void> _toggleMute() async {
    _muted = !_muted;

    await _controller.setVolume(_muted ? 0 : 1);

    setState(() {});
  }

@override
void dispose() {

  FeedVideoPlayer.fullscreenOpen = false;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    FeedVideoPlayer.pauseAll();
  });

  _controller.dispose();

  super.dispose();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: GestureDetector(
      onVerticalDragEnd: (_) async {
  await _controller.pause();

  if (mounted) {
    Navigator.pop(context);
  }
},

        child: Stack(
          fit: StackFit.expand,
          children: [

            /// VIDEO
            if (_initialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(),
              ),

            /// TAP PLAY
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(color: Colors.transparent),
              ),
            ),

            /// PLAY ICON
            if (_initialized)
         AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showPlayIcon ? 1 : 0,
                child: const IgnorePointer(
                  child: Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 90,
                    ),
                  ),
                ),
              ),

/// LOGO TOP CENTER
Positioned(
  top: 50,
  left: 0,
  right: 0,
  child: IgnorePointer(
    child: Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Colors.purple,
                  Colors.pink,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/logo6.png",
              width: 18,
              height: 18,
            ),
          ),

          const SizedBox(width: 8),

          const Text(
            "WeBaNiMaL",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    ),
  ),
),


/// INFO BOTTOM
Positioned(
  left: 16,
  right: 90,
  bottom: 90,

  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      /// USER
      Row(
        children: [
          CustomAvatar(
            url: widget.userAvatar,
          ),

          const SizedBox(width: 10),

        GestureDetector(
      onTap: () async {
        await _controller.pause();

        if (!mounted) return;

        context.push('/user-posts/${widget.userId}');
      },
  child: Text(
    widget.userName,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  ),
),
        ],
      ),

      const SizedBox(height: 12),

      /// DESCRIPCION
      if (widget.description.isNotEmpty)
        Text(
          widget.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.3,
          ),
        ),

      const SizedBox(height: 12),

      /// VER POST
      GestureDetector(
        onTap: () async {
  await _controller.pause();

  if (!mounted) return;

  widget.onOpenPost();
},

        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),

          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white24,
            ),
          ),

          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link,
                color: Colors.white,
                size: 18,
              ),

              SizedBox(width: 8),

              Text(
                'Ver publicación',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),

/// CLOSE
Positioned(
  top: 50,
  left: 20,
              child: GestureDetector(
                onTap: () async {
                await _controller.pause();
                
                if (mounted) {
                  Navigator.pop(context);
                }
              },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            /// MUTE
            Positioned(
              bottom: 40,
              right: 20,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _muted
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
/// ACTIONS INSTAGRAM STYLE
Positioned(
  right: 20,
  bottom: 120,
  child: Column(
    children: [

      /// LIKE
      GestureDetector(
        onTap: _handleLike,

        child: Column(
          children: [
            Icon(
              localLiked
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: localLiked
                  ? Colors.red
                  : Colors.white,
              size: 32,
            ),

            const SizedBox(height: 4),

            Text(
              '$localLikes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 26),

      /// COMMENTS
      GestureDetector(
        onTap: () async {
          await _controller.pause();

          if (!mounted) return;

          widget.onOpenPost();
        },

        child: Column(
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 30,
            ),

            const SizedBox(height: 4),

            Text(
              '${widget.comments}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 26),

      /// SHARE
      GestureDetector(
        onTap: _shareVideo,

        child: Column(
          children: const [
            Icon(
              Icons.share,
              color: Colors.white,
              size: 30,
            ),

            SizedBox(height: 4),

            Text(
              'Compartir',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
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
      ),
    );
  }
}