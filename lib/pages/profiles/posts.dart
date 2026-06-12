import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:mobile_app/service/reports_service.dart';
import 'package:mobile_app/utils/share_post_helper.dart';
import 'package:mobile_app/widgets/avatar.dart';
import 'package:mobile_app/widgets/report_popup.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class UserPostsPage extends StatefulWidget {
  final String userId;
  const UserPostsPage({super.key, required this.userId});

  @override
  State<UserPostsPage> createState() => _UserPostsPageState();
}

class _UserPostsPageState extends State<UserPostsPage> {
  List<Post> _posts = [];
  Map<String, dynamic>? _profile;
  List<PostMedia> _medias = [];
  bool _isSavingEdit = false;
  bool _loading = true;
  String? _error;
  String avatarUrl = '';
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.getProfile();

      setState(() {
        avatarUrl = profile['avatar'] ?? "";
        loadingProfile = false;
      });
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
      setState(() {
        loadingProfile = false;
      });
    }
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        PostsService.getPostsByUser(widget.userId),
        AuthService.getUserById(widget.userId),
      ]);

      _posts = results[0] as List<Post>;
      _profile = results[1] as Map<String, dynamic>?;

      /// PRECACHE SOLO PRIMERAS IMÁGENES
      for (final post in _posts.take(3)) {
        final media = post.medias.isNotEmpty ? post.medias.first : null;

        if (media != null && !media.isVideo) {
          precacheImage(
            ResizeImage(NetworkImage(media.url), width: 300),
            context,
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
        loadingProfile = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
        loadingProfile = false;
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

    final profileAvatarUrl = _profile?['avatar'];
    final bio = _profile?['bio'] ?? "";

    final bool isVet = _profile?['es_veterinaria'] == true;
    final String nombreComercial = _profile?['nombre_comercial'] ?? "";

    final String displayName =
        (_profile?['display_name'] ?? "").toString().isNotEmpty
        ? _profile!['display_name']
        : _profile?['username'] ?? "Perfil";

    final String nombreFinal = isVet && nombreComercial.isNotEmpty
        ? nombreComercial
        : displayName;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 8,

        title: Row(
          children: [
            /// LOGO
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.pink],
                ),
                borderRadius: BorderRadius.circular(12),
              ),

              child: Image.asset("assets/logo6.png", width: 22, height: 22),
            ),

            const SizedBox(width: 10),

            /// TITLE RESPONSIVE
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,

                child: const Text(
                  "WeBaNiMaL",
                  maxLines: 1,

                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),

        actions: [
          /// SEARCH
          IconButton(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),

            padding: EdgeInsets.zero,

            icon: const Icon(Icons.search),

            onPressed: () {
              context.push('/search/users');
            },
          ),

          /// PROFILE
          IconButton(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),

            padding: EdgeInsets.zero,

            onPressed: () {
              context.push('/user-posts/${AuthService.currentUserId}');
            },

            icon: CustomAvatar(url: avatarUrl),
          ),

          /// SETTINGS
          IconButton(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),

            padding: EdgeInsets.zero,

            icon: const Icon(Icons.settings),

            onPressed: () {
              context.push('/account/settings');
            },
          ),

          const SizedBox(width: 6),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// AVATAR
                        CustomAvatar(url: profileAvatarUrl, size: 60),

                        /// STATS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          spacing: 6,
                          children: [
                            _stat(
                              _profile?['posts_count']?.toString() ?? "0",
                              "Posteos",
                            ),
                            _stat(
                              _profile?['followers_count']?.toString() ?? "-",
                              "Seguidores",
                            ),
                            _stat(
                              _profile?['following_count']?.toString() ?? "-",
                              "Siguiendo",
                            ),
                          ],
                        ),

                        PopupMenuButton<String>(
                          padding: EdgeInsetsGeometry.all(0.0),
                          menuPadding: EdgeInsets.all(0.0),
                          icon: const Icon(Icons.more_vert, size: 14),
                          onSelected: (value) async {
                            if (value == "block") {
                              await ReportPopup.show(
                                context,
                                type: UserReportType.BLOQUEO_USUARIO,
                                id: widget.userId,
                                onSent: () => Navigator.pop(context),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'block',
                              child: Text('Bloquear usuario'),
                            ),
                          ],
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
                            fontSize: 14,
                          ),
                        ),
                        if (isVet) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 18,
                          ),
                        ],
                      ],
                    ),

                    /// BIO
                    if (bio.toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(bio, style: const TextStyle(fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),

            /// ================= GRID POSTS =================
            SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final post = _posts[index];

                final media = post.medias.isNotEmpty ? post.medias.first : null;

                return GestureDetector(
                  onTap: () => _openImageViewer(post, 0),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Hero(
                          tag: media != null
                              ? '${post.id}_${media.id}'
                              : '${post.id}_empty',

                          child: media == null
                              ? Container(color: Colors.grey.shade300)
                              : media.isVideo
                              ? ClipRRect(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      VideoThumbnailWidget(url: media.url),

                                      Container(color: Colors.black26),

                                      const Center(
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Image.network(
                                  media.url,
                                  fit: BoxFit.cover,

                                  cacheWidth: 250,

                                  filterQuality: FilterQuality.low,

                                  gaplessPlayback: true,

                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }

                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },

                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),

                      /// MULTIMEDIA
                      if (post.medias.length > 1)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${post.medias.length - 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      /// VIDEO
                      if (media?.isVideo == true)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.videocam,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }, childCount: _posts.length),

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Future<void> _editarPost(Post post) async {
    final formKey = GlobalKey<FormState>();
    String description = post.description;
    final ImagePicker picker = ImagePicker();

    _medias = List.from(post.medias);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.purple, Colors.pink],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Expanded(
                              child: Text(
                                'Editar Post',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        initialValue: description,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: '¿Qué querés compartir?',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Ingrese descripción'
                            : null,
                        onSaved: (v) => description = v ?? '',
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Imágenes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _medias.map((media) {
                          return Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: media.isVideo
                                  ? Container(
                                      color: Colors.black,
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : Image.network(media.url, fit: BoxFit.cover),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Cancelar', maxLines: 1),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSavingEdit
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate())
                                        return;

                                      formKey.currentState!.save();

                                      setState(() {
                                        _isSavingEdit = true;
                                      });

                                      try {
                                        await PostsService.updatePost(
                                          post.id,
                                          description: description,
                                          mediaIds: _medias
                                              .map((e) => e.id)
                                              .toList(),
                                        );

                                        if (!mounted) return;

                                        Navigator.pop(context);
                                        await _refresh();
                                      } catch (e) {
                                        debugPrint(e.toString());
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isSavingEdit = false;
                                          });
                                        }
                                      }
                                    },

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),

                              child: _isSavingEdit
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Guardar', maxLines: 1),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openImageViewer(Post post, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) {
          return _FullScreenViewer(
            post: post,
            initialIndex: initialIndex,
            onRefresh: _refresh,
            onEdit: _editarPost,
          );
        },
      ),
    );
  }

  Widget _imagePreview({
    required Widget image,
    required VoidCallback onDelete,
  }) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: image,
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? controller;

  bool initialized = false;
  bool paused = false;
  bool disposed = false;
  bool muted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      /// CONTROLLER LIVIANO
      final c = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      await c.initialize();

      if (!mounted || disposed) {
        await c.dispose();
        return;
      }

      /// CONFIG
      await c.setLooping(false);
      await c.setPlaybackSpeed(1.0);

      /// mute por defecto
      await c.setVolume(1);

      controller = c;

      /// autoplay
      paused = true;

      if (!mounted || disposed) return;

      setState(() {
        initialized = true;
      });
    } catch (e) {
      debugPrint("VIDEO ERROR: $e");
    }
  }

  @override
  void dispose() {
    disposed = true;

    final c = controller;

    controller = null;

    if (c != null) {
      c.pause();
      c.dispose();
    }

    super.dispose();
  }

  Future<void> togglePlayPause() async {
    final c = controller;

    if (c == null) return;

    if (c.value.isPlaying) {
      await c.pause();
      paused = true;
    } else {
      await c.play();
      paused = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> toggleMute() async {
    final c = controller;

    if (c == null) return;

    muted = !muted;

    await c.setVolume(muted ? 0 : 1);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;

    if (!initialized || c == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          /// VIDEO OPTIMIZADO
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
          ),

          /// PLAY
          if (paused)
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 80,
              ),
            ),

          /// MUTE
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: toggleMute,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  muted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoThumbnailWidget extends StatefulWidget {
  final String url;

  const VideoThumbnailWidget({super.key, required this.url});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  Uint8List? thumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final bytes = await vt.VideoThumbnail.thumbnailData(
        video: widget.url,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 400,
        quality: 75,
      );

      if (!mounted) return;

      setState(() {
        thumbnail = bytes;
      });
    } catch (e) {
      debugPrint('Thumbnail error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (thumbnail == null) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Image.memory(thumbnail!, fit: BoxFit.cover, gaplessPlayback: true);
  }
}

class VideoThumbnail extends StatefulWidget {
  final String url;

  const VideoThumbnail({super.key, required this.url});

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));

      await c.initialize();

      // Ir al primer frame
      await c.seekTo(Duration.zero);
      await c.pause();

      if (!mounted) {
        await c.dispose();
        return;
      }

      setState(() {
        _controller = c;
        _ready = true;
      });
    } catch (e) {
      debugPrint("Thumbnail error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}

class _FullScreenViewer extends StatefulWidget {
  final Post post;
  final int initialIndex;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Post post)? onEdit;

  const _FullScreenViewer({
    required this.post,
    required this.initialIndex,
    required this.onRefresh,
    this.onEdit,
  });

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late PageController controller;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    controller = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            /// ================= MEDIA =================
            PageView.builder(
              controller: controller,
              itemCount: post.medias.length,
              onPageChanged: (i) => setState(() => currentIndex = i),
              itemBuilder: (context, index) {
                final media = post.medias[index];

                return Center(
                  child: Hero(
                    tag: '${post.id}_${media.id}',

                    child: media.isVideo
                        ? VideoPlayerWidget(url: media.url)
                        : InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Image.network(
                              media.url,
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                );
              },
            ),

            /// ================= TOP BAR =================
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// CLOSE
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),

                  /// 3 DOTS (SOLO MIS POSTS)
                  if (widget.post.user.id.toString() ==
                      AuthService.currentUserId.toString())
                    PopupMenuButton<String>(
                      color: const Color.fromARGB(255, 235, 42, 151),
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.pop(context);
                          await widget.onEdit?.call(widget.post);
                        }

                        if (value == 'share') {
                          if (widget.post.medias.isNotEmpty) {
                            await SharePostHelper.sharePost(
                              imageUrl: widget.post.medias[currentIndex].url,
                              postType: widget.post.postType.name,
                              fileName: 'shared_${widget.post.id}',
                            );
                          }
                        }

                        if (value == 'view_post') {
                          Navigator.pop(context);
                          context.push('/posts/${widget.post.id}/view');
                        }

                        if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Eliminar post'),
                              content: const Text(
                                '¿Seguro que querés eliminar este post?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            Navigator.pop(context);
                            await PostsService.deletePost(
                              widget.post.id.toString(),
                            );
                            await widget.onRefresh();
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(
                            'Editar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),

                        PopupMenuItem(
                          value: 'share',
                          child: Text(
                            'Compartir',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),

                        PopupMenuItem(
                          value: 'view_post',
                          child: Text(
                            'Ver publicación',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),

                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            /// ================= BOTTOM OVERLAY (TU UI ORIGINAL) =================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 26),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(.85), Colors.transparent],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    /// ================= INFO =================
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// USER
                          Row(
                            children: [
                              CustomAvatar(url: post.user.imageUrl),
                              const SizedBox(width: 10),
                              Text(
                                post.user.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// DESCRIPTION
                          if (post.description.isNotEmpty)
                            Text(
                              post.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),

                          const SizedBox(height: 12),

                          /// VER PUBLICACIÓN
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/posts/${post.id}/view');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24),
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
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    /// ================= ACTIONS =================
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// LIKE
                        GestureDetector(
                          onTap: () async {
                            await PostsService.addReaction(
                              int.parse(post.id),
                              1,
                            );
                            await widget.onRefresh();
                            setState(() {});
                          },
                          child: Column(
                            children: [
                              const Icon(
                                Icons.favorite_border,
                                color: Colors.white,
                                size: 32,
                              ),
                              Text(
                                '${post.likes}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// COMMENTS
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/posts/${post.id}/view');
                          },
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// SHARE
                        GestureDetector(
                          onTap: () async {
                            if (post.medias.isEmpty) return;

                            await SharePostHelper.sharePost(
                              imageUrl: post.medias[currentIndex].url,
                              postType: post.postType.name,
                              fileName: 'shared_${post.id}',
                            );
                          },
                          child: const Icon(Icons.share, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
