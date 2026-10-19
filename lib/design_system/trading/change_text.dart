import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../tokens/trading_tokens.dart';

/// Percent change text colored by direction: positive uses the up color,
/// negative the down color. Null renders as a neutral `--`.
class ChangeText extends StatelessWidget {
  const ChangeText({super.key, required this.percent, this.style});

  /// Signed percent value, e.g. Decimal.parse('2.22') renders `+2.22%`.
  final Decimal? percent;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final trading = TradingColors.of(context);
    final percent = this.percent;
    final Color color;
    final String text;
    if (percent == null) {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
      text = '--';
    } else {
      final negative = percent < Decimal.zero;
      color = negative ? trading.down : trading.up;
      text = '${negative ? '' : '+'}${percent.toString()}%';
    }
    return Text(
      text,
      style:
          (style ?? TradingText.priceMedium(color)).copyWith(
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
