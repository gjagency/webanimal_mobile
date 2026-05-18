import 'package:flutter/material.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'promocion_card.dart';

class PromocionesPorVeterinariaWidget extends StatefulWidget {
  final PromocionesPorVeterinaria grupo;

  const PromocionesPorVeterinariaWidget({
    super.key,
    required this.grupo,
  });

  @override
  State<PromocionesPorVeterinariaWidget> createState() =>
      _PromocionesPorVeterinariaWidgetState();
}

class _PromocionesPorVeterinariaWidgetState
    extends State<PromocionesPorVeterinariaWidget> {
  late final PageController _pageController;
  final Map<int, GlobalKey> _cardKeys = {};

  double _currentHeight = 420;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      viewportFraction: 0.90,
    );

    for (int i = 0; i < widget.grupo.promociones.length; i++) {
      _cardKeys[i] = GlobalKey();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHeight(0);
    });
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promociones = widget.grupo.promociones;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.only(top: 14, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      height: _currentHeight,
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
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
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Promociones disponibles',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
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
                        ? Colors.purple
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
      elevation: 6,
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