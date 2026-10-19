import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/nexus_app.dart';
import 'core/api/errors.dart';
import 'core/config/app_config.dart';
import 'core/domain/preferences.dart';
import 'core/providers/platform_provider.dart';
import 'core/providers/preferences_provider.dart';
import 'core/providers/session_provider.dart';
import 'core/providers/platform_error_observer.dart';
import 'core/session/session_manager.dart';
import 'core/storage/native_stores.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const environment = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  const suppliedBase = String.fromEnvironment('API_BASE_URL');
  final config = AppConfig.fromValues(
    environment,
    suppliedBase.isEmpty && environment == 'dev'
        ? 'https://dev-nexusft-trade-api.nexuspb.com'
        : suppliedBase,
  );
  final preferencesStore = SharedPreferencesStore();
  AppPreferences preferences = const AppPreferences();
  PlatformError? startupError;
  try {
    preferences = await preferencesStore.read();
  } catch (error, stack) {
    developer.log(
      'Preference initialization failed.',
      name: 'nexus.bootstrap',
      error: error.runtimeType,
      stackTrace: stack,
    );
    startupError = error is PlatformError
        ? error
        : const PlatformError(
            PlatformErrorCode.storageFailed,
            'Local initialization failed.',
          );
  }
  final session = SessionManager(
    store: SecureSessionStore(),
    scope: config.sessionScope,
  );
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      preferencesStoreProvider.overrideWithValue(preferencesStore),
      initialPreferencesProvider.overrideWithValue(preferences),
      sessionManagerProvider.overrideWithValue(session),
      startupErrorProvider.overrideWithValue(startupError),
    ],
    observers: [PlatformErrorObserver()],
  );
  if (startupError == null) {
    unawaited(
      session.restore(() => container.read(platformApiProvider).auth.me()),
    );
  }
  runApp(
    UncontrolledProviderScope(container: container, child: const NexusApp()),
  );
}
