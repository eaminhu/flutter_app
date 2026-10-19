// Dedicated native-storage verification entry point; never used by lib/main.dart.
import 'package:flutter/material.dart';

import 'package:flutter_nexusft/core/domain/session.dart';
import 'package:flutter_nexusft/core/domain/preferences.dart';
import 'package:flutter_nexusft/core/storage/native_stores.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const mode = String.fromEnvironment('STORAGE_PROBE', defaultValue: 'read');
  final sessions = SecureSessionStore();
  final prefs = SharedPreferencesStore(key: 'nexus.preferences.probe.v1');
  var passed = false;
  try {
    if (mode == 'write') {
      await sessions.write(
        'nexus-native-storage-probe-v1',
        const AuthSession(accessToken: 'non-account-fixture', expiresAt: null),
      );
      await prefs.write(
        const AppPreferences(language: AppLanguage.zhTw, theme: AppTheme.dark),
      );
    } else {
      final value = await sessions.read('nexus-native-storage-probe-v1');
      final preferences = await prefs.read();
      if (value?.accessToken != 'non-account-fixture' ||
          value?.expiresAt != null ||
          preferences.language != AppLanguage.zhTw ||
          preferences.theme != AppTheme.dark) {
        throw StateError('Native storage did not survive restart.');
      }
    }
    passed = true;
    debugPrint('NEXUS_NATIVE_STORAGE:${mode.toUpperCase()}_PASS');
  } catch (error) {
    debugPrint(
      'NEXUS_NATIVE_STORAGE:${mode.toUpperCase()}_FAIL ${error.runtimeType}',
    );
  }
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            passed
                ? 'Native storage probe passed'
                : 'Native storage probe failed',
          ),
        ),
      ),
    ),
  );
}
