import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_nexusft/core/adapters/v1/v1_adapter.dart';
import 'package:flutter_nexusft/core/domain/event_card.dart';
import 'package:flutter_nexusft/core/realtime/stomp_client.dart';
import 'package:flutter_nexusft/modules/prediction/detail/event_detail_view_model.dart';

void main() {
  group('SockJS frame codec', () {
    test('decodes open / heartbeat / close / message frames', () {
      expect(sockJsDecode('o'), isA<SockJsOpen>());
      expect(sockJsDecode('h'), isA<SockJsHeartbeat>());
      expect(sockJsDecode('c[3000,"bye"]'), isA<SockJsClose>());
      final messages = sockJsDecode('a["CONNECTED\\nversion:1.2\\n\\n"]');
      expect(messages, isA<SockJsMessages>());
      expect(
        (messages as SockJsMessages).frames.single,
        'CONNECTED\nversion:1.2\n\n',
      );
      expect(sockJsDecode('x'), isNull);
    });

    test('encodes client frames as a JSON array', () {
      final frame = 'CONNECT\n\n\x00';
      expect(sockJsEncode([frame]), '["CONNECT\\n\\n\\u0000"]');
    });
  });

  group('STOMP frame codec', () {
    test('encodes command, headers and body with the null terminator', () {
      expect(
        stompEncode('SUBSCRIBE', {'id': 'sub-0', 'destination': '/topic/x'}),
        'SUBSCRIBE\nid:sub-0\ndestination:/topic/x\n\n\x00',
      );
    });

    test('decodes frames and treats a bare newline as heartbeat', () {
      expect(stompDecode('\n'), isNull);
      expect(stompDecode(''), isNull);
      final frame = stompDecode(
        'MESSAGE\ndestination:/topic/pm/auction/1\nsubscription:sub-0\n\n{"bestAsk":"0.7"}\x00',
      );
      expect(frame, isNotNull);
      expect(frame!.command, 'MESSAGE');
      expect(frame.headers['destination'], '/topic/pm/auction/1');
      expect(frame.body, '{"bestAsk":"0.7"}');
    });
  });

  group('ReconnectPolicy', () {
    test('caps consecutive failures and resets on success', () {
      final policy = ReconnectPolicy();
      for (var i = 0; i < 6; i++) {
        policy.recordFailure();
        expect(policy.canRetry, isTrue, reason: 'failure ${i + 1}');
      }
      policy.recordFailure(); // 7th consecutive failure
      expect(policy.canRetry, isFalse);
      policy.recordSuccess();
      expect(policy.canRetry, isTrue);
      expect(policy.failures, 0);
    });
  });

  group('decodeAuctionTick', () {
    test('decodes the auction frame; absent quotes stay null', () {
      final tick = decodeAuctionTick(
        '1001',
        '{"symbol":"x","indicativePrice":"0.61","bestBid":"0.60","bestAsk":"0.64"}',
      );
      expect(tick, isNotNull);
      expect(tick!.marketId, '1001');
      expect(tick.indicativePrice, Decimal.parse('0.61'));
      expect(tick.bestBid, Decimal.parse('0.60'));
      expect(tick.bestAsk, Decimal.parse('0.64'));
    });

    test('malformed frames are dropped, never fatal', () {
      expect(decodeAuctionTick('1', 'not json'), isNull);
      expect(decodeAuctionTick('1', '[1,2]'), isNull);
      final partial = decodeAuctionTick('1', '{"bestAsk":"0.5"}');
      expect(partial!.bestAsk, Decimal.parse('0.5'));
      expect(partial.bestBid, isNull);
    });
  });

  group('decodeEventDetail', () {
    Map<String, dynamic> detailWire() => {
      'id': '309',
      'title': 'Everton FC vs. Chelsea FC',
      'itemType': 'WINNER',
      'status': 'ACTIVE',
      'markets': [
        {
          'id': 10004368,
          'title': 'Everton',
          'midPrice': '0.42',
          'yesBid': '0.40',
          'yesAsk': '0.44',
          'tradingPairs': [
            {'tokenSide': 'YES', 'currentPrice': '0.41'},
          ],
        },
        {'id': 10004369, 'title': 'Chelsea', 'yesAsk': '0.35'},
      ],
      'tradingCloseTime': 1790000000000,
      'startTime': 1790100000000,
      'tradingStartTime': 1760000000000,
      'totalVolumeUsd': '125000.5',
      'liquidity': '4200',
      'resolutionRule': 'Resolves to the official result.',
      'resolutionSourceUrl': 'https://example.com/rules',
      'uiConfig': {'iconUrl': 'https://example.com/icon.png'},
    };

    test('maps legs to outcome rows with ask-driven probabilities', () {
      final detail = decodeEventDetail(detailWire());
      expect(detail.id, '309');
      expect(detail.status, TradeStatus.open);
      expect(detail.outcomes.length, 2);
      expect(detail.outcomes[0].name, 'Everton');
      expect(detail.outcomes[0].marketId, '10004368');
      expect(detail.outcomes[0].prob, Decimal.fromInt(44));
      expect(detail.outcomes[1].prob, Decimal.fromInt(35));
      expect(detail.volume, Decimal.parse('125000.5'));
      expect(detail.liquidity, Decimal.parse('4200'));
      expect(detail.resolutionRule, 'Resolves to the official result.');
      expect(detail.resolutionSourceUrl, 'https://example.com/rules');
      expect(detail.iconUrl, 'https://example.com/icon.png');
      expect(detail.closesAt, isNotNull);
      expect(detail.startsAt, isNotNull);
      expect(detail.tradingStartsAt, isNotNull);
    });

    test('SINGLE itemType yields the canonical Yes/No pair', () {
      final wire = detailWire()
        ..['itemType'] = 'SINGLE'
        ..['markets'] = [
          {'id': 7, 'yesAsk': '0.64', 'noAsk': '0.36'},
        ];
      final detail = decodeEventDetail(wire);
      expect(detail.outcomes.map((o) => o.name), ['Yes', 'No']);
      expect(detail.outcomes[0].prob, Decimal.fromInt(64));
      expect(detail.outcomes[1].prob, Decimal.fromInt(36));
    });

    test('absent money and rule fields stay null', () {
      final wire = detailWire()
        ..remove('totalVolumeUsd')
        ..remove('liquidity')
        ..remove('resolutionRule')
        ..remove('resolutionSourceUrl');
      final detail = decodeEventDetail(wire);
      expect(detail.volume, isNull);
      expect(detail.liquidity, isNull);
      expect(detail.resolutionRule, isNull);
      expect(detail.resolutionSourceUrl, isNull);
    });
  });

  group('liveProbOf', () {
    test('ask first, bid fallback, degenerate spread skipped', () {
      expect(
        liveProbOf(bestBid: Decimal.parse('0.60'), bestAsk: Decimal.parse('0.64')),
        Decimal.fromInt(64),
      );
      expect(liveProbOf(bestBid: Decimal.parse('0.33')), Decimal.fromInt(33));
      expect(
        liveProbOf(bestBid: Decimal.parse('0.01'), bestAsk: Decimal.parse('0.99')),
        isNull,
      );
      expect(liveProbOf(), isNull);
    });
  });
}
