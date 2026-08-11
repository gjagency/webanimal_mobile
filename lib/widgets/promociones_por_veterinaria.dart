import 'package:flutter/material.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/config.dart';

const _kBrandStart = Color(0xFF9B4DCC);
const _kBrandEnd = Color(0xFFE0528D);

String _fullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '${Config.baseUrl}$path';
}

class PromocionesPorVeterinariaWidget extends StatefulWidget {
  final PromocionesPorVeterinaria grupo;
  final VoidCallback? onEmpty;

  const PromocionesPorVeterinariaWidget({
    super.key,
    required this.grupo,
    this.onEmpty,
  });

  @override
  State<PromocionesPorVeterinariaWidget> createState() =>
      _PromocionesPorVeterinariaWidgetState();
}

class _PromocionesPorVeterinariaWidgetState
    extends State<PromocionesPorVeterinariaWidget> {
  int _selectedIndex = 0;
  bool _isDeleting = false;
  String? _deletingId;

  Future<void> _confirmAndDelete(Promocion promo) async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Eliminar promoción'),
        content: Text(
          '¿Seguro que querés eliminar "${promo.titulo}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
      _deletingId = promo.id;
    });

    final ok = await PromocionesService.eliminarPromocion(promo.id);

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _isDeleting = false;
        _deletingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la promoción')),
      );
      return;
    }

    setState(() {
      widget.grupo.promociones.removeWhere((p) => p.id == promo.id);
      _isDeleting = false;
      _deletingId = null;

      if (widget.grupo.promociones.isNotEmpty &&
          _selectedIndex >= widget.grupo.promociones.length) {
        _selectedIndex = widget.grupo.promociones.length - 1;
      }
    });

    if (widget.grupo.promociones.isEmpty) {
      widget.onEmpty?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final promociones = widget.grupo.promociones;

    if (promociones.isEmpty) {
      return const SizedBox.shrink();
    }

    final index = _selectedIndex.clamp(0, promociones.length - 1);
    final selected = promociones[index];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kBrandStart, _kBrandEnd],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Promociones disponibles',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${promociones.length}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // "STORIES" SELECTOR
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: promociones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final promo = promociones[i];
                final isSelected = i == index;
                return _PromoBubble(
                  promo: promo,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedIndex = i),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _PromoDetailPanel(
                key: ValueKey(selected.id),
                promocion: selected,
                isDeleting: _deletingId == selected.id,
                onDelete: () => _confirmAndDelete(selected),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoBubble extends StatelessWidget {
  final Promocion promo;
  final bool isSelected;
  final VoidCallback onTap;

  const _PromoBubble({
    required this.promo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _fullImageUrl(promo.imagen);
    final hasImage = promo.imagen != null && imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_kBrandStart, _kBrandEnd],
                      )
                    : null,
                color: isSelected ? null : Colors.grey.shade200,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: hasImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              promo.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: Icon(
        Icons.local_offer_rounded,
        color: Colors.grey.shade400,
        size: 22,
      ),
    );
  }
}

class _PromoDetailPanel extends StatelessWidget {
  final Promocion promocion;
  final bool isDeleting;
  final VoidCallback onDelete;

  const _PromoDetailPanel({
    super.key,
    required this.promocion,
    required this.isDeleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _fullImageUrl(promocion.imagen);
    final hasImage = promocion.imagen != null && imageUrl.isNotEmpty;
    final hasPrice =
        promocion.precio != null && promocion.precio.toString().isNotEmpty;
    final hasDesc = promocion.descripcion.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Colors.grey.shade400,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _DeleteButton(busy: isDeleting, onTap: onDelete),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        promocion.nombreComercio.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _kBrandStart,
                          letterSpacing: 1.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!hasImage) _DeleteButton(busy: isDeleting, onTap: onDelete),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  promocion.titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                if (hasDesc) ...[
                  const SizedBox(height: 6),
                  Text(
                    promocion.descripcion,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_month_rounded,
                      label: '${_formatDate(promocion.fechadesde)} - ${_formatDate(promocion.fechahasta)}',
                    ),
                    if (hasPrice)
                      _InfoChip(
                        icon: Icons.sell_rounded,
                        label: '\$ ${promocion.precio}',
                        emphasized: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
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
}

class _DeleteButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;

  const _DeleteButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.red),
                  ),
                )
              : const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 18,
                ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: emphasized ? const Color(0xFFFFF3E0) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: emphasized
            ? Border.all(color: const Color(0xFFFFB74D))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: emphasized ? const Color(0xFFE65100) : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: emphasized ? const Color(0xFFE65100) : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
