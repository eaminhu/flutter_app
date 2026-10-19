import 'package:flutter/material.dart';

import '../tokens/trading_tokens.dart';

/// Buy/sell ratio bar. A null [buyPercent] renders a neutral placeholder:
/// the ratio is never invented while the quote feed is disconnected.
class BuySellRatioBar extends StatelessWidget {
  const BuySellRatioBar({super.key, required this.buyPercent});

  /// 0-100. Null renders a neutral bar with `--`.
  final int? buyPercent;

  @override
  Widget build(BuildContext context) {
    final trading = TradingColors.of(context);
    final colors = Theme.of(context).colorScheme;
    final buyPercent = this.buyPercent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  flex: buyPercent ?? 50,
                  child: ColoredBox(
                    color: buyPercent == null
                        ? colors.outlineVariant
                        : trading.up,
                  ),
                ),
                Expanded(
                  flex: buyPercent == null ? 50 : 100 - buyPercent,
                  child: ColoredBox(
                    color: buyPercent == null
                        ? colors.outlineVariant
                        : trading.down,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              buyPercent == null ? '--' : '$buyPercent%',
              style: TradingText.caption(trading.up),
            ),
            Text(
              buyPercent == null ? '--' : '${100 - buyPercent}%',
              style: TradingText.caption(trading.down),
            ),
          ],
        ),
      ],
    );
  }
}
