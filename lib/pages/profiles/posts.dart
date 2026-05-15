import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/service/media_service.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:mobile_app/utils/share_post_helper.dart';

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
        avatarUrl = profile['avatar'] ?? 'https://i.pravatar.cc/150?img=10';
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

      setState(() {
        _loading = false;
        loadingProfile = false; // <-- faltaba esto
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        loadingProfile = false; // también acá
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
                      children: [
                        /// AVATAR
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              profileAvatarUrl != null &&
                                  profileAvatarUrl.toString().isNotEmpty
                              ? NetworkImage(profileAvatarUrl)
                              : null,
                          child:
                              (profileAvatarUrl == null ||
                                  profileAvatarUrl.toString().isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                )
                              : null,
                        ),

                        const SizedBox(width: 20),

                        /// STATS
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _stat(
                                _profile?['posts_count']?.toString() ?? "0",
                                "Posts",
                              ),
                              _stat(
                                _profile?['followers_count']?.toString() ?? "0",
                                "Seguidores",
                              ),
                              _stat(
                                _profile?['following_count']?.toString() ?? "0",
                                "Siguiendo",
                              ),
                            ],
                          ),
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

                final imageUrl = post.medias.isNotEmpty
                    ? post.medias.first.url
                    : "https://via.placeholder.com/300";

                return GestureDetector(
                  onTap: () => _openImageViewer(post, 0),

                  child: Stack(
                    children: [
                      /// IMAGEN
                      Positioned.fill(
                        child: Hero(
                          tag: '${post.id}_0',
                          child: Image.network(imageUrl, fit: BoxFit.cover),
                        ),
                      ),

                      /// +X imágenes
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
                              color: Colors.black.withOpacity(0.65),
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

    _medias = post.medias;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 30,
            ),
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
                      /// HEADER
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
                          const Text(
                            'Editar Post',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// TEXTFIELD
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

                      /// IMAGES GRID
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ..._medias.map(
                            (media) => _imagePreview(
                              image: Image.network(
                                media.url,
                                fit: BoxFit.cover,
                              ),
                              onDelete: () {
                                setModalState(() {
                                  _medias.remove(media);
                                });
                              },
                            ),
                          ),

                          if (_medias.length < 3)
                            GestureDetector(
                              onTap: () async {
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );

                                if (picked != null) {
                                  final media = await MediaService.upload(
                                    File(picked.path),
                                  );

                                  setModalState(() {
                                    _medias.add(
                                      PostMedia(
                                        id: media.id ?? "",
                                        url: media.url ?? "",
                                        mimeType: media.mimeType ?? "",
                                        filename: media.filename ?? "",
                                      ),
                                    );
                                  });
                                }
                              },
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 30,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      /// BOTONES
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSavingEdit
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }

                                      formKey.currentState!.save();

                                      setState(() => _isSavingEdit = true);

                                      try {
                                        await PostsService.updatePost(
                                          post.id.toString(),
                                          description: description,
                                          mediaIds: _medias
                                              .map((m) => m.id)
                                              .toList(),
                                        );

                                        if (!context.mounted) return;

                                        Navigator.pop(context);
                                        await _refresh();
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isSavingEdit = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSavingEdit
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Guardar'),
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
    final bool isMyPost =
        widget.userId.toString() == AuthService.currentUserId.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        double dragOffset = 0;
        int currentIndex = initialIndex;
        bool showHeart = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                  GestureDetector(
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        dragOffset += details.delta.dy;
                      });
                    },
                    onVerticalDragEnd: (_) {
                      if (dragOffset > 150) {
                        Navigator.pop(context);
                      } else {
                        setState(() => dragOffset = 0);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.translationValues(0, dragOffset, 0),
                      child: Center(
                        child: Dialog(
                          insetPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 40,
                          ),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: Column(
                              children: [
                                /// HEADER FUERA DE LA IMAGEN
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(18),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),

                                      Row(
                                        children: [
                                          if (isMyPost)
                                            PopupMenuButton<String>(
                                              color: const Color.fromARGB(
                                                255,
                                                235,
                                                42,
                                                151,
                                              ),
                                              icon: const Icon(
                                                Icons.more_vert,
                                                color: Colors.white,
                                              ),
                                              onSelected: (value) async {
                                                if (value == 'edit') {
                                                  Navigator.pop(context);
                                                  _editarPost(post);
                                                }

                                                if (value == 'share' &&
                                                    post.medias.isNotEmpty) {
                                                  await SharePostHelper.sharePost(
                                                    imageUrl: post
                                                        .medias[currentIndex]
                                                        .url,
                                                    postType:
                                                        post.postType.name,
                                                    fileName:
                                                        'shared_${post.id}',
                                                  );
                                                }

                                                if (value == 'view_post') {
                                                  Navigator.pop(context);
                                                  context.push(
                                                    '/posts/${post.id}/view',
                                                  );
                                                }

                                                if (value == 'delete') {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      title: const Text(
                                                        'Eliminar post',
                                                      ),
                                                      content: const Text(
                                                        '¿Seguro que querés eliminar este post?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                false,
                                                              ),
                                                          child: const Text(
                                                            'Cancelar',
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                true,
                                                              ),
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                          child: const Text(
                                                            'Eliminar',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirm == true) {
                                                    Navigator.pop(context);
                                                    await PostsService.deletePost(
                                                      post.id.toString(),
                                                    );
                                                    _refresh();
                                                  }
                                                }
                                              },
                                              itemBuilder: (_) => const [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text(
                                                    'Editar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'share',
                                                  child: Text(
                                                    'Compartir',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'view_post',
                                                  child: Text(
                                                    'Ver publicación',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text(
                                                    'Eliminar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                  255,
                                                  235,
                                                  42,
                                                  151,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  context.push(
                                                    '/posts/${post.id}/view',
                                                  );
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 8,
                                                      ),
                                                ),
                                                child: const Text(
                                                  'Ver publicación',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                /// IMAGEN
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(18),
                                    ),
                                    child: Stack(
                                      children: [
                                        PageView.builder(
                                          controller: PageController(
                                            initialPage: initialIndex,
                                          ),
                                          itemCount: post.medias.length,
                                          onPageChanged: (i) {
                                            setState(() => currentIndex = i);
                                          },
                                          itemBuilder: (context, index) {
                                            final imageUrl =
                                                post.medias[index].url;

                                            return InteractiveViewer(
                                              minScale: 1,
                                              maxScale: 4,
                                              child: Container(
                                                color: Colors.black,
                                                child: Center(
                                                  child: Hero(
                                                    tag: '${post.id}_$index',
                                                    child: Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.contain,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
