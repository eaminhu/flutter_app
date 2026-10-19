import 'dart:convert';

import '../api/errors.dart';
import '../domain/session.dart';

abstract interface class SessionStore {
  Future<AuthSession?> read(String scope);
  Future<void> write(String scope, AuthSession? value);
}

// Used by isolated provider/widget tests; main always injects the native store.
class MemorySessionStore implements SessionStore {
  final _values = <String, AuthSession>{};
  @override
  Future<AuthSession?> read(String scope) async => _values[scope];
  @override
  Future<void> write(String scope, AuthSession? value) async {
    if (value == null) {
      _values.remove(scope);
    } else {
      _values[scope] = value;
    }
  }
}

String encodeSession(AuthSession value) => jsonEncode({
  'accessToken': value.accessToken,
  'expiresAt': value.expiresAt?.toUtc().toIso8601String(),
});
AuthSession decodeSession(String value) {
  try {
    final data = jsonDecode(value);
    if (data is! Map<String, dynamic> ||
        data['accessToken'] is! String ||
        (data['accessToken'] as String).trim().isEmpty ||
        !data.containsKey('expiresAt')) {
      throw const FormatException();
    }
    final raw = data['expiresAt'];
    final expiry = raw == null
        ? null
        : (raw is String ? DateTime.tryParse(raw)?.toUtc() : null);
    if (raw != null && expiry == null) throw const FormatException();
    return AuthSession(
      accessToken: data['accessToken'] as String,
      expiresAt: expiry,
    );
  } catch (_) {
    throw const PlatformError(
      PlatformErrorCode.responseMalformed,
      'Stored credentials are malformed.',
    );
  }
}
