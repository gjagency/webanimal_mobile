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
  
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _load();
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
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
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

    final avatarUrl = _profile?['avatar'];
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
                          backgroundImage:
                              avatarUrl != null && avatarUrl.toString().isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                          child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                              ? const Icon(Icons.person,
                                  color: Colors.white, size: 40)
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
                            fontSize: 16,
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

                          /// 3 puntitos editar/eliminar
                          if (isMyProfile)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  color: Colors.white,
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      // reutilizá tu método de editar
                                      // _editarPost(post);
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
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await PostsService.deletePost(post.id.toString());
                                        _refresh();
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            'Eliminar',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
  final _formKey = GlobalKey<FormState>();
  String description = post.description;

  final ImagePicker _picker = ImagePicker();

  // Limpiar listas por si venían de otro edit
  _newImages = [];
  _deleteImageIds = [];

_existingImages = post.imageUrls.map((url) {
  final id = post.imageIdByUrl[url];   // 👈 USAR URL COMPLETA

  return PostImage(id: id, url: url);
}).toList();
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Post', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Descripción
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  validator: (v) => v == null || v.isEmpty ? 'Ingrese una descripción' : null,
                  onSaved: (v) => description = v ?? '',
                ),
                const SizedBox(height: 12),

                // IMÁGENES
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // 🔹 Existentes
                    ..._existingImages.map((img) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              img.url,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                          setState(() {
                            // Si tiene ID real, lo agregamos a deleteImageIds
                            if (img.id != null && !_deleteImageIds.contains(img.id)) {
                              _deleteImageIds.add(img.id!);
                            }
                            // Removemos la imagen de la UI
                            _existingImages.remove(img);
                          });
                        },


                              child: const Icon(Icons.cancel, color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    }).toList(),

                    // 🔹 Nuevas (local)
                    ..._newImages.map((file) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              file,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _newImages.remove(file);
                                });
                              },
                              child: const Icon(Icons.cancel, color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),

                const SizedBox(height: 12),

                // Botón agregar imagen
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Agregar Imagen'),
                  onPressed: () async {
                    final totalImages = _existingImages.length + _newImages.length;
                    if (totalImages >= 3) {
                      showDialog(
                        context: context,
                        builder: (_) => const AlertDialog(
                          content: Text('Solo podés agregar hasta 3 imágenes'),
                        ),
                      );
                      return;
                    }

                    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setState(() {
                        _newImages.add(File(picked.path));
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
         ElevatedButton(
  onPressed: _isSavingEdit
      ? null
      : () async {
          if (!_formKey.currentState!.validate()) return;
          _formKey.currentState!.save();

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

            // ===============================
            // POPUP ÉXITO PRO
            // ===============================
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Post actualizado',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Los cambios se guardaron correctamente',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },            
                    child: const Text('OK'),
                  )
                ],
              ),
            );


            await _refresh();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al actualizar post: $e')),
            );
          } finally {
            if (mounted) setState(() => _isSavingEdit = false);
          }
        },
  child: _isSavingEdit
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Text('Guardar'),
),

        ],
      ),
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




}
