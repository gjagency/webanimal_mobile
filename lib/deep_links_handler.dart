import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:mobile_app/router.dart';

class DeepLinkHandler {
  static late final AppLinks _appLinks;
  static StreamSubscription? _linkSubscription;

  static void init() {
    _appLinks = AppLinks();

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(uri);
        });
      }
    });

    _linkSubscription = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  static void _handleDeepLink(Uri uri) {
    final nextUri = Uri(path: uri.path, queryParameters: uri.queryParameters);
    print(nextUri.toString());
    router.go(nextUri.toString());
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }
}
