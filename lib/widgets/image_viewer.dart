import 'package:flutter/material.dart';

class ImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController controller;
  int currentIndex = 0;
  bool showHeart = false;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: widget.initialIndex);
    currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => currentIndex = i),
        itemBuilder: (_, index) {
          final imageUrl = widget.images[index];

          return GestureDetector(
            onDoubleTap: () async {
              setState(() => showHeart = true);

              await Future.delayed(const Duration(milliseconds: 700));

              if (!mounted) return;

              setState(() => showHeart = false);
            },
            child: Center(
              child: Image.network(imageUrl),
            ),
          );
        },
      ),
    );
  }
}