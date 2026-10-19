import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_nexusft/core/adapters/v1/v1_adapter.dart';
import 'package:flutter_nexusft/core/domain/event_card.dart';
import 'package:flutter_nexusft/design_system/trading/compact_volume.dart';

// Wire samples modelled on the Web v1 adapter's expectations
// (dex-v2_fe src/core/adapters/v1-server/catalog.ts itemToCard).
Map<String, dynamic> homeItem({
  String id = '900222',
  String title = 'Will BTC exceed 150k in 2026?',
  String cardLayout = 'SINGLE_BINARY',
  String status = 'ACTIVE',
  List<Map<String, dynamic>>? previewItems,
  int? tradingStartTime = 1760000000000,
  int? tradingCloseTime = 1790000000000,
  Object? totalVolumeUsd = '125000.5',
}) => {
  'id': id,
  'title': title,
  'cardLayout': cardLayout,
  'domain': 'Crypto > Bitcoin',
  'status': status,
  'previewItems': previewItems ??
      [
        {
          'marketId': '1001',
          'yesPrice': '0.62',
          'yesBid': '0.60',
          'yesAsk': '0.64',
          'noBid': '0.36',
          'noAsk': '0.40',
        },
      ],
  'tradingStartTime': ?tradingStartTime,
  'tradingCloseTime': ?tradingCloseTime,
  'marketCount': 1,
  'totalVolumeUsd': ?totalVolumeUsd,
  'uiConfig': {'iconUrl': ''},
};

void main() {
  test('decodes a binary home item: ask drives the probability', () {
    final card = decodeEventCard(homeItem());
    expect(card.id, '900222');
    expect(card.status, TradeStatus.open);
    expect(card.pricingPending, isFalse);
    expect(card.outcomes.length, 2);
    expect(card.outcomes[0].name, 'Yes');
    expect(card.outcomes[0].prob, Decimal.fromInt(64));
    expect(card.outcomes[1].name, 'No');
    expect(card.outcomes[1].prob, Decimal.fromInt(40));
    expect(card.outcomes[0].marketId, '1001');
    expect(card.volume24h, Decimal.parse('125000.5'));
    expect(card.iconUrl, isNull);
    expect(card.closesAt, isNotNull);
  });

  test('a degenerate full-range spread is unpriced, never 0%', () {
    final card = decodeEventCard(
      homeItem(
        previewItems: [
          {'marketId': 'm1', 'yesBid': '0.01', 'yesAsk': '0.99'},
        ],
      ),
    );
    expect(card.outcomes[0].prob, isNull);
    // All outcomes unpriced ⇒ pricingPending.
    expect(card.pricingPending, isTrue);
  });

  test('ask falls back to bid, then mid, then last-traded', () {
    EventOutcome yes(Map<String, dynamic> preview) =>
        decodeEventCard(homeItem(previewItems: [preview])).outcomes[0];
    expect(yes({'yesBid': '0.33'}).prob, Decimal.fromInt(33));
    expect(yes({'midPrice': '0.42'}).prob, Decimal.fromInt(42));
    expect(yes({'yesPrice': '0.57'}).prob, Decimal.fromInt(57));
    expect(yes({}).prob, isNull);
  });

  test('status crosswalk and pricingPending for non-ACTIVE events', () {
    final settled = decodeEventCard(homeItem(status: 'SETTLED'));
    expect(settled.status, TradeStatus.settled);
    expect(settled.pricingPending, isTrue);
    expect(
      decodeEventCard(homeItem(status: 'MARKET_ADJ_PENDING')).status,
      TradeStatus.adjudicating,
    );
    expect(
      decodeEventCard(homeItem(status: 'CANCELLED')).status,
      TradeStatus.voided,
    );
  });

  test('missing volume stays null; multi-row cards render generic rows', () {
    final card = decodeEventCard(
      homeItem(
        cardLayout: 'MULTI_ROW',
        totalVolumeUsd: null,
        previewItems: [
          {'label': 'Brazil', 'marketId': 'a', 'yesAsk': '0.51'},
          {'label': 'France', 'marketId': 'b', 'yesAsk': '0.22'},
          {'label': '', 'marketId': 'c'},
        ],
      ),
    );
    expect(card.volume24h, isNull);
    expect(card.outcomes.length, 3);
    expect(card.outcomes[0].name, 'Brazil');
    expect(card.outcomes[0].prob, Decimal.fromInt(51));
    // A blank label surfaces honestly as a dash, never fabricated.
    expect(card.outcomes[2].name, '—');
  });

  test('parsePmMenu maps the three-level tree with derived ids', () {
    final nodes = parsePmMenu([
      {
        'name': 'Crypto',
        'children': [
          {
            'name': 'Bitcoin',
            'children': [
              {'name': 'Price'},
            ],
          },
        ],
      },
      {'name': 'World Cup 2026'},
    ]);
    expect(nodes.length, 2);
    expect(nodes[0].id, 'crypto');
    expect(nodes[0].children[0].id, 'bitcoin');
    expect(nodes[0].children[0].children[0].label, 'Price');
    expect(nodes[1].id, 'world-cup-2026');
    expect(parsePmMenu(null), isEmpty);
  });

  test('cardLayout maps to archetype; unknown layouts stay leaderboard', () {
    expect(decodeEventCard(homeItem()).archetype, CardArchetype.binary);
    expect(
      decodeEventCard(homeItem(cardLayout: 'MATCH')).archetype,
      CardArchetype.match,
    );
    expect(
      decodeEventCard(homeItem(cardLayout: 'MULTI_ROW')).archetype,
      CardArchetype.leaderboard,
    );
    final noLayout = homeItem()..remove('cardLayout');
    expect(decodeEventCard(noLayout).archetype, CardArchetype.leaderboard);
  });

  test('isParticipant is a wire-raw boolean flag', () {
    final fixture = homeItem(cardLayout: 'MATCH')..['isParticipant'] = true;
    expect(decodeEventCard(fixture).isParticipant, isTrue);
    expect(decodeEventCard(homeItem()).isParticipant, isFalse);
  });

  test('domain is decoded from the wire and defaults to empty', () {
    expect(decodeEventCard(homeItem()).domain, 'Crypto > Bitcoin');
    final noDomain = homeItem()..remove('domain');
    expect(decodeEventCard(noDomain).domain, '');
  });

  test('formatCompactVolume compacts to K/M/B or stays absent', () {
    expect(formatCompactVolume(Decimal.parse('52000000')), '52M');
    expect(formatCompactVolume(Decimal.parse('975000')), '975K');
    expect(formatCompactVolume(Decimal.parse('1230000000')), '1.2B');
    expect(formatCompactVolume(Decimal.parse('500')), '500');
    expect(formatCompactVolume(null), isNull);
  });
}
