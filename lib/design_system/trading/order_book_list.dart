import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../tokens/app_typography.dart';
import '../tokens/trading_tokens.dart';
import 'order_book_entry.dart';
import 'price_text.dart';

/// Order book list: asks on top, optional mid price, bids below.
/// Entries with null price/quantity render `--` placeholder rows; no
/// market values are ever invented.
class OrderBookList extends StatelessWidget {
  const OrderBookList({
    super.key,
    required this.asks,
    required this.bids,
    this.midPrice,
    this.midChange,
  });

  final List<OrderBookEntry> asks;
  final List<OrderBookEntry> bids;
  final Decimal? midPrice;
  final Decimal? midChange;

  /// Largest quantity of one side; null when no level has a quantity.
  static Decimal? _maxQuantity(List<OrderBookEntry> entries) {
    Decimal? max;
    for (final entry in entries) {
      final quantity = entry.quantity;
      if (quantity != null && (max == null || quantity > max)) {
        max = quantity;
      }
    }
    return max;
  }

  /// Share of the row's quantity within its side (0–1), for the depth bar.
  static double _depthFraction(OrderBookEntry entry, Decimal? max) {
    final quantity = entry.quantity;
    if (quantity == null || max == null || max <= Decimal.zero) return 0;
    return (quantity / max).toDouble().clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final trading = TradingColors.of(context);
    final colors = Theme.of(context).colorScheme;
    final maxAsk = _maxQuantity(asks);
    final maxBid = _maxQuantity(bids);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in asks)
          _OrderBookRow(
            entry: entry,
            depthFraction: _depthFraction(entry, maxAsk),
          ),
        SizedBox(
          height: 30,
          child: Row(
            children: [
              PriceText(
                value: midPrice,
                style: AppNumber.medium(
                  midPrice == null
                      ? colors.onSurfaceVariant
                      : (midChange != null && midChange! < Decimal.zero
                            ? trading.down
                            : trading.up),
                ),
              ),
            ],
          ),
        ),
        for (final entry in bids)
          _OrderBookRow(
            entry: entry,
            depthFraction: _depthFraction(entry, maxBid),
          ),
      ],
    );
  }
}

class _OrderBookRow extends StatelessWidget {
  const _OrderBookRow({required this.entry, required this.depthFraction});

  final OrderBookEntry entry;

  /// 0–1 share of this side's max quantity; 0 hides the depth bar.
  final double depthFraction;

  @override
  Widget build(BuildContext context) {
    final trading = TradingColors.of(context);
    final colors = Theme.of(context).colorScheme;
    final isAsk = entry.side == OrderBookSide.ask;
    return SizedBox(
      height: TradingMetrics.orderBookRowHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (depthFraction > 0)
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: depthFraction,
                heightFactor: 1,
                child: ColoredBox(
                  color: isAsk ? trading.askDepth : trading.bidDepth,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: PriceText(
                  value: entry.price,
                  color: isAsk ? trading.down : trading.up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: PriceText(
                    value: entry.quantity,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
