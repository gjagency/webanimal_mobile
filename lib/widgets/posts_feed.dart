import 'package:flutter/material.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/widgets/modern_post_card.dart';
import 'package:mobile_app/widgets/promocion_card.dart';
import 'package:mobile_app/service/auth_service.dart';

class PostsFeed extends StatelessWidget {
  final List<Post> posts;
  final List<Promocion> promociones;
  final bool isLoading;
  final String? error;
  final String? selectedTypeId;
  final Future<void> Function() onRefresh;
  final void Function(Post post)? onEditPost; 

  const PostsFeed({
    super.key,
    required this.posts,
    required this.promociones,
    required this.isLoading,
    required this.error,
    required this.selectedTypeId,
    required this.onRefresh,
    this.onEditPost,
  });

  @override

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onRefresh(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (selectedTypeId == 'promociones') {
      if (promociones.isEmpty) return const Center(child: Text('No hay promociones activas'));
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
          itemCount: promociones.length,
          itemBuilder: (context, index) => PromocionCard(promocion: promociones[index], onTap: () {}),
          
        ),
      );
    }

    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No se encontraron posts', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }
return RefreshIndicator(
  onRefresh: onRefresh,
  child: ListView.builder(
    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
    itemCount: posts.length,
    itemBuilder: (context, index) {
      final post = posts[index];
      // Solo permitir editar si estamos en "Mis Posts" y es tu post
      final canEdit = selectedTypeId == 'mis_posts' &&
                      post.user.id == AuthService.currentUserId;

      return ModernPostCard(
        post: post,
        onEdit: canEdit
            ? () {
                if (onEditPost != null) onEditPost!(post);
              }
            : null,
      );
    }, 
  ),
);

  }
}
