import 'package:flutter/material.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/config.dart';

String getFullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '${Config.baseUrl}$path';
}

class _T {
  static const bg = Color(0xFF111827);
  static const surface = Color(0xFF1F2937);
  static const accent = Color(0xFF10B981);
  static const accentDim = Color(0xFF064E3B);
  static const warn = Color(0xFFF59E0B);
  static const textHigh = Color(0xFFF9FAFB);
  static const textMid = Color(0xFF9CA3AF);
  static const textLow = Color(0xFF4B5563);
  static const radius = 20.0;
}

class PromocionCard extends StatelessWidget {
  final Promocion promocion;
  final VoidCallback? onTap;

  const PromocionCard({
    super.key,
    required this.promocion,
    this.onTap,
  });

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
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: _T.surface,
                    shape: BoxShape.circle,
                  ),
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
        promocion.precio != null &&
        promocion.precio.toString().isNotEmpty;
    final hasDesc = promocion.descripcion.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(_T.radius),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
                      ),
                    ),
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

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ComercioChip(
                    nombre: promocion.nombreComercio,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    promocion.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _T.textHigh,
                    ),
                  ),

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

                  const SizedBox(height: 12),

                 _DateChip(
                    fechaInicio: promocion.fechadesde,
                    fechaFin: promocion.fechahasta,
                  ),

                  if (hasPrice) ...[
                    const SizedBox(height: 14),
                    _PriceChip(
                      precio: promocion.precio.toString(),
                    ),
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

class _DateChip extends StatelessWidget {
  final String? fechaInicio;
  final String? fechaFin;

  const _DateChip({
    required this.fechaInicio,
    required this.fechaFin,
  });

  String _format(String? date) {
    if (date == null || date.isEmpty) return '--';

    try {
      final parsed = DateTime.parse(date);

      return '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year}';
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _T.accentDim,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 16,
            color: _T.accent,
          ),
          const SizedBox(width: 8),
          Text(
            '${_format(fechaInicio)} - ${_format(fechaFin)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _T.accent,
            ),
          ),
        ],
      ),
    );
  }
}
class _ComercioChip extends StatelessWidget {
  final String nombre;

  const _ComercioChip({
    required this.nombre,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      nombre.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: _T.accent,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String precio;

  const _PriceChip({
    required this.precio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _T.warn.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _T.warn.withOpacity(0.3),
        ),
      ),
      child: Text(
        '\$ $precio',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _T.warn,
        ),
      ),
    );
  }
}