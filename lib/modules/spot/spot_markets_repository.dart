import '../../core/api/contract.dart';
import '../../core/domain/market.dart';

class SpotMarketsRepository {
  const SpotMarketsRepository(this.api);
  final PlatformApi api;

  Future<Page<Market>> loadFirstPage() => api.catalog.markets(
    const MarketQuery(instrumentType: InstrumentType.spot),
  );
}
