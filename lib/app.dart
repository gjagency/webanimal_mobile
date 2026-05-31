import 'package:flutter/material.dart';
import 'package:mobile_app/deep_links_handler.dart';
import 'package:mobile_app/router.dart';
import 'package:mobile_app/widgets/UpdaterPopup.dart';
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.init();
    });
  }

  @override
  void dispose() {
    DeepLinkHandler.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  print("🚀🚀🚀🚀 APP BUILD");

return MaterialApp.router(
  routerConfig: router,
  builder: (context, child) {
    return UpdaterPopup(
      child: child,
    );
  },
);
}
}
