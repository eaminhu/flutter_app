import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_nexusft/app/nexus_app.dart';
import 'package:flutter_nexusft/app/router.dart';
import 'package:flutter_nexusft/core/domain/preferences.dart';
import 'package:flutter_nexusft/core/domain/session.dart';
import 'package:flutter_nexusft/core/providers/preferences_provider.dart';
import 'package:flutter_nexusft/core/providers/session_provider.dart';
import 'package:flutter_nexusft/core/session/session_manager.dart';
import 'package:flutter_nexusft/core/storage/session_store.dart';
import 'package:flutter_nexusft/core/storage/preferences_store.dart';
import 'package:flutter_nexusft/core/api/errors.dart';

void main() {
  test('credential codec never fabricates expiry or accepts missing token', () {
    const session = AuthSession(accessToken: 'fixture-token', expiresAt: null);
    expect(decodeSession(encodeSession(session)).expiresAt, isNull);
    expect(
      () => decodeSession('{"expiresAt":null}'),
      throwsA(isA<PlatformError>()),
    );
    expect(
      () => decodeSession('{"accessToken":" ","expiresAt":null}'),
      throwsA(isA<PlatformError>()),
    );
  });
  test('preferences survive a fresh provider container', () async {
    final store = MemoryPreferencesStore();
    final first = ProviderContainer(
      overrides: [preferencesStoreProvider.overrideWithValue(store)],
    );
    await first
        .read(preferencesProvider.notifier)
        .selectLanguage(AppLanguage.zhTw);
    await first.read(preferencesProvider.notifier).selectTheme(AppTheme.dark);
    first.dispose();
    final restored = await store.read();
    final second = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(restored),
      ],
    );
    addTearDown(second.dispose);
    expect(second.read(preferencesProvider).language, AppLanguage.zhTw);
    expect(second.read(preferencesProvider).theme, AppTheme.dark);
  });
  testWidgets('account page hosts the profile with a guest CTA', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final manager = SessionManager(store: MemorySessionStore(), scope: 'fixture');
    addTearDown(manager.dispose);
    final container = ProviderContainer(
      overrides: [sessionManagerProvider.overrideWithValue(manager)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const NexusApp()),
    );
    await tester.pumpAndSettle();
    final router = container.read(routerProvider);
    router.go('/account');
    await tester.pumpAndSettle();
    // Guests see the profile page itself with a sign-in CTA (no redirect).
    expect(find.byKey(const Key('accountScreen')), findsOneWidget);
    expect(find.byKey(const Key('profileSignIn')), findsOneWidget);
    await manager.signIn(
      () async => const AuthSession(accessToken: 'fixture', expiresAt: null),
      () async => const AccountIdentity(accountId: 'fixture-account'),
    );
    await tester.pumpAndSettle();
    expect(identical(container.read(routerProvider), router), isTrue);
    expect(find.byKey(const Key('profileAccountId')), findsOneWidget);
    expect(find.text('fixture-account'), findsOneWidget);
    await manager.signOut();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profileSignIn')), findsOneWidget);
    expect(find.text('fixture-account'), findsNothing);
  });
}
