import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nexusft/app/nexus_app.dart';
import 'package:flutter_nexusft/app/router.dart';
import 'package:flutter_nexusft/core/adapters/unconfigured/unconfigured_adapter.dart';
import 'package:flutter_nexusft/core/api/contract.dart';
import 'package:flutter_nexusft/core/domain/market.dart';
import 'package:flutter_nexusft/core/providers/platform_provider.dart';
import 'package:flutter_nexusft/modules/assets/demo_assets.dart';
import 'package:flutter_nexusft/modules/spot/demo_orders.dart';

class FixtureApi implements PlatformApi, CatalogApi {
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

Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final container = ProviderContainer(
    overrides: [platformApiProvider.overrideWithValue(FixtureApi())],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const NexusApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('demo orders and demo assets are deterministic', () {
    final a = demoOrders('BTC/USDT');
    final b = demoOrders('BTC/USDT');
    expect(a.openOrders.length, 2);
    expect(a.history.length, 3);
    expect(a.positions.length, 1);
    expect(a.openOrders.first.price, b.openOrders.first.price);
    expect(a.positions.first.pnl, b.positions.first.pnl);
    final first = demoAssets();
    final second = demoAssets();
    expect(first.totalUsd, second.totalUsd);
    expect(first.assets.map((a) => a.currency), ['USDT', 'BTC', 'ETH']);
  });

  testWidgets('orders tabs switch between demo lists with demo labels', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('ordersTabs')), findsOneWidget);
    expect(find.byKey(const Key('ordersDemoHint')), findsOneWidget);
    expect(find.byKey(const Key('openOrdersList')), findsOneWidget);
    expect(find.byKey(const Key('ordersSignInHint')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ordersTab.1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('historyList')), findsOneWidget);
    expect(find.text('Canceled'), findsWidgets);
    await tester.tap(find.byKey(const Key('ordersTab.2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('positionsList')), findsOneWidget);
    expect(find.byKey(const Key('positionPnl')), findsOneWidget);
  });

  testWidgets('assets tab opens the demo assets page with sign-in CTA', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('assetsTab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('assetsScreen')), findsOneWidget);
    expect(find.byKey(const Key('totalAssetsCard')), findsOneWidget);
    expect(find.byKey(const Key('assetsDemoHint')), findsOneWidget);
    expect(find.byKey(const Key('assetList')), findsOneWidget);
    expect(find.byKey(const Key('asset.USDT')), findsOneWidget);
    expect(find.byKey(const Key('assetsSignIn')), findsOneWidget);
    // Demo quick actions only hint; nothing is sent anywhere.
    await tester.tap(find.byKey(const Key('assetsDeposit')));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon.'), findsOneWidget);
  });

  testWidgets('assets sign-in CTA navigates to /login', (tester) async {
    final container = await pumpApp(tester);
    container.read(routerProvider).go('/assets');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assetsSignIn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loginScreen')), findsOneWidget);
  });
}
