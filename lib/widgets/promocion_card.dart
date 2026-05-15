import 'package:flutter/material.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/config.dart';

String getFullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '${Config.baseUrl}$path';
}

// ── Design tokens ────────────────────────────────────────────────
class _T {
  static const bg = Color(0xFF111827); // gris carbón profundo
  static const surface = Color(0xFF1F2937); // superficie elevada
  static const accent = Color(0xFF10B981); // esmeralda
  static const accentDim = Color(0xFF064E3B); // esmeralda oscuro
  static const warn = Color(0xFFF59E0B); // ámbar para precio
  static const textHigh = Color(0xFFF9FAFB);
  static const textMid = Color(0xFF9CA3AF);
  static const textLow = Color(0xFF4B5563);
  static const radius = 20.0;
}

class PromocionCard extends StatelessWidget {
  final Promocion promocion;
  final VoidCallback? onTap;

  const PromocionCard({super.key, required this.promocion, this.onTap});

  void _showImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
            // Botón cerrar
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: _T.surface,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.close_rounded,
                    color: _T.textMid,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = getFullImageUrl(promocion.imagen);
    final hasImage = promocion.imagen != null && imageUrl.isNotEmpty;
    final hasPrice =
        promocion.precio != null && promocion.precio.toString().isNotEmpty;
    final hasDesc = promocion.descripcion.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(_T.radius),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: _T.accent.withOpacity(0.04),
              blurRadius: 40,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Imagen hero con overlay ───────────────────────
            if (hasImage)
              GestureDetector(
                onTap: () => _showImagePopup(context, imageUrl),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(_T.radius),
                      ),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 195,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 195,
                          color: _T.bg,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: _T.textLow,
                            size: 40,
                          ),
                        ),
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                height: 195,
                                color: _T.bg,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: _T.accent,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                      ),
                    ),

                    // Gradiente inferior sobre imagen
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              _T.surface.withOpacity(0.95),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Ícono "tap para ampliar"
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Ver',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
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

            // ── Cuerpo ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chip de comercio
                  _ComercioChip(nombre: promocion.nombreComercio),

                  const SizedBox(height: 10),

                  // Título
                  Text(
                    promocion.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _T.textHigh,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),

                  // Descripción
                  if (hasDesc) ...[
                    const SizedBox(height: 6),
                    Text(
                      promocion.descripcion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _T.textMid,
                        height: 1.5,
                      ),
                    ),
                  ],

                  // Precio
                  if (hasPrice) ...[
                    const SizedBox(height: 14),
                    _PriceChip(precio: promocion.precio.toString()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip del comercio ────────────────────────────────────────────
class _ComercioChip extends StatelessWidget {
  final String nombre;
  const _ComercioChip({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: _T.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            nombre.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _T.accent,
              letterSpacing: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Chip de precio ───────────────────────────────────────────────
class _PriceChip extends StatelessWidget {
  final String precio;
  const _PriceChip({required this.precio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _T.warn.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _T.warn.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '\$',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _T.warn,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            precio,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _T.warn,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
