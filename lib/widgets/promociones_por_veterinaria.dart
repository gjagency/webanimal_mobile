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
  double _currentHeight = 400; // altura inicial

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);

    for (int i = 0; i < widget.grupo.promociones.length; i++) {
      _cardKeys[i] = GlobalKey();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHeight(0);
    });
  }

  void _updateHeight(int index) {
    final key = _cardKeys[index];
    if (key != null && key.currentContext != null) {
      final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
      setState(() {
        _currentHeight = box.size.height;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: _currentHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.grupo.promociones.length,
            onPageChanged: (index) => _updateHeight(index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4), // separación menor
                child: SingleChildScrollView(
                  child: PromocionCard(
                    key: _cardKeys[index],
                    promocion: widget.grupo.promociones[index],
                  ),
                ),
              );
            },
          ),

          // ⬅️ Flecha izquierda
          if (widget.grupo.promociones.length > 1)
            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: _ArrowButton(
                  icon: Icons.chevron_left,
                  onTap: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
            ),

          // ➡️ Flecha derecha
          if (widget.grupo.promociones.length > 1)
            Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: _ArrowButton(
                  icon: Icons.chevron_right,
                  onTap: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 28,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
