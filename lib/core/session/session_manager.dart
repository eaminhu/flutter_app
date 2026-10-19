import 'dart:async';
import 'dart:developer' as developer;

import '../api/errors.dart';
import '../domain/session.dart';
import '../storage/session_store.dart';

class SessionManager {
  SessionManager({required this.store, required this.scope});
  final SessionStore store;
  final String scope;
  final _changes = StreamController<SessionSnapshot>.broadcast(sync: true);
  Stream<SessionSnapshot> get changes => _changes.stream;
  SessionSnapshot _snapshot = const SessionSnapshot(SessionStatus.anonymous);
  SessionSnapshot get snapshot => _snapshot;
  AuthSession? _credentials;
  AuthSession? get credentials => _credentials;
  int _generation = 0;
  int get generation => _generation;
  bool _disposed = false;
  Future<void> _writes = Future.value();
  void _emit(SessionSnapshot value) {
    if (_disposed) return;
    _snapshot = SessionSnapshot(
      value.status,
      identity: value.identity,
      error: value.error,
      generation: _generation,
    );
    _changes.add(_snapshot);
  }

  Future<void> _write(AuthSession? value) {
    final result = _writes.then((_) => store.write(scope, value));
    _writes = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        developer.log(
          'Credential storage failed.',
          name: 'nexus.session',
          error: error.runtimeType,
          stackTrace: stack,
        );
      },
    );
    return result;
  }

  PlatformError _failure(Object error) => error is PlatformError
      ? error
      : const PlatformError(
          PlatformErrorCode.unexpected,
          'Session operation failed.',
        );
  void _ensureCurrent(int epoch) {
    if (_disposed || epoch != _generation) {
      throw const PlatformError(
        PlatformErrorCode.requestCancelled,
        'Session operation was superseded.',
      );
    }
  }

  Future<void> restore(Future<AccountIdentity> Function() loadIdentity) async {
    final epoch = ++_generation;
    _credentials = null;
    _emit(const SessionSnapshot(SessionStatus.restoring));
    try {
      final saved = await store.read(scope);
      if (epoch != _generation || _disposed) return;
      if (saved == null) {
        _emit(const SessionSnapshot(SessionStatus.anonymous));
        return;
      }
      if (saved.expiresAt?.isBefore(DateTime.now().toUtc()) == true) {
        await invalidate(epoch);
        return;
      }
      _credentials = saved;
      final identity = await loadIdentity();
      if (epoch != _generation || _disposed) return;
      _emit(SessionSnapshot(SessionStatus.authenticated, identity: identity));
    } catch (error, stack) {
      if (epoch != _generation || _disposed) return;
      _generation++;
      _credentials = null;
      developer.log(
        'Session restore failed.',
        name: 'nexus.session',
        error: error.runtimeType,
        stackTrace: stack,
      );
      _emit(SessionSnapshot(SessionStatus.failure, error: _failure(error)));
    }
  }

  Future<void> signIn(
    Future<AuthSession> Function() authenticate,
    Future<AccountIdentity> Function() loadIdentity,
  ) async {
    final epoch = ++_generation;
    _credentials = null;
    _emit(const SessionSnapshot(SessionStatus.authenticating));
    try {
      await _write(null);
      _ensureCurrent(epoch);
      final credentials = await authenticate();
      _ensureCurrent(epoch);
      if (credentials.accessToken.trim().isEmpty) {
        throw const PlatformError(
          PlatformErrorCode.responseMalformed,
          'Login did not provide credentials.',
        );
      }
      if (credentials.expiresAt?.isBefore(DateTime.now().toUtc()) == true) {
        throw const PlatformError(
          PlatformErrorCode.authTokenExpired,
          'Login credentials have already expired.',
        );
      }
      _credentials = credentials;
      final identity = await loadIdentity();
      _ensureCurrent(epoch);
      await _write(credentials);
      _ensureCurrent(epoch);
      _emit(SessionSnapshot(SessionStatus.authenticated, identity: identity));
    } catch (error, stack) {
      if (epoch == _generation && !_disposed) {
        final retired = ++_generation;
        _credentials = null;
        try {
          await _write(null);
        } catch (cleanupError) {
          developer.log(
            'Credential cleanup failed.',
            name: 'nexus.session',
            error: cleanupError.runtimeType,
          );
        }
        if (retired == _generation) {
          _emit(SessionSnapshot(SessionStatus.failure, error: _failure(error)));
        }
      }
      developer.log(
        'Sign-in failed.',
        name: 'nexus.session',
        error: error.runtimeType,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    final epoch = ++_generation;
    _credentials = null;
    _emit(const SessionSnapshot(SessionStatus.anonymous));
    try {
      await _write(null);
    } catch (error) {
      if (epoch == _generation && !_disposed) {
        _emit(SessionSnapshot(SessionStatus.failure, error: _failure(error)));
      }
      rethrow;
    }
  }

  Future<bool> invalidate(int epoch) async {
    if (epoch != _generation || _disposed) return false;
    await signOut();
    return true;
  }

  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    _credentials = null;
    await _changes.close();
  }
}
