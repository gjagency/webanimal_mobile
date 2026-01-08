import 'package:flutter/material.dart';

import 'package:mobile_app/app.dart';
import 'package:mobile_app/config.dart';

void main() async {
  await Config.load();

  runApp(const App());
}
