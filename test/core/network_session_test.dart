import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_nexusft/core/api/errors.dart';
import 'package:flutter_nexusft/core/config/app_config.dart';
import 'package:flutter_nexusft/core/domain/session.dart';
import 'package:flutter_nexusft/core/domain/market.dart';
import 'package:flutter_nexusft/core/domain/preferences.dart';
import 'package:flutter_nexusft/core/session/session_manager.dart';
import 'package:flutter_nexusft/core/storage/session_store.dart';
import 'package:flutter_nexusft/core/storage/preferences_store.dart';
import 'package:flutter_nexusft/core/http/dio_http.dart';
import 'package:flutter_nexusft/core/adapters/v1/v1_adapter.dart';

class MemorySessions implements SessionStore {
  final values = <String, AuthSession>{};
  @override
  Future<AuthSession?> read(String scope) async => values[scope];
  @override
  Future<void> write(String scope, AuthSession? value) async {
    if (value == null) {
      values.remove(scope);
    } else {
      values[scope] = value;
    }
  }
}

const first = AuthSession(accessToken: 'fixture-first', expiresAt: null);
const second = AuthSession(accessToken: 'fixture-second', expiresAt: null);
const identity = AccountIdentity(accountId: 'fixture-account');

void main() {
  test(
    'system Hans overrides region TW consistently for UI and request header',
    () {
      final language = languageForTags(
        'zh',
        scriptCode: 'Hans',
        countryCode: 'TW',
      );
      expect(language, AppLanguage.zhCn);
      expect(languageHeader(language), 'zh-CN');
      expect(
        languageForTags('zh', scriptCode: 'Hant', countryCode: 'HK'),
        AppLanguage.zhTw,
      );
    },
  );

  test(
    'login uses multipart fields and confirms identity before authenticating',
    () async {
      final store = MemorySessions();
      final manager = SessionManager(store: store, scope: 'dev');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
        await manager.dispose();
      });
      String? contentType, body, meToken;
      server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/uc/login_auth_data') {
          contentType = request.headers.value('content-type');
          body = await utf8.decoder.bind(request).join();
          request.response.write(
            '{"code":0,"data":{"token":"fixture-issued"}}',
          );
        } else {
          meToken = request.headers.value('x-auth-token');
          request.response.write('{"code":0,"data":{"uid":42}}');
        }
        await request.response.close();
      });
      final http = DioHttp(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        session: manager,
        locale: () => 'en-US',
      );
      addTearDown(http.close);
      final api = V1Adapter(http);
      await manager.signIn(
        () => api.auth.login(
          username: 'fixture-user',
          password: 'fixture-password',
        ),
        api.auth.me,
      );
      expect(contentType, startsWith('multipart/form-data'));
      expect(body, contains('name="username"'));
      expect(body, contains('fixture-user'));
      expect(body, contains('name="password"'));
      expect(meToken, 'fixture-issued');
      expect(manager.snapshot.identity?.accountId, '42');
      expect(store.values['dev']?.expiresAt, isNull);
    },
  );

  test('receive timeout stays a typed failure', () async {
    final manager = SessionManager(store: MemorySessions(), scope: 'dev');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
      await manager.dispose();
    });
    server.listen((request) {});
    final http = DioHttp(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      session: manager,
      locale: () => 'en-US',
      receiveTimeout: const Duration(milliseconds: 40),
    );
    addTearDown(http.close);
    await expectLater(
      http.request('/slow'),
      throwsA(
        predicate(
          (e) =>
              e is PlatformError && e.code == PlatformErrorCode.requestTimeout,
        ),
      ),
    );
  });

  test(
    'failed restore retires staged credentials and its request generation',
    () async {
      final store = MemorySessions()..values['dev'] = first;
      final manager = SessionManager(store: store, scope: 'dev');
      addTearDown(manager.dispose);
      final gate = Completer<AccountIdentity>();
      final restore = manager.restore(() => gate.future);
      await Future<void>.delayed(Duration.zero);
      final staged = manager.generation;
      gate.completeError(
        const PlatformError(PlatformErrorCode.networkUnreachable, 'fixture'),
      );
      await restore;
      expect(manager.generation, greaterThan(staged));
      expect(manager.credentials, isNull);
      expect(manager.snapshot.status, SessionStatus.failure);
    },
  );
  test(
    'already expired login credentials are rejected before persistence',
    () async {
      final store = MemorySessions();
      final manager = SessionManager(store: store, scope: 'dev');
      addTearDown(manager.dispose);
      await expectLater(
        manager.signIn(
          () async => AuthSession(
            accessToken: 'fixture',
            expiresAt: DateTime.utc(2000),
          ),
          () async => identity,
        ),
        throwsA(
          predicate(
            (e) =>
                e is PlatformError &&
                e.code == PlatformErrorCode.authTokenExpired,
          ),
        ),
      );
      expect(store.values['dev'], isNull);
    },
  );

  test(
    'configuration rejects unsafe URL and isolates host/environment scopes',
    () {
      final dev = AppConfig.fromValues('dev', 'https://dev.example.test');
      final uat = AppConfig.fromValues('uat', 'https://dev.example.test');
      final other = AppConfig.fromValues('dev', 'https://other.example.test');
      expect(dev.sessionScope, isNot(uat.sessionScope));
      expect(dev.sessionScope, isNot(other.sessionScope));
      for (final value in [
        'http://dev.example.test',
        'https://u:p@example.test',
        'https://example.test?q=secret',
        '//example.test',
      ]) {
        expect(() => AppConfig.fromValues('dev', value), throwsFormatException);
      }
    },
  );

  test(
    'catalog preserves symbols and ID, disabled listing remains visible',
    () {
      final items = decodeSpotMarkets([
        {'symbol': 'BTC/USDT', 'enable': 1},
        {'symbol': 'ETH/USDT', 'enable': 2},
        {'symbol': 'HIDDEN/USDT', 'enable': 0},
      ]);
      expect(items.map((m) => m.symbol), ['BTC/USDT', 'ETH/USDT']);
      expect(items.first.marketId, 'BTC-USDT');
      expect(
        () => decodeSpotMarkets({'code': 500}),
        throwsA(isA<PlatformError>()),
      );
      expect(
        () => decodeSpotMarkets([
          {'enable': 1},
        ]),
        throwsA(isA<PlatformError>()),
      );
      expect(
        () => decodeSpotMarkets([
          {'symbol': 'BTC/USDT', 'enable': 'bad'},
        ]),
        throwsA(isA<PlatformError>()),
      );
    },
  );

  test('delayed restore cannot resurrect credentials after logout', () async {
    final store = MemorySessions()..values['dev'] = first;
    final manager = SessionManager(store: store, scope: 'dev');
    addTearDown(manager.dispose);
    final gate = Completer<AccountIdentity>();
    final restoring = manager.restore(() => gate.future);
    await Future<void>.delayed(Duration.zero);
    await manager.signOut();
    gate.complete(identity);
    await restoring;
    expect(manager.snapshot.status, SessionStatus.anonymous);
    expect(manager.credentials, isNull);
    expect(store.values['dev'], isNull);
  });

  test(
    'old request rejection does not clear newer authenticated session',
    () async {
      final store = MemorySessions();
      final manager = SessionManager(store: store, scope: 'dev');
      addTearDown(manager.dispose);
      await manager.signIn(() async => first, () async => identity);
      final old = manager.generation;
      await manager.signIn(() async => second, () async => identity);
      expect(await manager.invalidate(old), isFalse);
      expect(manager.credentials?.accessToken, second.accessToken);
      expect(manager.snapshot.status, SessionStatus.authenticated);
      expect(store.values['dev']?.accessToken, second.accessToken);
    },
  );

  test('failed identity confirmation never persists a login token', () async {
    final store = MemorySessions();
    final manager = SessionManager(store: store, scope: 'dev');
    addTearDown(manager.dispose);
    await expectLater(
      manager.signIn(
        () async => first,
        () async =>
            throw const PlatformError(PlatformErrorCode.unexpected, 'fixture'),
      ),
      throwsA(isA<PlatformError>()),
    );
    expect(manager.snapshot.status, SessionStatus.failure);
    expect(manager.credentials, isNull);
    expect(store.values['dev'], isNull);
  });

  test(
    'preference codec round trips nullable language and rejects unknown values',
    () {
      const value = AppPreferences(
        language: AppLanguage.zhTw,
        theme: AppTheme.dark,
      );
      expect(
        decodePreferences(encodePreferences(value)).language,
        AppLanguage.zhTw,
      );
      expect(
        decodePreferences(encodePreferences(const AppPreferences())).language,
        isNull,
      );
      expect(
        () => decodePreferences('{"theme":"unknown"}'),
        throwsA(isA<PlatformError>()),
      );
      expect(() => decodePreferences('broken'), throwsA(isA<PlatformError>()));
    },
  );

  test(
    'real HTTP server verifies token, locale, envelope and 401 teardown',
    () async {
      final store = MemorySessions();
      final manager = SessionManager(store: store, scope: 'dev');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
        await manager.dispose();
      });
      String? token, language;
      server.listen((request) async {
        token = request.headers.value('x-auth-token');
        language = request.headers.value('accept-language');
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/market/symbol') {
          request.response.write('[{"symbol":"BTC/USDT","enable":1}]');
        } else {
          request.response.write('{"code":401,"message":"fixture"}');
        }
        await request.response.close();
      });
      final http = DioHttp(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        session: manager,
        locale: () => 'zh-CN',
      );
      addTearDown(http.close);
      final api = V1Adapter(http);
      await manager.signIn(() async => first, () async => identity);
      final result = await api.catalog.markets(
        const MarketQuery(instrumentType: InstrumentType.spot),
      );
      expect(result.items.single.symbol, 'BTC/USDT');
      expect(token, first.accessToken);
      expect(language, 'zh-CN');
      await expectLater(
        api.auth.me(),
        throwsA(
          predicate(
            (e) =>
                e is PlatformError &&
                e.code == PlatformErrorCode.authTokenExpired,
          ),
        ),
      );
      expect(manager.snapshot.status, SessionStatus.anonymous);
      expect(store.values['dev'], isNull);
    },
  );

  test('HTTP rejects redirects and cancellation without turning them into empty data', () async {
    final manager = SessionManager(store: MemorySessions(), scope: 'dev');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
      await manager.dispose();
    });
    server.listen((request) async {
      request.response.statusCode = 302;
      request.response.headers.set('location', 'https://another.example.test');
      await request.response.close();
    });
    final http = DioHttp(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      session: manager,
      locale: () => 'en-US',
    );
    addTearDown(http.close);
    await expectLater(http.request('/redirect'), throwsA(isA<PlatformError>()));
    final cancel = CancelToken()..cancel();
    await expectLater(
      http.request('/cancel', cancelToken: cancel),
      throwsA(
        predicate(
          (e) =>
              e is PlatformError &&
              e.code == PlatformErrorCode.requestCancelled,
        ),
      ),
    );
    await expectLater(
      http.request('https://another.example.test'),
      throwsA(isA<PlatformError>()),
    );
  });
}
