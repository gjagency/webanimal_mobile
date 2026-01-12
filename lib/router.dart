import 'package:go_router/go_router.dart';
import 'package:mobile_app/pages/auth/PageEditProfile.dart';

import 'package:mobile_app/service/auth_service.dart';

// AUTH
import 'package:mobile_app/pages/auth/sign_in.dart';
import 'package:mobile_app/pages/auth/sign_up.dart';
import 'package:mobile_app/pages/auth/otp.dart';
import 'package:mobile_app/pages/auth/reset_password.dart';
import 'package:mobile_app/pages/auth/recover.dart';

// HOME
import 'package:mobile_app/pages/splash.dart';
import 'package:mobile_app/pages/home/home.dart';

// ACCOUNT
import 'package:mobile_app/pages/account/settings.dart';
import 'package:mobile_app/pages/account/notifications.dart';

// POSTS
import 'package:mobile_app/pages/posts/create.dart';
import 'package:mobile_app/pages/posts/view.dart';

// PROFILES
import 'package:mobile_app/pages/profiles/public.dart';

final router = GoRouter(
  initialLocation: '/splash',

  routes: [
    /* =========================
       SPLASH
       ========================= */
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),

    /* =========================
       AUTH RECOVER
       ========================= */
    GoRoute(
      path: '/auth/recover',
      builder: (context, state) => const PageAuthRecover(),
    ),

    /* =========================
       HOME
       ========================= */
    GoRoute(path: '/home', builder: (context, state) => const PageHome()),

    /* =========================
       AUTH
       ========================= */
    GoRoute(
      path: '/auth/sign_in',
      builder: (context, state) => const PageAuthSignIn(),
    ),
    GoRoute(
      path: '/auth/sign_up',
      builder: (context, state) => const PageAuthSignUp(),
    ),
    GoRoute(
      path: '/auth/otp',
      builder: (context, state) => const PageAuthOTP(),
    ),

    // 🔐 RESET PASSWORD (con uid + token)
    GoRoute(
      path: '/auth/reset_password',
      builder: (context, state) {
        final uid = state.uri.queryParameters['uid'];
        final token = state.uri.queryParameters['token'];

        if (uid == null || token == null) {
          return const PageAuthSignIn();
        }

        return ResetPasswordPage(uid: uid, token: token);
      },
    ),

    /* =========================
       ACCOUNT
       ========================= */
    GoRoute(
      path: '/account/settings',
      builder: (context, state) => const PageAccountSettings(),
    ),
    GoRoute(
      path: '/account/notifications',
      builder: (context, state) => const PageAccountNotifications(),
    ),

    /* =========================
       PROFILES
       ========================= */
    GoRoute(
      path: '/profiles/:username',
      builder: (context, state) {
        final username = state.pathParameters['username']!;
        return PageProfilesPublic(username: username);
      },
    ),

    /* =========================
       POSTS
       ========================= */
    GoRoute(
      path: '/posts/create',
      builder: (context, state) => PagePostCreate(),
    ),
    GoRoute(
      path: '/posts/:id/view',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PagePostView(postId: id);
      },
      
    ),
        GoRoute(
      path: '/api/auth/profile',
      builder: (context, state) => const PageEditProfile(),
    ),
  ],

  /* =========================
     REDIRECT GLOBAL
     ========================= */
  redirect: (context, state) async {
    final token = await AuthService.getAccessToken();
    final location = state.matchedLocation;

    final isSplash = location == '/splash';
    final isReset = location.startsWith('/auth/reset_password');
    final isRecover = location == '/auth/recover';
    final isAuthRoute = location.startsWith('/auth');

    // 👉 Splash, Reset y Recover siempre permitidos
    if (isSplash || isReset || isRecover) return null;

    // 👉 No logueado → fuera de auth
    if (token == null && !isAuthRoute) {
      return '/auth/sign_in';
    }

    // 👉 Logueado → evitar auth (menos reset)
    if (token != null && isAuthRoute && !isReset) {
      return '/';
    }
    

    return null;
  },
);
