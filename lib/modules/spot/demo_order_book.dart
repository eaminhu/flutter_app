import 'dart:math';

import 'package:decimal/decimal.dart';

import '../../design_system/trading/order_book_entry.dart';

/// Demo order book snapshot. Generated locally for UI development only;
/// clearly labelled as demo data in the UI and never sent to any API.
class DemoOrderBook {
  const DemoOrderBook({
    required this.asks,
    required this.bids,
    required this.midPrice,
    required this.midChangePercent,
    required this.buyPercent,
  });

  /// Highest ask first.
  final List<OrderBookEntry> asks;

  /// Nearest bid first.
  final List<OrderBookEntry> bids;
  final Decimal midPrice;

  /// Signed percent, e.g. -2.50 means down 2.5%.
  final Decimal midChangePercent;

  /// 0-100.
  final int buyPercent;
}

/// Builds a deterministic demo book for [symbol]: the same symbol always
/// yields the same numbers so rebuilds and hot reloads stay stable.
DemoOrderBook demoOrderBook(String symbol, {int levels = 7}) {
  final random = Random(symbol.hashCode);

  const magnitudes = [1, 10, 100, 1000, 10000];
  final magnitude = magnitudes[random.nextInt(magnitudes.length)];
  final priceDecimals = magnitude >= 1000 ? 1 : 2;

  Decimal price(double value) =>
      Decimal.parse(value.toStringAsFixed(priceDecimals));
  Decimal quantity(double value) => Decimal.parse(value.toStringAsFixed(4));

  final midValue = magnitude * (0.5 + random.nextDouble());
  final mid = price(midValue);

  final asks = <OrderBookEntry>[];
  final bids = <OrderBookEntry>[];
  for (var i = 0; i < levels; i += 1) {
    final step = midValue * 0.0002 * (i + 1) * (0.6 + random.nextDouble() * 0.8);
    asks.add(
      OrderBookEntry(
        side: OrderBookSide.ask,
        price: price(midValue + step),
        quantity: quantity(0.001 + random.nextDouble() * 3),
      ),
    );
    bids.add(
      OrderBookEntry(
        side: OrderBookSide.bid,
        price: price(midValue - step),
        quantity: quantity(0.001 + random.nextDouble() * 3),
      ),
    );
  }

  return DemoOrderBook(
    asks: asks.reversed.toList(),
    bids: bids,
    midPrice: mid,
    midChangePercent: Decimal.parse(
      (random.nextDouble() * 10 - 5).toStringAsFixed(2),
    ),
    buyPercent: 20 + random.nextInt(61),
  );
}
