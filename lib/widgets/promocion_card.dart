import 'package:flutter/material.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/config.dart';

String getFullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '${Config.baseUrl}$path';
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
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 247, 226, 242),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // se ajusta automáticamente
          children: [
            // Veterinaria arriba de la imagen
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'VETERINARIA: ${promocion.nombreComercio.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),

            // Imagen con popup
            if (promocion.imagen != null)
              GestureDetector(
                onTap: () =>
                    _showImagePopup(context, getFullImageUrl(promocion.imagen)),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    getFullImageUrl(promocion.imagen),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Info de la promoción
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // ajusta según texto
                children: [
                  Text(
                    promocion.titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),

                  if (promocion.precio != null &&
                      promocion.precio!.toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '\$ ${promocion.precio}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],

                  if (promocion.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      promocion.descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
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
