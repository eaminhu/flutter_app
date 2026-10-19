import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nexusft/app/nexus_app.dart';
import 'package:flutter_nexusft/core/adapters/unconfigured/unconfigured_adapter.dart';
import 'package:flutter_nexusft/core/api/contract.dart';
import 'package:flutter_nexusft/core/api/errors.dart';
import 'package:flutter_nexusft/core/domain/event_card.dart';
import 'package:flutter_nexusft/core/domain/event_detail.dart';
import 'package:flutter_nexusft/core/domain/market.dart';
import 'package:flutter_nexusft/core/providers/platform_provider.dart';

class FixturePrediction implements PredictionApi {
  FixturePrediction({
    required this.pages,
    required this.total,
    this.categoryList = const [],
    this.firstPageError,
  });

  /// page number → cards.
  final Map<int, List<EventCard>> pages;
  final int total;
  final List<CategoryNode> categoryList;
  final PlatformError? firstPageError;
  final requestedDomains = <String?>[];
  final queries = <CardQuery>[];
  var requests = 0;
  var _failed = false;

  @override
  Future<Page<EventCard>> events(CardQuery query) async {
    requests++;
    queries.add(query);
    requestedDomains.add(query.domain);
    if (query.page == 1 && firstPageError != null && !_failed) {
      _failed = true;
      throw firstPageError!;
    }
    final items = pages[query.page] ?? const <EventCard>[];
    return Page(
      items: items,
      page: query.page,
      pageSize: query.pageSize,
      total: total,
    );
  }

  @override
  Future<EventDetail> eventDetail(String eventId) async =>
      detail ?? (throw UnimplementedError('fixture: no detail'));

  EventDetail? detail;

  @override
  Future<List<CategoryNode>> categories() async => categoryList;
}

class FixtureApi implements PlatformApi, CatalogApi {
  FixtureApi(this.predictionApi);
  @override
  AuthApi get auth => const UnconfiguredAdapter().auth;
  @override
  CatalogApi get catalog => this;
  @override
  PredictionApi get prediction => predictionApi;
  @override
  RealtimeApi get realtime => const UnconfiguredAdapter().realtime;
  final FixturePrediction predictionApi;
  @override
  Future<Page<Market>> markets(MarketQuery query) async =>
      Page(items: const [], page: 1, pageSize: 20, total: 0);
}

EventCard card(
  String id,
  String title, {
  Decimal? prob,
  TradeStatus status = TradeStatus.open,
}) => EventCard(
  id: id,
  title: title,
  outcomes: [
    EventOutcome(name: 'Yes', prob: prob, marketId: 'm$id'),
    EventOutcome(name: 'No', prob: prob == null ? null : Decimal.fromInt(100) - prob, marketId: 'm$id'),
  ],
  status: status,
  numMarkets: 1,
  pricingPending: prob == null,
  tradingStartsAt: DateTime.now().subtract(const Duration(hours: 1)),
  closesAt: DateTime.now().add(const Duration(days: 7)),
  volume24h: Decimal.parse('12500'),
);

Future<void> pumpPrediction(WidgetTester tester, FixturePrediction prediction) async {
  tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = const Size(540, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        platformApiProvider.overrideWithValue(FixtureApi(prediction)),
      ],
      child: const NexusApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('instrumentTab.prediction')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('prediction tab loads real cards with prob and LIVE pill', (
    tester,
  ) async {
    await pumpPrediction(
      tester,
      FixturePrediction(
        pages: {
          1: [card('e1', 'Will BTC exceed 150k in 2026?', prob: Decimal.fromInt(64))],
        },
        total: 1,
      ),
    );
    expect(find.byKey(const Key('eventsList')), findsOneWidget);
    expect(find.byKey(const Key('eventCard.e1')), findsOneWidget);
    expect(find.text('Will BTC exceed 150k in 2026?'), findsOneWidget);
    // Leaderboard layout renders percent prices; footer shows compact volume.
    expect(find.text('64%'), findsWidgets);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.textContaining('\$12.5K'), findsOneWidget);
    expect(find.byKey(const Key('bookmark.e1')), findsOneWidget);
  });

  testWidgets('empty feed shows the empty state', (tester) async {
    await pumpPrediction(
      tester,
      FixturePrediction(pages: const {1: []}, total: 0),
    );
    expect(find.byKey(const Key('eventsEmpty')), findsOneWidget);
    expect(find.text('No prediction markets available.'), findsOneWidget);
  });

  testWidgets('a failed first page can be retried', (tester) async {
    final prediction = FixturePrediction(
      pages: {1: [card('e1', 'Event one', prob: Decimal.fromInt(10))]},
      total: 1,
      firstPageError: const PlatformError(
        PlatformErrorCode.unexpected,
        'Fixture outage',
      ),
    );
    await pumpPrediction(tester, prediction);
    expect(find.byKey(const Key('eventsError')), findsOneWidget);
    expect(find.text('Unable to load prediction markets.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eventCard.e1')), findsOneWidget);
    expect(prediction.requests, 2);
  });

  testWidgets('category chips refilter the feed by domain', (tester) async {
    final prediction = FixturePrediction(
      pages: {1: [card('e1', 'Event one', prob: Decimal.fromInt(10))]},
      total: 1,
      categoryList: const [
        CategoryNode(
          id: 'crypto',
          label: 'Crypto',
          children: [CategoryNode(id: 'bitcoin', label: 'Bitcoin')],
        ),
      ],
    );
    await pumpPrediction(tester, prediction);
    expect(find.byKey(const Key('categoryChip.all')), findsOneWidget);
    expect(find.byKey(const Key('categoryChip.crypto')), findsOneWidget);
    expect(find.byKey(const Key('categoryChip.crypto/bitcoin')), findsOneWidget);
    await tester.tap(find.byKey(const Key('categoryChip.crypto')));
    await tester.pumpAndSettle();
    expect(prediction.requestedDomains, contains('Crypto'));
  });

  testWidgets('scrolling to the end loads the next page', (tester) async {
    final page1 = [
      for (var i = 1; i <= 5; i++)
        card('e$i', 'Event number $i with a reasonably long title', prob: Decimal.fromInt(10 + i)),
    ];
    final prediction = FixturePrediction(
      pages: {
        1: page1,
        2: [card('e6', 'Event number six', prob: Decimal.fromInt(20))],
      },
      total: 6,
    );
    await pumpPrediction(tester, prediction);
    expect(find.byKey(const Key('eventCard.e1')), findsOneWidget);
    await tester.fling(find.byKey(const Key('eventsList')), const Offset(0, -800), 1200);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eventCard.e6')), findsOneWidget);
  });

  testWidgets('tapping a card opens the detail page', (tester) async {
    final prediction = FixturePrediction(
      pages: {1: [card('e1', 'Event one', prob: Decimal.fromInt(10))]},
      total: 1,
    );
    prediction.detail = EventDetail(
      id: 'e1',
      title: 'Event one',
      status: TradeStatus.open,
      outcomes: const [DetailOutcome(name: 'Yes', marketId: 'm1')],
    );
    await pumpPrediction(tester, prediction);
    await tester.tap(find.byKey(const Key('eventCard.e1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eventDetailBody')), findsOneWidget);
    // The shell bottom bar is gone on the full-screen detail route.
    expect(find.byKey(const Key('spotTab')), findsNothing);
  });

  testWidgets('switching back to the spot tab restores the trading body', (
    tester,
  ) async {
    await pumpPrediction(
      tester,
      FixturePrediction(
        pages: {1: [card('e1', 'Event one', prob: Decimal.fromInt(10))]},
        total: 1,
      ),
    );
    expect(find.byKey(const Key('eventsList')), findsOneWidget);
    await tester.tap(find.byKey(const Key('instrumentTab.spot')));
    await tester.pumpAndSettle();
    // The fixture catalog is empty: the spot body shows its empty state.
    expect(find.byKey(const Key('marketEmpty')), findsOneWidget);
  });

  testWidgets('non-CJK search goes to the server with a search param', (
    tester,
  ) async {
    final prediction = FixturePrediction(
      pages: {1: [card('e1', 'Bitcoin event', prob: Decimal.fromInt(10))]},
      total: 1,
    );
    await pumpPrediction(tester, prediction);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('eventSearch')),
        matching: find.byType(EditableText),
      ),
      'bitcoin',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(prediction.queries.last.search, 'bitcoin');
    expect(prediction.queries.last.pageSize, 20);
    expect(find.byKey(const Key('searchResultCount')), findsOneWidget);
    // Clearing restores the unfiltered feed.
    await tester.tap(find.byKey(const Key('clearSearch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categoryChips')), findsOneWidget);
    expect(prediction.queries.last.search, isNull);
  });

  testWidgets('CJK search filters one bulk page client-side', (tester) async {
    final prediction = FixturePrediction(
      pages: {
        1: [
          card('e1', '比特币今晚涨吗', prob: Decimal.fromInt(55)),
          card('e2', 'Ethereum upgrade', prob: Decimal.fromInt(30)),
        ],
      },
      total: 2,
    );
    await pumpPrediction(tester, prediction);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('eventSearch')),
        matching: find.byType(EditableText),
      ),
      '比特',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    // Bulk fetch, no server-side search param; only the matching card shows.
    expect(prediction.queries.last.search, isNull);
    expect(prediction.queries.last.pageSize, 500);
    expect(find.byKey(const Key('eventCard.e1')), findsOneWidget);
    expect(find.byKey(const Key('eventCard.e2')), findsNothing);
    expect(find.text('Results: 1'), findsOneWidget);
  });

  testWidgets('match cards render the 1X2 cells with an unpriced dash', (
    tester,
  ) async {
    final match = EventCard(
      id: 'm1',
      title: 'Everton FC vs. Chelsea FC',
      archetype: CardArchetype.match,
      outcomes: [
        EventOutcome(name: 'Everton', prob: Decimal.fromInt(44)),
        EventOutcome(name: 'Draw', prob: Decimal.fromInt(30)),
        const EventOutcome(name: 'Chelsea'),
      ],
      status: TradeStatus.open,
      numMarkets: 3,
      pricingPending: false,
      tradingStartsAt: DateTime.now().subtract(const Duration(hours: 1)),
      closesAt: DateTime.now().add(const Duration(days: 2)),
    );
    await pumpPrediction(
      tester,
      FixturePrediction(pages: {
        1: [match],
      }, total: 1),
    );
    expect(find.byKey(const Key('eventCell.m1.0')), findsOneWidget);
    expect(find.byKey(const Key('eventCell.m1.2')), findsOneWidget);
    expect(find.text('44%'), findsOneWidget);
    // Draw is the centered middle button; its leg has no row of its own.
    expect(find.text('Draw'), findsOneWidget);
    // Unpriced cell shows a dash, never 0.
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('binary cards render Yes/No price buttons', (tester) async {
    final binary = EventCard(
      id: 'b1',
      title: 'Will BTC exceed 150k?',
      archetype: CardArchetype.binary,
      outcomes: [
        EventOutcome(name: 'Yes', prob: Decimal.fromInt(64)),
        EventOutcome(name: 'No', prob: Decimal.fromInt(36)),
      ],
      status: TradeStatus.open,
      numMarkets: 1,
      pricingPending: false,
      closesAt: DateTime.now().add(const Duration(days: 2)),
    );
    await pumpPrediction(
      tester,
      FixturePrediction(pages: {
        1: [binary],
      }, total: 1),
    );
    expect(find.byKey(const Key('eventYes.b1')), findsOneWidget);
    expect(find.byKey(const Key('eventNo.b1')), findsOneWidget);
    expect(find.text('64%'), findsOneWidget);
    expect(find.text('36%'), findsOneWidget);
  });

  testWidgets('leaderboard cards show top four rows and a +N remainder', (
    tester,
  ) async {
    final board = EventCard(
      id: 'w1',
      title: 'World Cup winner',
      archetype: CardArchetype.leaderboard,
      outcomes: [
        for (var i = 1; i <= 6; i++)
          EventOutcome(name: 'Team $i', prob: Decimal.fromInt(60 - i * 5)),
      ],
      status: TradeStatus.open,
      numMarkets: 6,
      pricingPending: false,
      closesAt: DateTime.now().add(const Duration(days: 30)),
    );
    await pumpPrediction(
      tester,
      FixturePrediction(pages: {
        1: [board],
      }, total: 1),
    );
    expect(find.byKey(const Key('eventRow.w1.0')), findsOneWidget);
    expect(find.byKey(const Key('eventRow.w1.3')), findsOneWidget);
    expect(find.byKey(const Key('eventRow.w1.4')), findsNothing);
    expect(find.byKey(const Key('eventMore.w1')), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
  });
}
