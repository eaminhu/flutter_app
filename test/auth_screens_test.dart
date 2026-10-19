import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:flutter_nexusft/app/nexus_app.dart';
import 'package:flutter_nexusft/app/router.dart';
import 'package:flutter_nexusft/core/adapters/unconfigured/unconfigured_adapter.dart';
import 'package:flutter_nexusft/core/api/contract.dart';
import 'package:flutter_nexusft/core/api/errors.dart';
import 'package:flutter_nexusft/core/domain/country.dart';
import 'package:flutter_nexusft/core/domain/market.dart';
import 'package:flutter_nexusft/core/domain/session.dart';
import 'package:flutter_nexusft/core/providers/platform_provider.dart';

class FixtureAuth implements AuthApi {
  FixtureAuth({this.registerError});
  PlatformError? registerError;
  var registerCalls = 0;
  var sendCodeCalls = 0;

  @override
  Future<List<Country>> countries() async => const [
    Country(zhName: '中国', enName: 'China', areaCode: '+86'),
    Country(zhName: '美国', enName: 'United States', areaCode: '+1'),
  ];

  @override
  Future<void> sendRegisterCode({required String email}) async {
    sendCodeCalls++;
  }

  @override
  Future<void> register(RegisterInput input) async {
    registerCalls++;
    final error = registerError;
    if (error != null) throw error;
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async => const AuthSession(accessToken: 'fixture-token', expiresAt: null);

  @override
  Future<AccountIdentity> me() async =>
      const AccountIdentity(accountId: 'fixture-account');
}

class FixtureApi implements PlatformApi, CatalogApi {
  FixtureApi(this.auth);
  @override
  final FixtureAuth auth;
  @override
  PredictionApi get prediction => const UnconfiguredAdapter().prediction;
  @override
  RealtimeApi get realtime => const UnconfiguredAdapter().realtime;
  @override
  CatalogApi get catalog => this;
  @override
  Future<Page<Market>> markets(MarketQuery query) async =>
      Page(items: const [], page: 1, pageSize: 20, total: 0);
}

Future<ProviderContainer> pumpApp(WidgetTester tester, FixtureAuth auth) async {
  tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final container = ProviderContainer(
    overrides: [platformApiProvider.overrideWithValue(FixtureApi(auth))],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const NexusApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> ensureVisible(WidgetTester tester, Key screen, Key target) async {
  await tester.scrollUntilVisible(
    find.byKey(target),
    120,
    scrollable: find
        .descendant(
          of: find.byKey(screen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, Key field, String text) async {
  final editable = find.descendant(
    of: find.byKey(field),
    matching: find.byType(EditableText),
  );
  await tester.enterText(editable, text);
  await tester.pump();
}

Future<void> fillValidForm(WidgetTester tester) async {
  const screen = Key('registerScreen');
  await tester.tap(find.byKey(const Key('registerCountry')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('China'));
  await tester.pumpAndSettle();
  // Selecting an FSelect item removes its FTappable mid-gesture; let the
  // stray long-press timer (500ms) expire so no timer is left pending.
  await tester.pump(const Duration(milliseconds: 700));
  await enter(tester, const Key('registerPhone'), '13800138000');
  await enter(tester, const Key('registerEmail'), 'user@example.com');
  await enter(tester, const Key('registerCode'), 'A1b2C3');
  await enter(tester, const Key('registerUsername'), 'trader1');
  await enter(tester, const Key('registerPassword'), 'Abcdef1!');
  await enter(tester, const Key('registerConfirm'), 'Abcdef1!');
  await ensureVisible(tester, screen, const Key('agreeTerms'));
  await tester.tap(find.byKey(const Key('agreeTerms')));
  await ensureVisible(tester, screen, const Key('agreeRisk'));
  await tester.tap(find.byKey(const Key('agreeRisk')));
  // FTappable keeps a 100ms press-feedback timer; advance past it so no
  // timer is pending when the test ends.
  await tester.pump(const Duration(milliseconds: 200));
}

bool submitEnabled(WidgetTester tester) =>
    tester.widget<FButton>(find.byKey(const Key('registerSubmit'))).onPress !=
    null;

void main() {
  testWidgets('register: submit stays disabled until the form is valid', (
    tester,
  ) async {
    final container = await pumpApp(tester, FixtureAuth());
    container.read(routerProvider).go('/register');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('registerScreen')), findsOneWidget);
    expect(submitEnabled(tester), isFalse);
    await fillValidForm(tester);
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('register: send code starts a 60s countdown', (tester) async {
    final auth = FixtureAuth();
    final container = await pumpApp(tester, auth);
    container.read(routerProvider).go('/register');
    await tester.pumpAndSettle();
    await enter(tester, const Key('registerEmail'), 'user@example.com');
    await tester.tap(find.byKey(const Key('sendCode')));
    await tester.pump();
    expect(auth.sendCodeCalls, 1);
    expect(find.text('Resend (60s)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 61));
    await tester.pump();
    expect(find.text('Send code'), findsOneWidget);
  });

  testWidgets('register: success auto signs in and lands on account', (
    tester,
  ) async {
    final auth = FixtureAuth();
    final container = await pumpApp(tester, auth);
    container.read(routerProvider).go('/register');
    await tester.pumpAndSettle();
    await fillValidForm(tester);
    await ensureVisible(tester, const Key('registerScreen'), const Key('registerSubmit'));
    await tester.tap(find.byKey(const Key('registerSubmit')));
    await tester.pumpAndSettle();
    expect(auth.registerCalls, 1);
    expect(find.byKey(const Key('accountScreen')), findsOneWidget);
  });

  testWidgets('register: backend rejection shows the backend message', (
    tester,
  ) async {
    final auth = FixtureAuth(
      registerError: const PlatformError(
        PlatformErrorCode.serverError,
        'Email already registered',
      ),
    );
    final container = await pumpApp(tester, auth);
    container.read(routerProvider).go('/register');
    await tester.pumpAndSettle();
    await fillValidForm(tester);
    await ensureVisible(tester, const Key('registerScreen'), const Key('registerSubmit'));
    await tester.tap(find.byKey(const Key('registerSubmit')));
    await tester.pumpAndSettle();
    expect(find.text('Email already registered'), findsOneWidget);
    expect(find.byKey(const Key('registerScreen')), findsOneWidget);
    // The form stays retryable after a failure.
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('login: register link navigates to /register', (tester) async {
    final container = await pumpApp(tester, FixtureAuth());
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();
    await ensureVisible(tester, const Key('loginScreen'), const Key('registerLink'));
    await tester.tap(find.byKey(const Key('registerLink')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('registerScreen')), findsOneWidget);
  });

  testWidgets('login: password visibility toggles', (tester) async {
    final container = await pumpApp(tester, FixtureAuth());
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();
    await enter(tester, const Key('loginPassword'), 'secret');
    EditableText field() => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('loginPassword')),
        matching: find.byType(EditableText),
      ),
    );
    expect(field().obscureText, isTrue);
    await tester.tap(find.byKey(const Key('passwordVisibility')));
    await tester.pump();
    expect(field().obscureText, isFalse);
  });

  testWidgets('login: Google button is a coming-soon placeholder', (
    tester,
  ) async {
    final container = await pumpApp(tester, FixtureAuth());
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();
    await ensureVisible(tester, const Key('loginScreen'), const Key('googleSignIn'));
    await tester.tap(find.byKey(const Key('googleSignIn')));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon.'), findsOneWidget);
  });
}
