import 'package:go_router/go_router.dart';
import 'package:mobile_app/pages/splash.dart';
import 'package:mobile_app/service/auth_service.dart';

import 'package:mobile_app/pages/home/home.dart';
import 'package:mobile_app/pages/auth/otp.dart';
import 'package:mobile_app/pages/auth/recover.dart';
import 'package:mobile_app/pages/auth/sign_in.dart';
import 'package:mobile_app/pages/auth/sign_up.dart';
import 'package:mobile_app/pages/account/settings.dart';
import 'package:mobile_app/pages/account/notifications.dart';
import 'package:mobile_app/pages/posts/edit.dart';
import 'package:mobile_app/pages/posts/view.dart';
import 'package:mobile_app/pages/profiles/public.dart';
final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),

    // HOME
    GoRoute(
      path: '/',
      builder: (ctx, state) => const PageHome(),
    ),

    // AUTH
    GoRoute(path: '/auth/sign_in', builder: (ctx, state) => const PageAuthSignIn()),
    GoRoute(path: '/auth/sign_up', builder: (ctx, state) => const PageAuthSignUp()),
    GoRoute(path: '/auth/recover', builder: (ctx, state) => const PageAuthRecover()),
    GoRoute(path: '/auth/otp', builder: (ctx, state) => const PageAuthOTP()),

    // ACCOUNT
    GoRoute(path: '/account/settings', builder: (ctx, state) => const PageAccountSettings()),
    GoRoute(path: '/account/notifications', builder: (ctx, state) => const PageAccountNotifications()),

    // PROFILES
    GoRoute(
      path: '/profiles/:username',
      builder: (ctx, state) {
        final username = state.pathParameters['username']!;
        return PageProfilesPublic(username: username);
      },
    ),

    // POSTS
    GoRoute(
      path: '/posts/:id/edit',
      builder: (ctx, state) {
        final id = state.pathParameters['id']!;
        return PagePostEdit(postId: id);
      },
    ),
    GoRoute(
      path: '/posts/:id/view',
      builder: (ctx, state) {
        final id = state.pathParameters['id']!;
        return PagePostView(postId: id);
      },
    ),
  ],

  redirect: (context, state) async {
    final token = await AuthService.getToken();

    final loggingIn = state.matchedLocation.startsWith('/auth');

    if (token == null && !loggingIn) {
      // Si no hay token y no estamos en login → redirige a login
      return '/auth/sign_in';
    }

    if (token != null && loggingIn) {
      // Si hay token y estamos en login → redirige a home
      return '/';
    }

    return null; // no redirige
  },
);
