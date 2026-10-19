import 'dart:io';

import 'package:flutter_nexusft/core/config/app_config.dart';
import 'package:flutter_nexusft/core/domain/market.dart';
import 'package:flutter_nexusft/core/http/dio_http.dart';
import 'package:flutter_nexusft/core/session/session_manager.dart';
import 'package:flutter_nexusft/core/storage/session_store.dart';
import 'package:flutter_nexusft/core/adapters/v1/v1_adapter.dart';

Future<void> main() async {
  final config = AppConfig.fromValues(
    'dev',
    'https://dev-nexusft-trade-api.nexuspb.com',
  );
  final session = SessionManager(
    store: MemorySessionStore(),
    scope: config.sessionScope,
  );
  final http = DioHttp(
    baseUrl: config.apiBaseUrl!,
    session: session,
    locale: () => 'en-US',
  );
  try {
    final raw = (await http.request('/market/symbol')).body;
    if (raw is! List) throw StateError('Live catalog was not an array.');
    final expected = raw
        .where((row) => row is Map && row['enable'] != 0)
        .map((row) => (row as Map)['symbol'] as String)
        .toList();
    final actual = await V1Adapter(http).catalog
        .markets(const MarketQuery(instrumentType: InstrumentType.spot));
    if (actual.total != expected.length ||
        actual.items.map((m) => m.symbol).join('|') != expected.join('|')) {
      throw StateError('Live adapter catalog differs from source response.');
    }
    stdout.writeln(
      'LIVE_CATALOG_PASS raw=${raw.length} mapped=${actual.total}',
    );
    for (final market in actual.items) {
      stdout.writeln('${market.marketId}\t${market.symbol}');
    }
  } finally {
    http.close();
    await session.dispose();
  }
}
