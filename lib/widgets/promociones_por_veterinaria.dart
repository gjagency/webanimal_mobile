import 'package:flutter/material.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'promocion_card.dart';

const _kBrandStart = Color(0xFF9B4DCC);
const _kBrandEnd = Color(0xFFE0528D);

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
  late final PageController _pageController;
  Map<int, GlobalKey> _cardKeys = {};

  double _currentHeight = 420;
  int _currentIndex = 0;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      viewportFraction: 0.90,
    );

    _rebuildKeys();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHeight(0);
    });
  }

  void _rebuildKeys() {
    _cardKeys = {
      for (int i = 0; i < widget.grupo.promociones.length; i++) i: GlobalKey(),
    };
  }

  void _updateHeight(int index) {
    final key = _cardKeys[index];

    if (key?.currentContext != null) {
      final box = key!.currentContext!.findRenderObject() as RenderBox;

      setState(() {
        _currentHeight = box.size.height + 90;
        _currentIndex = index;
      });
    }
  }

  void _nextPage() {
    if (_currentIndex < widget.grupo.promociones.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _confirmAndDelete() async {
    final promociones = widget.grupo.promociones;
    if (_isDeleting || promociones.isEmpty) return;
    final promo = promociones[_currentIndex];

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

    setState(() => _isDeleting = true);

    final ok = await PromocionesService.eliminarPromocion(promo.id);

    if (!mounted) return;

    if (!ok) {
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la promoción')),
      );
      return;
    }

    setState(() {
      widget.grupo.promociones.removeAt(_currentIndex);
      _rebuildKeys();
      _isDeleting = false;

      if (widget.grupo.promociones.isEmpty) {
        return;
      }

      if (_currentIndex >= widget.grupo.promociones.length) {
        _currentIndex = widget.grupo.promociones.length - 1;
      }
    });

    if (widget.grupo.promociones.isEmpty) {
      widget.onEmpty?.call();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
      _updateHeight(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promociones = widget.grupo.promociones;

    if (promociones.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.only(top: 14, bottom: 12),
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
      height: _currentHeight,
      child: Column(
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
                    '${_currentIndex + 1}/${promociones.length}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _DeleteIconButton(
                  isBusy: _isDeleting,
                  onTap: _confirmAndDelete,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // CAROUSEL
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: promociones.length,
                  onPageChanged: _updateHeight,
                  itemBuilder: (context, index) {
                    return AnimatedScale(
                      duration: const Duration(milliseconds: 250),
                      scale: _currentIndex == index ? 1 : 0.96,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: PromocionCard(
                            key: _cardKeys[index],
                            promocion: promociones[index],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                if (promociones.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ModernArrowButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: _prevPage,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ModernArrowButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: _nextPage,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // INDICADORES
          if (promociones.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                promociones.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? _kBrandStart
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeleteIconButton extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onTap;

  const _DeleteIconButton({
    required this.isBusy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade50,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isBusy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: isBusy
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.red),
                  ),
                )
              : Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade400,
                  size: 18,
                ),
        ),
      ),
    );
  }
}

class _ModernArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ModernArrowButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: Colors.black87,
            size: 24,
          ),
        ),
      ),
    );
  }
}
