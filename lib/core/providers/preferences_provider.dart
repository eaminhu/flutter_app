import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/preferences.dart';
import '../storage/preferences_store.dart';

final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => MemoryPreferencesStore(),
);
final initialPreferencesProvider = Provider<AppPreferences>(
  (ref) => const AppPreferences(),
);
final preferencesProvider =
    NotifierProvider<PreferencesController, AppPreferences>(
      PreferencesController.new,
    );

class PreferencesController extends Notifier<AppPreferences> {
  Future<void> _writes = Future.value();
  late AppPreferences _desired;
  @override
  AppPreferences build() {
    _desired = ref.watch(initialPreferencesProvider);
    return _desired;
  }

  Future<void> _save(AppPreferences next) {
    _desired = next;
    final store = ref.read(preferencesStoreProvider);
    final operation = _writes.then((_) async {
      await store.write(next);
      state = next;
    });
    _writes = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        developer.log(
          'Preference write failed.',
          name: 'nexus.preferences',
          error: error.runtimeType,
          stackTrace: stack,
        );
      },
    );
    return operation;
  }

  Future<void> selectLanguage(AppLanguage language) =>
      _save(AppPreferences(language: language, theme: _desired.theme));
  Future<void> selectTheme(AppTheme theme) =>
      _save(AppPreferences(language: _desired.language, theme: theme));
}
