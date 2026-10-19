import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../tokens/trading_tokens.dart';

/// Numeric price/quantity text with tabular figures. Null renders as `--`;
/// values are never invented or zero-filled.
class PriceText extends StatelessWidget {
  const PriceText({super.key, required this.value, this.style, this.color});

  final Decimal? value;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base =
        style ??
        TradingText.priceMedium(
          color ?? Theme.of(context).colorScheme.onSurface,
        );
    return Text(
      value?.toString() ?? '--',
      style: base.copyWith(
        color: color ?? base.color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
