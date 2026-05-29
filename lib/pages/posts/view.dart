import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mobile_app/widgets/avatar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/utils/share_post_helper.dart';
import 'package:mobile_app/widgets/modern_post_card.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
class PagePostView extends StatefulWidget {
  final String postId;
  const PagePostView({super.key, required this.postId});

  @override
  State<PagePostView> createState() => _PagePostViewState();
}

class _PagePostViewState extends State<PagePostView> {
  final GlobalKey<FeedVideoPlayerState> _videoKey =
    GlobalKey<FeedVideoPlayerState>();
  int _visibleComments = 10;
  String avatarUrl = '';
  bool loadingProfile = true;
  Post? _post;
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _commentController = TextEditingController();
  bool _isCommenting = false;
  String _commentMessage = 'Comentando...';
  final ValueNotifier<double> _commentProgress = ValueNotifier(0.0);
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

    final media = _post!.medias.first;

    /// VIDEO
    if (media.isVideo) {
      final tempDir = await getTemporaryDirectory();

      final filePath = '${tempDir.path}/shared_video_${widget.postId}.mp4';

      final file = File(filePath);

      /// si ya existe no lo vuelve a descargar
      if (!await file.exists()) {
        final request = await HttpClient().getUrl(Uri.parse(media.url));
        final response = await request.close();

        final bytes = await consolidateHttpClientResponseBytes(response);

        await file.writeAsBytes(bytes);
      }

      await Share.shareXFiles([XFile(file.path)], text: '🐾 @WeBaNiMaL');

      return;
    }

    /// IMAGEN
    await SharePostHelper.sharePost(
      imageUrl: media.url,
      postType: _post!.postType.name,
      fileName: 'shared_${widget.postId}',
    );
  }
void _openImagePopup(BuildContext context, int initialIndex) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.92),
    builder: (context) {
      double dragOffset = 0;

      return StatefulBuilder(
        builder: (context, setState) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [

                /// FONDO
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(color: Colors.transparent),
                  ),
                ),

                /// DRAG
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      dragOffset += details.delta.dy;
                    });
                  },

                  onVerticalDragEnd: (_) {
                    if (dragOffset.abs() > 140) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        dragOffset = 0;
                      });
                    }
                  },

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    transform:
                        Matrix4.translationValues(0, dragOffset, 0),

                    child: Center(
                      child: Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 40,
                        ),

                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.78,

                          child: PageView.builder(
                            controller: PageController(
                              initialPage: initialIndex,
                            ),

                            itemCount: _post!.medias.length,

                            itemBuilder: (context, index) {
                              final media = _post!.medias[index];

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius:
                                      BorderRadius.circular(22),
                                ),

                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(22),

                                  child: InteractiveViewer(
                                    minScale: 1,
                                    maxScale: 4,

                                    child: media.isVideo
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [

                                              FeedVideoPlayer(
                                                url: media.url,
                                                autoplay: true,
                                              ),

                                              const Center(
                                                child: IgnorePointer(
                                                  child: Icon(
                                                    Icons.play_circle_fill,
                                                    color: Colors.white,
                                                    size: 80,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )

                                        : CachedNetworkImage(
                                            imageUrl: media.url,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                            height: double.infinity,

                                            placeholder: (_, __) =>
                                                Container(
                                              color: Colors.black,
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),

                                            errorWidget:
                                                (_, __, ___) =>
                                                    const Icon(
                                              Icons.broken_image,
                                              color: Colors.white,
                                            ),
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

                /// CLOSE
                Positioned(
                  top: 45,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),

                    child: Container(
                      padding: const EdgeInsets.all(10),

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
              ],
            ),
          );
        },
      );
    },
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
    final commentText = _commentController.text.trim();

    if (commentText.isEmpty) return;

    // VALIDACIÓN 256 caracteres
    if (commentText.length > 256) {
      setState(() {
        _isCommenting = true;
        _commentMessage = 'Máximo 256 caracteres';
        _commentProgress.value = 0;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() {
        _isCommenting = false;
        _commentMessage = 'Comentando...';
        _commentProgress.value = 0.0;
      });

      return;
    }

    setState(() {
      _isCommenting = true;
      _commentMessage = 'Comentando...';
      _commentProgress.value = 0.2;
    });

    try {
      await PostsService.addComment(widget.postId, commentText);

      _commentProgress.value = 1.0;

      await Future.delayed(const Duration(milliseconds: 400));

      _commentController.clear();
      FocusScope.of(context).unfocus();
      await _loadPost();

      if (!mounted) return;

      setState(() {
        _commentMessage = 'Comentario agregado con EXITO!';
      });

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() {
        _isCommenting = false;
        _commentMessage = 'Comentando...';
        _commentProgress.value = 0.0;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _commentMessage = 'Error al comentar';
        _commentProgress.value = 0.0;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() {
        _isCommenting = false;
        _commentMessage = 'Comentando...';
      });
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
  titleSpacing: 6,
  toolbarHeight: 58,
  title: LayoutBuilder(
    builder: (context, constraints) {
      final isSmall = MediaQuery.of(context).size.width < 370;

      return Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 6 : 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.pink],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              "assets/logo6.png",
              width: isSmall ? 18 : 22,
              height: isSmall ? 18 : 22,
            ),
          ),

          SizedBox(width: isSmall ? 6 : 10),

          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                "WebAnimal",
                maxLines: 1,
                style: TextStyle(
                  fontSize: isSmall ? 15 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    },
  ),

  actions: [
    IconButton(
      iconSize: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: const Icon(Icons.search),
      onPressed: () {
        context.push('/search/users');
      },
    ),

    const SizedBox(width: 10),

    GestureDetector(
      onTap: () {
        context.push('/user-posts/${AuthService.currentUserId}');
      },
      child: SizedBox(
        width: 32,
        height: 32,
        child: CustomAvatar(url: avatarUrl),
      ),
    ),

    const SizedBox(width: 10),

    IconButton(
      iconSize: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: const Icon(Icons.settings),
      onPressed: () {
        context.push('/account/settings');
      },
    ),

    const SizedBox(width: 12),
  ],
),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.only(bottom: 6),
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CustomAvatar(url: post.user.imageUrl),
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
                          style: const TextStyle(fontSize: 14, height: 1.4),
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
// MEDIA
// MEDIA
post.medias.isNotEmpty && post.medias.first.isVideo
    ? ClipRect(
        child: SizedBox(
          width: double.infinity,
          height: 400,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [

              /// VIDEO
              Positioned.fill(
                child: FeedVideoPlayer(
  key: _videoKey,
  url: post.medias.first.url,
  autoplay: false,
),
              ),

              /// TAP SOLO EN EL CENTRO
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                onTap: () async {

  await _videoKey.currentState?.pauseVideo();

  await Navigator.of(context).push(
   PageRouteBuilder(
  opaque: false,
  barrierColor: Colors.black,

  pageBuilder: (_, __, ___) => FullScreenVideoPage(
    videoUrl: post.medias.first.url,
    liked: post.reacciones.isNotEmpty,
    likes: post.likes,
    comments: post.comments,
    userName: post.user.displayName,
    userAvatar:
        post.user.imageUrl ??
        'https://i.pravatar.cc/300',
    userId: post.user.id,
    description: post.description,

    onLike: () async {
      await _toggleLike();
    },

    onOpenPost: () {
      Navigator.pop(context);
    },
  ),
),
  );

  _videoKey.currentState?.playVideo();
},

                  child: Container(
                    width: 180,
                    height: 180,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      )

    : GestureDetector(
  onTap: () {
    if (!post.medias.first.isVideo) {
      _openImagePopup(context, 0);
    }
  },

  child: Image.network(
    post.medias.isNotEmpty
        ? post.medias.first.url
        : "https://via.placeholder.com/400x300?text=Sin+Imagen",

    width: double.infinity,
    fit: BoxFit.cover,
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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

          if (_isCommenting) _buildCommentOverlay(),
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
                      CustomAvatar(url: avatarUrl),

                      const SizedBox(width: 12),

                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          maxLength: 256,
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

        Widget _buildCommentOverlay() {
          return Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _commentProgress,
            builder: (_, value, __) => SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: _commentMessage == 'Comentando...'
                    ? (value == 0 ? null : value)
                    : 1,
                strokeWidth: 4,
                color: Colors.purple,
                backgroundColor: Colors.purple.shade50,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Flexible(
            child: Text(
              _commentMessage,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
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
      });
    } finally {
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
          CustomAvatar(url: comment.avatar),

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
