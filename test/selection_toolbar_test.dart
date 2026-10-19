
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_nexusft/app/nexus_app.dart';
import 'package:flutter_nexusft/app/router.dart';
import 'package:flutter_nexusft/app/localization/app_localizations.dart';
import 'package:flutter_nexusft/core/adapters/unconfigured/unconfigured_adapter.dart';
import 'package:flutter_nexusft/core/api/contract.dart';
import 'package:flutter_nexusft/core/domain/country.dart';
import 'package:flutter_nexusft/core/domain/market.dart';
import 'package:flutter_nexusft/core/domain/preferences.dart';
import 'package:flutter_nexusft/core/domain/session.dart';
import 'package:flutter_nexusft/core/providers/platform_provider.dart';

class _SpotFixtureApi implements PlatformApi, CatalogApi {
  @override
  AuthApi get auth => const UnconfiguredAdapter().auth;
  @override
  PredictionApi get prediction => const UnconfiguredAdapter().prediction;
  @override
  RealtimeApi get realtime => const UnconfiguredAdapter().realtime;
  @override
  CatalogApi get catalog => this;
  @override
  Future<Page<Market>> markets(MarketQuery query) async => Page(
    items: const [
      Market(
        marketId: 'fixture-btc',
        symbol: 'BTC/USDT',
        instrumentType: InstrumentType.spot,
      ),
    ],
    page: 1,
    pageSize: 20,
    total: 1,
  );
}

class _RegisterFixtureAuth implements AuthApi {
  const _RegisterFixtureAuth();
  @override
  Future<List<Country>> countries() async => const [
    Country(zhName: '中国', enName: 'China', areaCode: '+86'),
  ];
  @override
  Future<void> sendRegisterCode({required String email}) async {}
  @override
  Future<void> register(RegisterInput input) async {}
  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async => const AuthSession(accessToken: 'fixture-token', expiresAt: null);
  @override
  Future<AccountIdentity> me() async =>
      const AccountIdentity(accountId: 'fixture-account');
}

class _RegisterFixtureApi implements PlatformApi, CatalogApi {
  @override
  AuthApi get auth => const _RegisterFixtureAuth();
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

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final language in AppLanguage.values) {
      testWidgets(
        'Forui selection toolbar works on ${platform.name} / ${language.name}',
        (tester) async {
          tester.platformDispatcher.localesTestValue = [localeFor(language)];
          addTearDown(tester.platformDispatcher.clearLocalesTestValue);
          final container = ProviderContainer();
          addTearDown(container.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const NexusApp(),
            ),
          );
          await tester.pumpAndSettle();
          container.read(routerProvider).go('/login');
          await tester.pumpAndSettle();
          final editable = find.byType(EditableText).first;
          await tester.enterText(editable, 'selection-fixture');
          await tester.pump();
          await tester.longPressAt(
            tester.getTopLeft(editable) + const Offset(12, 12),
          );
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
          expect(
            find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == 'AdaptiveTextSelectionToolbar',
            ),
            findsWidgets,
          );
        },
        variant: TargetPlatformVariant.only(platform),
      );

      testWidgets(
        'Spot order ticket selection toolbar works on ${platform.name} / ${language.name}',
        (tester) async {
          tester.platformDispatcher.localesTestValue = [localeFor(language)];
          addTearDown(tester.platformDispatcher.clearLocalesTestValue);
          // Give the dense trading page enough vertical room so the order
          // ticket's price field is fully visible for the long press.
          tester.view.physicalSize = const Size(540, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          final container = ProviderContainer(
            overrides: [
              platformApiProvider.overrideWithValue(_SpotFixtureApi()),
            ],
          );
          addTearDown(container.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const NexusApp(),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('orderTicket')), findsOneWidget);
          await tester.scrollUntilVisible(
            find.byKey(const Key('orderPriceField')),
            120,
            scrollable: find
                .descendant(
                  of: find.byKey(const Key('orderTicket')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          final editable = find.descendant(
            of: find.byKey(const Key('orderPriceField')),
            matching: find.byType(EditableText),
          );
          await tester.enterText(editable, 'selection-fixture');
          await tester.pump();
          await tester.longPressAt(
            tester.getTopLeft(editable) + const Offset(12, 12),
          );
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
          expect(
            find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == 'AdaptiveTextSelectionToolbar',
            ),
            findsWidgets,
          );
        },
        variant: TargetPlatformVariant.only(platform),
      );

      testWidgets(
        'Register field selection toolbar works on ${platform.name} / ${language.name}',
        (tester) async {
          tester.platformDispatcher.localesTestValue = [localeFor(language)];
          addTearDown(tester.platformDispatcher.clearLocalesTestValue);
          final container = ProviderContainer(
            overrides: [
              platformApiProvider.overrideWithValue(_RegisterFixtureApi()),
            ],
          );
          addTearDown(container.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const NexusApp(),
            ),
          );
          await tester.pumpAndSettle();
          container.read(routerProvider).go('/register');
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('registerScreen')), findsOneWidget);
          await tester.scrollUntilVisible(
            find.byKey(const Key('registerEmail')),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          final editable = find.descendant(
            of: find.byKey(const Key('registerEmail')),
            matching: find.byType(EditableText),
          );
          await tester.enterText(editable, 'selection-fixture');
          await tester.pump();
          await tester.longPressAt(
            tester.getTopLeft(editable) + const Offset(12, 12),
          );
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
          expect(
            find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == 'AdaptiveTextSelectionToolbar',
            ),
            findsWidgets,
          );
        },
        variant: TargetPlatformVariant.only(platform),
      );
    }
  }
}

