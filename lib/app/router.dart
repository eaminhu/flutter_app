import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/domain/session.dart';
import '../core/providers/session_provider.dart';
import '../modules/assets/assets_screen.dart';
import '../modules/prediction/detail/event_detail_screen.dart';
import '../shell/trade/trade_home_screen.dart';
import '../shell/layout/app_shell.dart';
import '../shell/settings/settings_screen.dart';
import '../shell/auth/login_screen.dart';
import '../shell/auth/register_screen.dart';
import '../shell/auth/account_screen.dart';
import '../design_system/primitives/page_status.dart';
import 'localization/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionStateProvider, (old, next) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/spot',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionStateProvider);
      final authenticated = session.status == SessionStatus.authenticated;
      if (state.uri.path == '/login' && authenticated) return '/account';
      if (state.uri.path == '/register' && authenticated) return '/account';
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/spot'),
      // Full-screen event detail, outside the shell (own back bar).
      GoRoute(
        path: '/prediction/:eventId',
        builder: (context, state) =>
            EventDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/spot',
            builder: (context, state) => const TradeHomeScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/account',
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: '/placeholder',
            builder: (context, state) => PageStatus(
              key: const Key('placeholderScreen'),
              message: AppLocalizations.of(context).text(AppText.comingSoon),
              icon: Icons.rocket_launch_outlined,
            ),
          ),
          GoRoute(
            path: '/assets',
            builder: (context, state) => const AssetsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => PageStatus(
      message: AppLocalizations.of(context).text(AppText.notFound),
      icon: Icons.search_off_outlined,
    ),
  );
  ref.onDispose(router.dispose);
  ref.onDispose(refresh.dispose);
  return router;
});
