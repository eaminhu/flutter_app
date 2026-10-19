import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/market.dart';
import '../../core/domain/session.dart';
import '../../core/providers/platform_provider.dart';
import '../../core/providers/session_provider.dart';
import 'spot_markets_repository.dart';

final spotMarketsProvider =
    AsyncNotifierProvider<SpotMarketsViewModel, Page<Market>>(
      SpotMarketsViewModel.new,
      name: 'spotMarkets',
      retry: (retryCount, error) => null,
    );

/// Explicitly selected market id. Null means "first catalog entry".
final spotSelectedMarketIdProvider =
    NotifierProvider<SpotSelectedMarketId, String?>(
      SpotSelectedMarketId.new,
      name: 'spotSelectedMarketId',
    );

class SpotSelectedMarketId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String marketId) => state = marketId;
}

/// The effective selected market: the explicit selection if it still exists
/// in the loaded catalog, otherwise the first catalog entry.
final spotSelectedMarketProvider = Provider<Market?>((ref) {
  final items = ref.watch(spotMarketsProvider).value?.items;
  if (items == null || items.isEmpty) return null;
  final id = ref.watch(spotSelectedMarketIdProvider);
  if (id == null) return items.first;
  for (final market in items) {
    if (market.marketId == id) return market;
  }
  return items.first;
}, name: 'spotSelectedMarket');

class SpotMarketsViewModel extends AsyncNotifier<Page<Market>> {
  @override
  Future<Page<Market>> build() {
    ref.watch(
      sessionStateProvider.select(
        (s) => (s.generation, s.status == SessionStatus.authenticated),
      ),
    );
    return SpotMarketsRepository(ref.watch(platformApiProvider))
        .loadFirstPage();
  }

  void retry() => ref.invalidateSelf();
}
