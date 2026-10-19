import 'package:flutter_nexusft/core/adapters/unconfigured/unconfigured_adapter.dart';

import 'dart:async';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nexusft/app/nexus_app.dart';
import 'package:flutter_nexusft/core/api/contract.dart';
import 'package:flutter_nexusft/core/api/errors.dart';
import 'package:flutter_nexusft/core/domain/market.dart';
import 'package:flutter_nexusft/core/providers/platform_provider.dart';

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

Page<Market> emptyPage() => Page(items: [], page: 1, pageSize: 20, total: 0);

void main() {
  testWidgets('loading becomes empty only after a successful response', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final pending = Completer<Page<Market>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformApiProvider.overrideWithValue(
            FixtureApi(() => pending.future),
          ),
        ],
        child: const NexusApp(),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('marketEmpty')), findsNothing);
    pending.complete(emptyPage());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('marketEmpty')), findsOneWidget);
    expect(find.byKey(const Key('marketError')), findsNothing);
  });

  testWidgets('a failed read can be retried without inventing empty data', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    var attempts = 0;
    final api = FixtureApi(() async {
      attempts++;
      if (attempts == 1) {
        throw const PlatformError(
          PlatformErrorCode.unexpected,
          'Fixture outage',
        );
      }
      return Page(
        items: [
          const Market(
            marketId: 'fixture-btc',
            symbol: 'BTC/USDT',
            instrumentType: InstrumentType.spot,
          ),
        ],
        page: 1,
        pageSize: 20,
        total: 1,
      );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [platformApiProvider.overrideWithValue(api)],
        child: const NexusApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('marketError')), findsOneWidget);
    expect(find.byKey(const Key('marketEmpty')), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('BTC/USDT'), findsOneWidget);
    expect(attempts, 2);
  });
}
