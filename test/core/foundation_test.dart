import 'package:flutter_nexusft/core/adapters/unconfigured/unconfigured_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nexusft/core/config/app_config.dart';
import 'package:flutter_nexusft/core/api/contract.dart';
import 'package:flutter_nexusft/core/api/errors.dart';
import 'package:flutter_nexusft/core/domain/market.dart';
import 'package:flutter_nexusft/core/domain/preferences.dart';
import 'package:flutter_nexusft/core/localization/strings.dart';
import 'package:flutter_nexusft/core/providers/platform_provider.dart';
import 'package:flutter_nexusft/modules/spot/spot_markets_view_model.dart';

class FailingApi implements PlatformApi, CatalogApi {
  @override
  AuthApi get auth => const UnconfiguredAdapter().auth;
  @override
  PredictionApi get prediction => const UnconfiguredAdapter().prediction;
  @override
  RealtimeApi get realtime => const UnconfiguredAdapter().realtime;
  FailingApi(this.failure);
  final PlatformError failure;
  int requests = 0;
  @override
  CatalogApi get catalog => this;
  @override
  Future<Page<Market>> markets(MarketQuery query) async {
    requests++;
    expect(query.instrumentType, InstrumentType.spot);
    throw failure;
  }
}

void main() {
  test(
    'unknown environment refuses instead of choosing production or mock',
    () {
      for (final environment in AppEnvironment.values) {
        expect(AppConfig.fromValue(environment.name).environment, environment);
      }
      expect(
        () => AppConfig.fromValue('production-typo'),
        throwsFormatException,
      );
    },
  );
  test('three language trees contain every canonical key', () {
    for (final language in AppLanguage.values) {
      expect(translations[language]!.keys.toSet(), AppText.values.toSet());
      for (final key in AppText.values) {
        expect(translatedText(language, key).trim(), isNotEmpty);
      }
    }
  });
  test(
    'failed catalog read stays an error and does not automatically retry',
    () async {
      const failure = PlatformError(
        PlatformErrorCode.unexpected,
        'Test failure',
      );
      final api = FailingApi(failure);
      final container = ProviderContainer(
        overrides: [platformApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        spotMarketsProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);
      await expectLater(
        container.read(spotMarketsProvider.future),
        throwsA(same(failure)),
      );
      expect(container.read(spotMarketsProvider).hasError, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(api.requests, 1);
    },
  );
  test('a page cannot change through a mutable source list', () {
    final source = <Market>[];
    final page = Page(items: source, page: 1, pageSize: 20, total: 0);
    source.add(
      const Market(
        marketId: 'fixture',
        symbol: 'TEST/USD',
        instrumentType: InstrumentType.spot,
      ),
    );
    expect(page.items, isEmpty);
    expect(() => page.items.add(source.first), throwsUnsupportedError);
  });
}
