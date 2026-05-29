import 'package:flutter/material.dart';

import 'package:mobile_app/app.dart';
import 'package:mobile_app/config.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Config.load();

  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;

  await initializeDateFormatting('es_ES', null);

  runApp(const App());
}