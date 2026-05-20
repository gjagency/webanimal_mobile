import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/widgets/modern_post_card.dart';
import 'package:mobile_app/widgets/promocion_card.dart';

class PostsFeed extends StatelessWidget {
  final List<Post> posts;
  final List<Promocion> promociones;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? selectedTypeId;
  final Future<void> Function() onRefresh;
  final void Function(Post post)? onEditPost;
  final ScrollController? controller;

  const PostsFeed({
    super.key,
    required this.posts,
    required this.promociones,
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
    required this.selectedTypeId,
    required this.onRefresh,
    this.onEditPost,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    /// =========================
    /// LOADING
    /// =========================
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    /// =========================
    /// ERROR
    /// =========================
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),

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

    /// =========================
    /// PROMOCIONES
    /// =========================
    if (selectedTypeId == 'promociones') {
      if (promociones.isEmpty) {
        return const Center(
          child: Text('No hay promociones activas'),
        );
      }

      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          controller: controller,

          /// PRELOAD SCROLL
          cacheExtent: 2500,

          /// OPTIMIZACIONES
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          addSemanticIndexes: false,

          padding: const EdgeInsets.only(
            top: 16,
            bottom: 80,
          ),

          itemCount: promociones.length + (isLoadingMore ? 1 : 0),

          itemBuilder: (context, index) {
            /// LOADER ABAJO
            if (index >= promociones.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final promo = promociones[index];

            return PromocionCard(
              promocion: promo,
            );
          },
        ),
      );
    }

    /// =========================
    /// EMPTY POSTS
    /// =========================
    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),

            SizedBox(height: 16),

            Text(
              'No se encontraron posts',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    /// =========================
    /// POSTS FEED
    /// =========================
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: controller,

        /// PRELOAD TIPO INSTAGRAM
        cacheExtent: 2500,

        /// OPTIMIZACIONES IMPORTANTES
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,

        padding: const EdgeInsets.only(
          top: 16,
          bottom: 80,
        ),

        itemCount: posts.length + (isLoadingMore ? 1 : 0),

        itemBuilder: (context, index) {
          /// =========================
          /// LOADER FINAL
          /// =========================
          if (index >= posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final post = posts[index];

          /// =========================
          /// PRECARGA DE IMÁGENES
          /// =========================
          ///
          /// Precarga el siguiente post
          /// para sensación Instagram
          ///
          if (index < posts.length - 1) {
            final nextPost = posts[index + 1];

            for (final media in nextPost.medias) {
              if (!media.isVideo) {
                precacheImage(
                  CachedNetworkImageProvider(media.url),
                  context,
                );
              }
            }
          }

          /// =========================
          /// PRECARGA EXTRA
          /// =========================
          ///
          /// Precarga dos posts adelante
          ///
          if (index < posts.length - 2) {
            final nextPost2 = posts[index + 2];

            for (final media in nextPost2.medias) {
              if (!media.isVideo) {
                precacheImage(
                  CachedNetworkImageProvider(media.url),
                  context,
                );
              }
            }
          }

          /// =========================
          /// POST CARD
          /// =========================
          return ModernPostCard(
            key: ValueKey(post.id),

            post: post,

            onEdit: onEditPost != null
                ? () => onEditPost!(post)
                : null,
          );
        },
      ),
    );
  }
}