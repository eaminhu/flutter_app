import 'dart:convert';

import '../api/errors.dart';
import '../domain/preferences.dart';

abstract interface class PreferencesStore {
  Future<AppPreferences> read();
  Future<void> write(AppPreferences value);
}

class MemoryPreferencesStore implements PreferencesStore {
  AppPreferences _value = const AppPreferences();
  @override
  Future<AppPreferences> read() async => _value;
  @override
  Future<void> write(AppPreferences value) async {
    _value = value;
  }
}

String encodePreferences(AppPreferences value) =>
    jsonEncode({'language': value.language?.name, 'theme': value.theme.name});
AppPreferences decodePreferences(String value) {
  try {
    final data = jsonDecode(value);
    if (data is! Map<String, dynamic> || !data.containsKey('language')) {
      throw const FormatException();
    }
    final theme = AppTheme.values
        .where((e) => e.name == data['theme'])
        .firstOrNull;
    final language = data['language'] == null
        ? null
        : AppLanguage.values
              .where((e) => e.name == data['language'])
              .firstOrNull;
    if (theme == null || (data['language'] != null && language == null)) {
      throw const FormatException();
    }
    return AppPreferences(language: language, theme: theme);
  } catch (_) {
    throw const PlatformError(
      PlatformErrorCode.responseMalformed,
      'Stored preferences are malformed.',
    );
  }
}
