import 'package:go_router/go_router.dart';

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
  initialLocation: "/",
  routes: [
    GoRoute(path: '/', builder: (ctx, state) => PageHome()),

    GoRoute(path: '/auth/otp', builder: (ctx, state) => PageAuthOTP()),
    GoRoute(path: '/auth/recover', builder: (ctx, state) => PageAuthRecover()),
    GoRoute(path: '/auth/sign_in', builder: (ctx, state) => PageAuthSignIn()),
    GoRoute(path: '/auth/sign_up', builder: (ctx, state) => PageAuthSignUp()),

    GoRoute(
      path: '/account/settings',
      builder: (context, state) => PageAccountSettings(),
    ),
    GoRoute(
      path: '/account/notifications',
      builder: (context, state) => PageAccountNotifications(),
    ),
    GoRoute(
      path: '/profiles/:username',
      builder: (context, state) {
        final username = state.pathParameters['username']!;
        return PageProfilesPublic(username: username);
      },
    ),
    GoRoute(
      path: '/posts/:id/edit',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PagePostEdit(postId: id);
      },
    ),
    GoRoute(
      path: '/posts/:id/view',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PagePostView(postId: id);
      },
    ),
  ],
);
