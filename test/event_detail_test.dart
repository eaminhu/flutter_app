import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nexusft/app/nexus_app.dart';
import 'package:flutter_nexusft/app/router.dart';
import 'package:flutter_nexusft/core/adapters/unconfigured/unconfigured_adapter.dart';
import 'package:flutter_nexusft/core/api/contract.dart';
import 'package:flutter_nexusft/core/api/errors.dart';
import 'package:flutter_nexusft/core/domain/event_card.dart';
import 'package:flutter_nexusft/core/domain/event_detail.dart';
import 'package:flutter_nexusft/core/domain/market.dart';
import 'package:flutter_nexusft/core/providers/platform_provider.dart';

class FixtureRealtime implements RealtimeApi {
  final channels = <String, StreamController<AuctionTick>>{};
  var revalidateCalls = 0;

  @override
  Stream<AuctionTick> watchAuction(String marketId) {
    final controller = StreamController<AuctionTick>.broadcast();
    channels[marketId] = controller;
    return controller.stream;
  }

  @override
  void revalidate() => revalidateCalls++;

  void tick(String marketId, {String? bestBid, String? bestAsk}) {
    channels[marketId]?.add(
      AuctionTick(
        marketId: marketId,
        bestBid: bestBid == null ? null : Decimal.parse(bestBid),
        bestAsk: bestAsk == null ? null : Decimal.parse(bestAsk),
      ),
    );
  }
}

class FixturePrediction implements PredictionApi {
  FixturePrediction({this.detail, this.detailError});

  final EventDetail? detail;
  final PlatformError? detailError;

  @override
  Future<Page<EventCard>> events(CardQuery query) async =>
      Page(items: const [], page: 1, pageSize: 20, total: 0);

  @override
  Future<EventDetail> eventDetail(String eventId) async {
    final error = detailError;
    if (error != null) throw error;
    return detail!;
  }

  @override
  Future<List<CategoryNode>> categories() async => const [];
}

class FixtureApi implements PlatformApi, CatalogApi {
  FixtureApi(this.predictionApi, this.realtimeApi);
  @override
  AuthApi get auth => const UnconfiguredAdapter().auth;
  @override
  CatalogApi get catalog => this;
  @override
  PredictionApi get prediction => predictionApi;
  @override
  RealtimeApi get realtime => realtimeApi;
  final FixturePrediction predictionApi;
  final FixtureRealtime realtimeApi;
  @override
  Future<Page<Market>> markets(MarketQuery query) async =>
      Page(items: const [], page: 1, pageSize: 20, total: 0);
}

EventDetail detail() => EventDetail(
  id: 'e1',
  title: 'Will BTC exceed 150k in 2026?',
  status: TradeStatus.open,
  outcomes: [
    DetailOutcome(name: 'Yes', marketId: 'm1', prob: Decimal.fromInt(50)),
    DetailOutcome(name: 'No', marketId: 'm1', prob: Decimal.fromInt(50)),
  ],
  closesAt: DateTime.now().add(const Duration(days: 7)),
  tradingStartsAt: DateTime.now().subtract(const Duration(hours: 1)),
  volume: Decimal.parse('12500'),
  liquidity: Decimal.parse('4200'),
  resolutionRule: 'Resolves per the official source.',
  resolutionSourceUrl: 'https://example.com/rules',
);

Future<(ProviderContainer, FixtureRealtime)> pumpDetail(
  WidgetTester tester,
  FixturePrediction prediction,
) async {
  tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = const Size(540, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final realtime = FixtureRealtime();
  final container = ProviderContainer(
    overrides: [
      platformApiProvider.overrideWithValue(FixtureApi(prediction, realtime)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const NexusApp()),
  );
  await tester.pumpAndSettle();
  container.read(routerProvider).go('/prediction/e1');
  await tester.pumpAndSettle();
  return (container, realtime);
}

void main() {
  testWidgets('detail page renders snapshot fields and outcome rows', (
    tester,
  ) async {
    await pumpDetail(tester, FixturePrediction(detail: detail()));
    expect(find.byKey(const Key('eventDetailBody')), findsOneWidget);
    expect(find.text('Will BTC exceed 150k in 2026?'), findsWidgets);
    expect(find.text('50%'), findsNWidgets(2));
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('12500.00'), findsOneWidget);
    expect(find.text('4200.00'), findsOneWidget);
    expect(find.text('Resolves per the official source.'), findsOneWidget);
    expect(find.byKey(const Key('eventDetailBack')), findsOneWidget);
  });

  testWidgets('a live auction tick overlays the snapshot probability', (
    tester,
  ) async {
    final (_, realtime) = await pumpDetail(
      tester,
      FixturePrediction(detail: detail()),
    );
    expect(realtime.channels.keys, contains('m1'));
    realtime.tick('m1', bestBid: '0.70', bestAsk: '0.72');
    await tester.pumpAndSettle();
    expect(find.text('72%'), findsWidgets);
    // A degenerate spread is skipped: the last live value stays.
    realtime.tick('m1', bestBid: '0.01', bestAsk: '0.99');
    await tester.pumpAndSettle();
    expect(find.text('72%'), findsWidgets);
  });

  testWidgets('detail failure shows a retryable page status', (tester) async {
    await pumpDetail(
      tester,
      FixturePrediction(
        detailError: const PlatformError(
          PlatformErrorCode.unexpected,
          'Fixture outage',
        ),
      ),
    );
    expect(find.byKey(const Key('eventDetailError')), findsOneWidget);
    expect(find.text('Unable to load prediction markets.'), findsOneWidget);
  });

  testWidgets('outcome trade buttons stay placeholders', (tester) async {
    await pumpDetail(tester, FixturePrediction(detail: detail()));
    await tester.tap(find.text('Yes').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Trading is not connected yet. No order was sent.'),
      findsOneWidget,
    );
  });
}
