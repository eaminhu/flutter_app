import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../core/domain/preferences.dart';
import '../core/providers/preferences_provider.dart';
import '../core/providers/platform_provider.dart';
import '../design_system/primitives/page_status.dart';
import '../modules/prediction/detail/event_detail_view_model.dart';
import 'localization/app_localizations.dart';
import 'router.dart';
import '../design_system/theme/app_theme.dart';

class NexusApp extends ConsumerStatefulWidget {
  const NexusApp({super.key});

  @override
  ConsumerState<NexusApp> createState() => _NexusAppState();
}

class _NexusAppState extends ConsumerState<NexusApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // App resume: reconnect a dead realtime socket and re-align the open
    // event detail with a fresh REST read.
    ref.read(platformApiProvider).realtime.revalidate();
    ref.invalidate(eventDetailProvider);
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesProvider);
    final startupError = ref.watch(startupErrorProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context).text(AppText.appName),
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: switch (preferences.theme) {
        AppTheme.system => ThemeMode.system,
        AppTheme.light => ThemeMode.light,
        AppTheme.dark => ThemeMode.dark,
      },
      locale: preferences.language == null
          ? null
          : localeFor(preferences.language!),
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: resolveAppLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...FLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => FTheme(
        data: Theme.of(context).brightness == Brightness.dark
            ? FTheme.neutral.dark.touch
            : FTheme.neutral.light.touch,
        child: startupError == null
            ? FToaster(child: child!)
            : PageStatus(
                message: AppLocalizations.of(context)
                    .text(AppText.storageFailed),
                icon: Icons.error_outline,
              ),
      ),
    );
  }
}
