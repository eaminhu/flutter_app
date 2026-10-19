import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adapters/unconfigured/unconfigured_adapter.dart';
import '../adapters/v1/v1_adapter.dart';
import '../api/contract.dart';
import '../api/errors.dart';
import '../config/app_config.dart';
import '../domain/preferences.dart';
import '../http/dio_http.dart';
import 'preferences_provider.dart';
import 'session_provider.dart';

final startupErrorProvider = Provider<PlatformError?>((ref) => null);
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromValue(
    const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
  ),
);
final platformApiProvider = Provider<PlatformApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.apiBaseUrl == null) return const UnconfiguredAdapter();
  final http = DioHttp(
    baseUrl: config.apiBaseUrl!,
    session: ref.watch(sessionManagerProvider),
    locale: () {
      final prefs = ref.read(preferencesProvider);
      final system = WidgetsBinding.instance.platformDispatcher.locale;
      return languageHeader(
        prefs.language ??
            languageForTags(
              system.languageCode,
              scriptCode: system.scriptCode,
              countryCode: system.countryCode,
            ),
      );
    },
  );
  ref.onDispose(http.close);
  return V1Adapter(http);
});
