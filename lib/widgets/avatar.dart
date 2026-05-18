import 'package:flutter/material.dart';

class CustomAvatar extends StatefulWidget {
  final bool loading;
  final double size;
  final String? url;

  const CustomAvatar({
    super.key,
    this.loading = false,
    this.url,
    this.size = 40,
  });

  @override
  State<CustomAvatar> createState() => _CustomAvatarState();
}

class _CustomAvatarState extends State<CustomAvatar> {
  OverlayEntry? _overlayEntry;

  void _showFullScreen() {
    if (widget.url == null || widget.url!.isEmpty) return;
    final size = MediaQuery.of(context).size.width * 0.8;
    _overlayEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        onLongPressEnd: (_) => _hideFullScreen(),
        child: Material(
          color: Colors.black87,
          child: Center(
            child: ClipOval(
              child: SizedBox.square(
                dimension: size,
                child: Image.network(
                  widget.url!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const ColoredBox(
                      color: Colors.black26,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideFullScreen() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideFullScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _showFullScreen,
      onLongPressEnd: (_) => _hideFullScreen(),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Colors.purple, Colors.pink]),
        ),
        child: Center(
          child: Container(
            width: widget.size - 4,
            height: widget.size - 4,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child: _child(),
          ),
        ),
      ),
    );
  }

  Widget _child() {
    if (widget.loading) {
      return const ColoredBox(
        color: Colors.white12,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1),
        ),
      );
    }

    return SizedBox.square(
      dimension: widget.size,
      child: Image.network(
        widget.url ?? "",
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const ColoredBox(
            color: Colors.white12,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 1,
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) =>
            Icon(Icons.person, size: widget.size / 2, color: Colors.white),
      ),
    );
  }
}
