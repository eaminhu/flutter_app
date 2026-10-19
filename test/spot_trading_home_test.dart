import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:flutter_nexusft/app/nexus_app.dart';
import 'package:flutter_nexusft/core/adapters/unconfigured/unconfigured_adapter.dart';
import 'package:flutter_nexusft/core/api/contract.dart';
import 'package:flutter_nexusft/core/domain/market.dart';
import 'package:flutter_nexusft/core/providers/platform_provider.dart';
import 'package:flutter_nexusft/design_system/trading/trade_side_switch.dart';
import 'package:flutter_nexusft/modules/spot/demo_order_book.dart';

class FixtureApi implements PlatformApi, CatalogApi {
  @override
  AuthApi get auth => const UnconfiguredAdapter().auth;
  @override
  PredictionApi get prediction => const UnconfiguredAdapter().prediction;
  @override
  RealtimeApi get realtime => const UnconfiguredAdapter().realtime;
  FixtureApi(this.read);
  final Future<Page<Market>> Function() read;
  @override
  CatalogApi get catalog => this;
  @override
  Future<Page<Market>> markets(MarketQuery query) => read();
}

Page<Market> twoMarkets() => Page(
  items: const [
    Market(
      marketId: 'fixture-btc',
      symbol: 'BTC/USDT',
      instrumentType: InstrumentType.spot,
    ),
    Market(
      marketId: 'fixture-eth',
      symbol: 'ETH/USDT',
      instrumentType: InstrumentType.spot,
    ),
  ],
  page: 1,
  pageSize: 20,
  total: 2,
);

Future<void> pumpSpot(WidgetTester tester) async {
  tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        platformApiProvider.overrideWithValue(FixtureApi(() async => twoMarkets())),
      ],
      child: const NexusApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('demo order book is deterministic per symbol', () {
    final a = demoOrderBook('BTC/USDT');
    final b = demoOrderBook('BTC/USDT');
    final other = demoOrderBook('ETH/USDT');
    expect(a.midPrice, b.midPrice);
    expect(a.buyPercent, b.buyPercent);
    expect(a.asks.length, 7);
    expect(a.bids.length, 7);
    expect(a.buyPercent, inInclusiveRange(0, 100));
    // A different symbol yields a different book (different seeds).
    expect(a.midPrice == other.midPrice && a.buyPercent == other.buyPercent,
        isFalse);
  });

  testWidgets('catalog loads: pair header shows symbol, book shows demo data', (
    tester,
  ) async {
    await pumpSpot(tester);
    expect(find.byKey(const Key('pairHeader')), findsOneWidget);
    expect(find.text('BTC/USDT'), findsOneWidget);
    expect(find.byKey(const Key('marketError')), findsNothing);
    // Form and quote placeholders stay `--`; the order book renders locally
    // generated demo levels that are explicitly labelled as demo data.
    expect(find.byKey(const Key('pairLastPrice')), findsOneWidget);
    expect(find.text('--'), findsWidgets);
    expect(find.text('Demo data'), findsWidgets);
    expect(find.byKey(const Key('orderTicket')), findsOneWidget);
    expect(find.byKey(const Key('orderBookPanel')), findsOneWidget);
    expect(find.byKey(const Key('buySellRatioBar')), findsOneWidget);
    expect(find.byKey(const Key('ordersTabs')), findsOneWidget);
    expect(find.byKey(const Key('ordersSignInHint')), findsOneWidget);
  });

  testWidgets('pair picker selects another real catalog market', (
    tester,
  ) async {
    await pumpSpot(tester);
    await tester.tap(find.byKey(const Key('pairSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('marketOption.fixture-eth')));
    await tester.pumpAndSettle();
    expect(find.text('ETH/USDT'), findsOneWidget);
  });

  testWidgets('buy/sell switch toggles the trade side', (tester) async {
    await pumpSpot(tester);
    TradeSide side() =>
        tester.widget<TradeSideSwitch>(find.byKey(const Key('tradeSideSwitch'))).value;
    expect(side(), TradeSide.buy);
    await tester.tap(find.byKey(const Key('tradeSell')));
    await tester.pumpAndSettle();
    expect(side(), TradeSide.sell);
    await tester.tap(find.byKey(const Key('tradeBuy')));
    await tester.pumpAndSettle();
    expect(side(), TradeSide.buy);
  });

  testWidgets('futures and cfd tabs show a coming-soon placeholder', (
    tester,
  ) async {
    await pumpSpot(tester);
    await tester.tap(find.byKey(const Key('instrumentTab.futures')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tradeModePlaceholder')), findsOneWidget);
    expect(find.text('Coming soon.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('instrumentTab.cfd')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tradeModePlaceholder')), findsOneWidget);
    await tester.tap(find.byKey(const Key('instrumentTab.spot')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('orderTicket')), findsOneWidget);
  });

  testWidgets('signed-out CTA is sign in / sign up', (tester) async {
    await pumpSpot(tester);
    final cta = find.byKey(const Key('orderCta'));
    expect(cta, findsOneWidget);
    expect(find.text('Sign in / Sign up'), findsOneWidget);
  });

  testWidgets('bottom navigation has four entries with trade selected', (
    tester,
  ) async {
    await pumpSpot(tester);
    expect(find.byKey(const Key('homeTab')), findsOneWidget);
    expect(find.byKey(const Key('spotTab')), findsOneWidget);
    expect(find.byKey(const Key('assetsTab')), findsOneWidget);
    expect(find.byKey(const Key('profileTab')), findsOneWidget);
    final bar = tester.widget<FBottomNavigationBar>(
      find.byType(FBottomNavigationBar),
    );
    expect(bar.index, 1);
  });

  testWidgets('placeholder route is reachable from home tab', (tester) async {
    await pumpSpot(tester);
    await tester.tap(find.byKey(const Key('homeTab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('placeholderScreen')), findsOneWidget);
    expect(find.text('Coming soon.'), findsOneWidget);
    final bar = tester.widget<FBottomNavigationBar>(
      find.byType(FBottomNavigationBar),
    );
    expect(bar.index, -1);
  });
}
