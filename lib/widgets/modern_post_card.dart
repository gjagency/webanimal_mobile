import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/utils/share_post_helper.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

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

  if (!mounted) return;

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

    await SharePostHelper.sharePost(
      imageUrl: widget.post.medias.first.url,
      postType: widget.post.postType.name,
      fileName: 'shared_${widget.post.id}',
    );
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
                    if (!mounted) return;

                    setState(() {
                      dragOffset += details.delta.dy;
                    });
                  },
                                      onVerticalDragEnd: (details) {
                    if (dragOffset > 150) {
                      Navigator.pop(context);
                    } else {
                      if (!mounted) return;

                      setState(() {
                        dragOffset = 0;
                      });
                    }
                  },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.translationValues(0, dragOffset, 0),
                      child: Center(
                        child: Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 40,
                          ),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: PageView.builder(
                              controller: PageController(
                                initialPage: initialIndex,
                              ),
                              itemCount: widget.post.medias.length,
                              itemBuilder: (context, index) {
                                final imageUrl = widget.post.medias[index];

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: InteractiveViewer(
                                      minScale: 1,
                                      maxScale: 4,
                                      child: imageUrl.isVideo
                                      ? FeedVideoPlayer(url: imageUrl.url)
                                      : Image.network(
                                          imageUrl.url,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                    ),
                                  ),
                                );
                              },
                            ),
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
            backgroundColor: Colors.grey.shade200,
            child: ClipOval(
              child:
                  widget.post.user.imageUrl != null &&
                      widget.post.user.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.post.user.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person);
                      },
                    )
                  : const Icon(Icons.person),
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
                    const Icon(
                      Icons.phone,
                      size: 16,
                      color: Colors.green,
                    ),
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
                    onPageChanged: (i) {
                      setState(() => _currentImageIndex = i);
                    },
                    onImageTap: (index) => _openImagePopup(context, index),
                    onDoubleTap: _toggleLike,
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
          const Icon(Icons.chat_bubble_outline),
          const SizedBox(width: 4),
          Text('${widget.post.comments}'),
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
    );
  }
  
}
class FeedVideoPlayer extends StatefulWidget {
  final String url;

  const FeedVideoPlayer({
    super.key,
    required this.url,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}
class _FeedVideoPlayerState extends State<FeedVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  late VideoPlayerController controller;

  bool _disposed = false;
  bool _isMuted = true;
  bool _isPaused = false;
  int _loopCount = 0;
  bool _wasNearEnd = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await controller.initialize();

    if (!mounted || _disposed) return;

    await controller.setVolume(0);
    await controller.setLooping(true);
    await controller.play();

    controller.addListener(_videoListener);

    if (!mounted || _disposed) return;
    setState(() {});
  }

  @override
  void dispose() {
    _disposed = true;

    controller.removeListener(_videoListener);
    controller.pause();
    controller.dispose();

    super.dispose();
  }
Future<void> _toggleMute() async {

if (!mounted || _disposed) return;

  setState(() {
    _isMuted = !_isMuted;
  });

  await controller.setVolume(_isMuted ? 0 : 1);
}

Future<void> _togglePlayPause() async {
  if (_disposed) return;

  if (controller.value.isPlaying) {
    await controller.pause();

    if (!mounted || _disposed) return;

    setState(() {
      _isPaused = true;
    });
  } else {
    await controller.play();

    if (!mounted || _disposed) return;

    setState(() {
      _isPaused = false;
    });
  }
}
void _handleVisibilityChanged(VisibilityInfo info) async {
  if (_disposed) return;
  if (!controller.value.isInitialized) return;

  if (info.visibleFraction < 0.3) {
    if (controller.value.isPlaying) {
      await controller.pause();

      if (!mounted || _disposed) return;

      setState(() {
        _isPaused = true;
      });
    }
  } else {
    if (!controller.value.isPlaying) {
      await controller.play();

      if (!mounted || _disposed) return;

      setState(() {
        _isPaused = false;
      });
    }
  }
}
void _videoListener() {
  if (_disposed) return;
  if (!controller.value.isInitialized) return;

  final position = controller.value.position;
  final duration = controller.value.duration;

  if (duration.inMilliseconds == 0) return;

  final remaining =
      duration.inMilliseconds - position.inMilliseconds;

  /// está terminando
  if (remaining < 300 && !_wasNearEnd) {
    _wasNearEnd = true;
  }

  /// volvió a empezar
  if (_wasNearEnd && position.inMilliseconds < 300) {
    _loopCount++;
    _wasNearEnd = false;

    if (_loopCount >= 3) {
      controller.pause();

      if (!mounted || _disposed) return;

      setState(() {
        _isPaused = true;
      });
    }
  }
}
  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return VisibilityDetector(
      key: Key(widget.url),
      onVisibilityChanged: _handleVisibilityChanged,
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          children: [
            /// VIDEO
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),

            /// ICONO PLAY
            if (_isPaused)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 70,
                ),
              ),

            /// BOTON MUTE
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: Colors.white,
                    size: 22,
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

class AutoAdaptiveMediaSlider extends StatefulWidget {
  final List<dynamic> medias;
  final String postId;
  final int currentIndex;
  final Function(int) onPageChanged;
  final Function(int) onImageTap;
  final VoidCallback onDoubleTap;

  const AutoAdaptiveMediaSlider({
    super.key,
    required this.medias,
    required this.postId,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onImageTap,
    required this.onDoubleTap,
  });

  @override
  State<AutoAdaptiveMediaSlider> createState() =>
      _AutoAdaptiveMediaSliderState();
}

class _AutoAdaptiveMediaSliderState extends State<AutoAdaptiveMediaSlider> {
  double aspectRatio = 1;

  void _updateAspectRatio(String url) {
    final image = Image.network(url);

    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (!mounted) return;

        setState(() {
          aspectRatio = info.image.width / info.image.height;
        });
      }),
    );
  }

  @override
  void initState() {
    super.initState();

    final firstMedia = widget.medias.first;
    if (!firstMedia.isVideo) {
      _updateAspectRatio(firstMedia.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.medias.length,
            onPageChanged: (i) {
              widget.onPageChanged(i);

              final media = widget.medias[i];
              if (!media.isVideo) {
                _updateAspectRatio(media.url);
              }
            },
            itemBuilder: (context, index) {
              final media = widget.medias[index];

              return GestureDetector(
                onTap: () => widget.onImageTap(index),
                onDoubleTap: widget.onDoubleTap,
                child: Hero(
                  tag: '${widget.postId}_$index',
                  child: media.isVideo
                      ? FeedVideoPlayer(url: media.url)
                      : Container(
                          color: Colors.white,
                          child: Image.network(
                            media.url,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
              );
            },
          ),

          if (widget.medias.length > 1)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
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