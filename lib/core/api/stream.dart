import 'package:decimal/decimal.dart';

/// One PM auction tick (v1 /topic/pm/auction/{marketId}).
/// Absent quotes stay null — never zero-filled.
class AuctionTick {
  const AuctionTick({
    required this.marketId,
    this.indicativePrice,
    this.bestBid,
    this.bestAsk,
  });

  final String marketId;
  final Decimal? indicativePrice;
  final Decimal? bestBid;
  final Decimal? bestAsk;
}

abstract interface class RealtimeApi {
  /// Watches one market's auction channel. Multiple watchers share one
  /// STOMP subscription (reference counted); the stream never fabricates
  /// ticks — a market that has not quoted simply emits nothing.
  Stream<AuctionTick> watchAuction(String marketId);

  /// App-resume hook: reconnect immediately when the socket is down.
  void revalidate();
}
