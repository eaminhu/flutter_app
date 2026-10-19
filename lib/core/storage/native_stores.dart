import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/errors.dart';
import '../domain/preferences.dart';
import '../domain/session.dart';
import 'preferences_store.dart';
import 'session_store.dart';

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  @override
  Future<AuthSession?> read(String scope) async {
    try {
      final value = await _storage.read(key: scope);
      return value == null ? null : decodeSession(value);
    } on PlatformError {
      rethrow;
    } catch (_) {
      throw const PlatformError(
        PlatformErrorCode.storageFailed,
        'Unable to read secure credentials.',
      );
    }
  }

  @override
  Future<void> write(String scope, AuthSession? value) async {
    try {
      if (value == null) {
        await _storage.delete(key: scope);
      } else {
        await _storage.write(key: scope, value: encodeSession(value));
      }
    } catch (_) {
      throw const PlatformError(
        PlatformErrorCode.storageFailed,
        'Unable to update secure credentials.',
      );
    }
  }
}

class SharedPreferencesStore implements PreferencesStore {
  SharedPreferencesStore({this.key = 'nexus.preferences.v1'})
    : _storage = SharedPreferencesAsync();
  final String key;
  final SharedPreferencesAsync _storage;
  @override
  Future<AppPreferences> read() async {
    try {
      final value = await _storage.getString(key);
      return value == null ? const AppPreferences() : decodePreferences(value);
    } on PlatformError {
      rethrow;
    } catch (_) {
      throw const PlatformError(
        PlatformErrorCode.storageFailed,
        'Unable to read preferences.',
      );
    }
  }

  @override
  Future<void> write(AppPreferences value) async {
    try {
      await _storage.setString(key, encodePreferences(value));
    } catch (_) {
      throw const PlatformError(
        PlatformErrorCode.storageFailed,
        'Unable to update preferences.',
      );
    }
  }
}
