import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import '../tokens/trading_tokens.dart';

/// Quick percent selector (0/25/50/75/100%). Pure UI state in the demo:
/// selection does not compute amounts until the quote feed is connected.
class PercentSelector extends StatelessWidget {
  const PercentSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.values = const [0, 25, 50, 75, 100],
  });

  final int? selected;
  final ValueChanged<int> onChanged;
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trading = TradingColors.of(context);
    return Row(
      children: [
        for (final value in values) ...[
          if (value != values.first) AppGap.h4,
          Expanded(
            child: InkWell(
              key: Key('percent$value'),
              borderRadius: AppRadius.pillAll,
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected == value
                      ? colors.onSurface.withValues(alpha: 0.12)
                      : trading.surfaceRaised,
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(
                  '$value%',
                  style: AppTextStyle.caption(
                    selected == value
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
