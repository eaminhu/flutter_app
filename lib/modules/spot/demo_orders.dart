import 'dart:math';

import 'package:decimal/decimal.dart';

import 'demo_order_book.dart';

/// Demo order/position snapshot. Generated locally for UI development only;
/// clearly labelled as demo data in the UI and never sent to any API.
/// Same symbol always yields the same numbers (deterministic seed).

enum DemoOrderStatus { filled, canceled }

class DemoOpenOrder {
  const DemoOpenOrder({
    required this.isBuy,
    required this.price,
    required this.quantity,
    required this.filledPercent,
    required this.time,
  });

  final bool isBuy;
  final Decimal price;
  final Decimal quantity;

  /// 0-100.
  final int filledPercent;
  final DateTime time;
}

class DemoHistoryOrder {
  const DemoHistoryOrder({
    required this.isBuy,
    required this.price,
    required this.quantity,
    required this.status,
    required this.time,
  });

  final bool isBuy;
  final Decimal price;
  final Decimal quantity;
  final DemoOrderStatus status;
  final DateTime time;
}

class DemoPosition {
  const DemoPosition({
    required this.currency,
    required this.amount,
    required this.costPrice,
    required this.currentPrice,
  });

  final String currency;
  final Decimal amount;
  final Decimal costPrice;
  final Decimal currentPrice;

  Decimal get pnl => (currentPrice - costPrice) * amount;

  Decimal get pnlPercent => costPrice == Decimal.zero
      ? Decimal.zero
      : ((currentPrice - costPrice) * Decimal.fromInt(100) / costPrice)
            .toDecimal(scaleOnInfinitePrecision: 4);
}

class DemoOrderBookSection {
  const DemoOrderBookSection({
    required this.openOrders,
    required this.history,
    required this.positions,
  });

  final List<DemoOpenOrder> openOrders;
  final List<DemoHistoryOrder> history;
  final List<DemoPosition> positions;
}

/// Fixed base instant so demo times never depend on the wall clock.
final _baseTime = DateTime.utc(2026, 10, 14, 9, 30);

DemoOrderBookSection demoOrders(String symbol) {
  final random = Random('orders:$symbol'.hashCode);
  final parts = symbol.split('/');
  final base = parts.length == 2 ? parts[0] : symbol;

  Decimal price(double v) => Decimal.parse(v.toStringAsFixed(2));
  Decimal quantity(double v) => Decimal.parse(v.toStringAsFixed(4));

  // Anchor order/position prices to the demo order book's mid price so the
  // whole page tells one coherent (clearly labelled) demo story.
  final anchor = double.parse(demoOrderBook(symbol).midPrice.toString());
  final open = <DemoOpenOrder>[
    DemoOpenOrder(
      isBuy: true,
      price: price(anchor * 0.998),
      quantity: quantity(0.01 + random.nextDouble()),
      filledPercent: random.nextInt(60),
      time: _baseTime.subtract(const Duration(minutes: 12)),
    ),
    DemoOpenOrder(
      isBuy: false,
      price: price(anchor * 1.002),
      quantity: quantity(0.01 + random.nextDouble()),
      filledPercent: random.nextInt(40),
      time: _baseTime.subtract(const Duration(minutes: 47)),
    ),
  ];
  final history = <DemoHistoryOrder>[
    DemoHistoryOrder(
      isBuy: true,
      price: price(anchor * 0.995),
      quantity: quantity(0.02 + random.nextDouble()),
      status: DemoOrderStatus.filled,
      time: _baseTime.subtract(const Duration(hours: 2)),
    ),
    DemoHistoryOrder(
      isBuy: false,
      price: price(anchor * 1.005),
      quantity: quantity(0.02 + random.nextDouble()),
      status: DemoOrderStatus.filled,
      time: _baseTime.subtract(const Duration(hours: 5)),
    ),
    DemoHistoryOrder(
      isBuy: true,
      price: price(anchor * 0.99),
      quantity: quantity(0.02 + random.nextDouble()),
      status: DemoOrderStatus.canceled,
      time: _baseTime.subtract(const Duration(hours: 9)),
    ),
  ];
  final cost = anchor * (0.9 + random.nextDouble() * 0.1);
  final positions = <DemoPosition>[
    DemoPosition(
      currency: base,
      amount: quantity(0.05 + random.nextDouble()),
      costPrice: price(cost),
      currentPrice: price(anchor),
    ),
  ];
  return DemoOrderBookSection(
    openOrders: open,
    history: history,
    positions: positions,
  );
}
