import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/service/auth_service.dart';

class UserPostsPage extends StatefulWidget {
  final String userId;
  const UserPostsPage({super.key, required this.userId});

  @override
  State<UserPostsPage> createState() => _UserPostsPageState();
}

class _UserPostsPageState extends State<UserPostsPage> {
  List<Post> _posts = [];
  Map<String, dynamic>? _profile;
  List<File> _newImages = [];
  List<int> _deleteImageIds = [];
  List<PostImage> _existingImages = [];
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
        avatarUrl =
            profile['avatar'] ?? 'https://i.pravatar.cc/150?img=10';
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
  final bool isMyProfile =
      widget.userId.toString() == AuthService.currentUserId.toString();
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

    final String nombreFinal =
        isVet && nombreComercial.isNotEmpty ? nombreComercial : displayName;

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
        child: const Icon(
          Icons.pets,
          color: Colors.white,
          size: 20,
        ),
      ),
      const SizedBox(width: 8),

      Expanded(
        child: const Text(
          'WebAnimal',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
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
    IconButton(
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () {
        context.push('/account/notifications');
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
                  ? const Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey,
                    )
                  : null,
            ),
    ),


    // configuraciones 3 puntitos
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'settings') {
          context.push('/account/settings');
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, size: 20),
              SizedBox(width: 8),
              Text('Configuración'),
            ],
          ),
        ),
      ],
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
                      backgroundImage: profileAvatarUrl != null &&
                              profileAvatarUrl.toString().isNotEmpty
                          ? NetworkImage(profileAvatarUrl)
                          : null,
                      child: (profileAvatarUrl == null ||
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
                                  "Posts"),
                              _stat(
                                  _profile?['followers_count']?.toString() ??
                                      "0",
                                  "Seguidores"),
                              _stat(
                                  _profile?['following_count']?.toString() ??
                                      "0",
                                  "Siguiendo"),
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
                          const Icon(Icons.verified,
                              color: Colors.blue, size: 18),
                        ],
                      ],
                    ),

                    /// BIO
                    if (bio.toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            /// ================= GRID POSTS =================
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _posts[index];

                  final imageUrl = post.imageUrls.isNotEmpty
                      ? post.imageUrls.first
                      : "https://via.placeholder.com/300";

                  return GestureDetector(
               onTap: () => _openImageViewer(post, 0),

                      child: Stack(
                        children: [
                          /// IMAGEN
                          Positioned.fill(
                            child: Hero(
                              tag: '${post.id}_0',
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          /// +X imágenes
                          if (post.imageUrls.length > 1)
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
                                  '+${post.imageUrls.length - 1}',
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


                },
                childCount: _posts.length,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
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
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style:
              const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
Future<void> _editarPost(Post post) async {
  final formKey = GlobalKey<FormState>();
  String description = post.description;
  final ImagePicker picker = ImagePicker();

  _newImages = [];
  _deleteImageIds = [];

  _existingImages = post.imageUrls.map((url) {
    final id = post.imageIdByUrl[url];
    return PostImage(id: id, url: url);
  }).toList();

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
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
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
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Ingrese descripción' : null,
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
                        ..._existingImages.map(
                          (img) => _imagePreview(
                            image: Image.network(
                              img.url,
                              fit: BoxFit.cover,
                            ),
                            onDelete: () {
                              setModalState(() {
                                if (img.id != null &&
                                    !_deleteImageIds.contains(img.id)) {
                                  _deleteImageIds.add(img.id!);
                                }
                                _existingImages.remove(img);
                              });
                            },
                          ),
                        ),

                        ..._newImages.map(
                          (file) => _imagePreview(
                            image: Image.file(
                              file,
                              fit: BoxFit.cover,
                            ),
                            onDelete: () {
                              setModalState(() {
                                _newImages.remove(file);
                              });
                            },
                          ),
                        ),

                        if ((_existingImages.length + _newImages.length) < 3)
                          GestureDetector(
                            onTap: () async {
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                              );

                              if (picked != null) {
                                setModalState(() {
                                  _newImages.add(File(picked.path));
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
                                      await PostsService.updatePostWithImages(
                                        postId: post.id.toString(),
                                        fields: {'body': description},
                                        newImages: _newImages,
                                        deleteImageIds: _deleteImageIds,
                                      );

                                      if (!context.mounted) return;

                                      Navigator.pop(context);
                                      await _refresh();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: $e',
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(
                                          () => _isSavingEdit = false,
                                        );
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

  final PageController controller =
      PageController(initialPage: initialIndex);

  int currentIndex = initialIndex;
  bool showHeart = false;

  for (var url in post.imageUrls) {
    precacheImage(NetworkImage(url), context);
  }

  showDialog(
    context: context,
    barrierColor: Colors.black,
    builder: (_) {
      bool isAlive = true;

      return StatefulBuilder(
        builder: (context, setState) {
          return GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null &&
                  details.primaryDelta! > 12) {
                isAlive = false;
                Navigator.pop(context);
              }
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  PageView.builder(
                    controller: controller,
                    itemCount: post.imageUrls.length,
                    onPageChanged: (i) {
        if (!isAlive) return;
        setState(() => currentIndex = i);
      },
                    itemBuilder: (context, index) {
                      final imageUrl = post.imageUrls[index];

                      return GestureDetector(
                        onDoubleTap: () async {
                            if (!isAlive) return;

                            setState(() => showHeart = true);

                            await Future.delayed(const Duration(milliseconds: 700));

                            if (!isAlive || !context.mounted) return;

                            setState(() => showHeart = false);
                          },
                        child: Center(
                          child: Hero(
                            tag: '${post.id}_$index',
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  if (showHeart)
                    const Center(
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 110,
                      ),
                    ),

                  Positioned(
                    top: 40,
                    right: 12,
                    child: Row(
                      children: [
                        if (isMyPost)
                          PopupMenuButton<String>(
                            color: Colors.white,
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                isAlive = false;
                                Navigator.pop(context);
                                _editarPost(post);
                              }

                              if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Eliminar post'),
                                    content: const Text(
                                        '¿Seguro que querés eliminar este post?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  Navigator.pop(context);
                                  await PostsService.deletePost(
                                      post.id.toString());
                                  _refresh();
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar'),
                              ),
                            ],
                          ),

                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
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
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      ),
    ],
  );
}




}
