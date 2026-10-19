import 'package:flutter/material.dart';

import '../tokens/trading_tokens.dart';

/// Trade direction for the order ticket.
enum TradeSide { buy, sell }

/// Buy/sell segmented switch. Buy uses the up color, sell the down color.
class TradeSideSwitch extends StatelessWidget {
  const TradeSideSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.buyLabel,
    required this.sellLabel,
  });

  final TradeSide value;
  final ValueChanged<TradeSide> onChanged;
  final String buyLabel;
  final String sellLabel;

  @override
  Widget build(BuildContext context) {
    final trading = TradingColors.of(context);
    final colors = Theme.of(context).colorScheme;
    Widget segment(TradeSide side, String label, Color active, Key key) {
      final selected = value == side;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(8),
            onTap: () => onChanged(side),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? active : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trading.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          segment(TradeSide.buy, buyLabel, trading.up, const Key('tradeBuy')),
          segment(TradeSide.sell, sellLabel, trading.down, const Key('tradeSell')),
        ],
      ),
    );
  }
}
