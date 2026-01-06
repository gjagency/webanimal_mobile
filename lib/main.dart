// main.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Páginas
import 'package:mobile_app/pages/splash.dart';
import 'package:mobile_app/pages/auth/sign_in.dart';
import 'package:mobile_app/pages/home/home.dart';
import 'package:mobile_app/pages/account/settings.dart';

void main() {
  runApp(const MyApp());
}

// Configuración de rutas
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/auth/sign_in',
      builder: (context, state) => const PageAuthSignIn(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const PageHome(),
    ),
    GoRoute(
      path: '/account/settings',
      builder: (context, state) => const PageAccountSettings(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'WeBaNiMaL',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.light,
      ),
      routerConfig: _router,
    );
  }
}
