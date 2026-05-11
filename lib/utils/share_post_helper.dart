import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SharePostHelper {
  static Future<File> createImageWithTexts({
    required String imageUrl,
    required String topText,
    required String watermarkText,
    required String fileName,
  }) async {
    final response = await http.get(Uri.parse(imageUrl));
    final bytes = response.bodyBytes;

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final originalImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImage(originalImage, Offset.zero, Paint());

    final width = originalImage.width.toDouble();
    final height = originalImage.height.toDouble();

    final bannerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.75),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, width, height * 0.18),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height * 0.18),
      bannerPaint,
    );

    final titlePainter = TextPainter(
      text: TextSpan(
        text: '🐾 ${topText.toUpperCase()}',
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.07,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    titlePainter.layout(maxWidth: width * 0.9);
    titlePainter.paint(
      canvas,
      Offset(
        (width - titlePainter.width) / 2,
        height * 0.06,
      ),
    );

    final watermarkPainter = TextPainter(
      text: TextSpan(
        text: watermarkText,
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.04,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    watermarkPainter.layout();
    watermarkPainter.paint(
      canvas,
      Offset(
        width - watermarkPainter.width - 24,
        height - watermarkPainter.height - 24,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      originalImage.width,
      originalImage.height,
    );

    final byteData = await img.toByteData(
      format: ui.ImageByteFormat.png,
    );

    final file = File(
      '${(await getTemporaryDirectory()).path}/$fileName.png',
    );

    await file.writeAsBytes(byteData!.buffer.asUint8List());

    return file;
  }

  static Future<void> sharePost({
    required String imageUrl,
    required String postType,
    required String fileName,
  }) async {
    final file = await createImageWithTexts(
      imageUrl: imageUrl,
      topText: postType,
      watermarkText: '🐾 WeBaNiMaL',
      fileName: fileName,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '🐾 @WeBaNiMaL',
    );
  }
}