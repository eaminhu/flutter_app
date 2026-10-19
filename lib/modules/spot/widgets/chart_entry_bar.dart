import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../app/localization/app_localizations.dart';
import '../spot_markets_view_model.dart';
import 'spot_top_bar.dart';

/// Bottom chart entry bar (placeholder): tapping only hints that the chart
/// is not connected; Lightweight Charts is out of scope for this stage.
class ChartEntryBar extends ConsumerWidget {
  const ChartEntryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final market = ref.watch(spotSelectedMarketProvider);
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: InkWell(
        key: const Key('chartEntryBar'),
        onTap: () => showComingSoon(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                FLucideIcons.candlestickChart,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${market?.symbol ?? '--'} ${strings.text(AppText.chart)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                FLucideIcons.chevronUp,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
