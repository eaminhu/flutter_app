import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  // Selected tab is computed from a location whitelist; unmatched locations
  // (e.g. /placeholder, /settings, /login) highlight nothing.
  static int _indexFor(String location) => switch (location) {
    '/spot' => 1,
    '/assets' => 2,
    '/account' => 3,
    _ => -1,
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    // Labels follow the caption scale (12/1.35); the selected tab reads
    // primary + w600. Icon size (24) and colors come from the Forui style.
    final itemStyle = FBottomNavigationBarItemStyleDelta.delta(
      textStyle: FVariantsDelta.delta([
        FVariantOperation.all(
          const TextStyleDelta.delta(fontSize: 12, height: 1.35),
        ),
        FVariantOperation.match(
          {FTappableVariant.selected},
          const TextStyleDelta.delta(fontWeight: FontWeight.w600),
        ),
      ]),
    );
    return FScaffold(
      footer: FBottomNavigationBar(
        index: _indexFor(location),
        onChange: (index) => context.go(
          switch (index) {
            0 => '/placeholder',
            1 => '/spot',
            2 => '/assets',
            _ => '/account',
          },
        ),
        children: [
          FBottomNavigationBarItem(
            key: const Key('homeTab'),
            style: itemStyle,
            icon: const Icon(FLucideIcons.house),
            label: Text(strings.text(AppText.home)),
          ),
          FBottomNavigationBarItem(
            key: const Key('spotTab'),
            style: itemStyle,
            icon: const Icon(FLucideIcons.chartNoAxesCombined),
            label: Text(strings.text(AppText.trade)),
          ),
          FBottomNavigationBarItem(
            key: const Key('assetsTab'),
            style: itemStyle,
            icon: const Icon(FLucideIcons.wallet),
            label: Text(strings.text(AppText.assets)),
          ),
          FBottomNavigationBarItem(
            key: const Key('profileTab'),
            style: itemStyle,
            icon: const Icon(FLucideIcons.userRound),
            label: Text(strings.text(AppText.profile)),
          ),
        ],
      ),
      child: SafeArea(bottom: false, child: child),
    );
  }
}
