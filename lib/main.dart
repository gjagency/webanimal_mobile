import 'package:flutter/material.dart';

import 'package:mobile_app/app.dart';
import 'package:mobile_app/config.dart';

void main() async {
  await Config.load();

  WidgetsFlutterBinding.ensureInitialized();

  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;

  runApp(const App());
}
