import 'package:decimal/decimal.dart';

/// Order book side.
enum OrderBookSide { bid, ask }

/// A single order book level. Pure Dart value type; the real market-depth
/// contract will be defined in core/domain once the quote feed is connected.
class OrderBookEntry {
  const OrderBookEntry({required this.side, this.price, this.quantity});

  final OrderBookSide side;

  /// Null until the quote feed is connected; renders as `--`.
  final Decimal? price;

  /// Null until the quote feed is connected; renders as `--`.
  final Decimal? quantity;
}
