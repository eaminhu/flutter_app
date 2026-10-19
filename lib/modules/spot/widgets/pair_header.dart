import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../design_system/primitives/app_list_row.dart';
import '../../../design_system/tokens/app_radius.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../design_system/tokens/trading_tokens.dart';
import '../../../design_system/trading/change_text.dart';
import '../../../design_system/trading/price_text.dart';
import '../spot_markets_view_model.dart';

/// Selected pair header: symbol (tap opens the real catalog picker), the
/// latest price with a change capsule, and a 24h high/low/volume strip.
/// Quote fields are not connected yet, so they render `--` placeholders.
class PairHeader extends ConsumerWidget {
  const PairHeader({super.key});

  Future<void> _selectMarket(BuildContext context, WidgetRef ref) async {
    final strings = AppLocalizations.of(context);
    final items = ref.read(spotMarketsProvider).value?.items ?? const [];
    if (items.isEmpty) return;
    final selected = ref.read(spotSelectedMarketProvider);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                strings.text(AppText.selectMarket),
                style: AppTextStyle.heading(Theme.of(context).colorScheme.onSurface),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final market in items)
                    AppListRow(
                      key: ValueKey('marketOption.${market.marketId}'),
                      title: market.symbol,
                      trailing: market.marketId == selected?.marketId
                          ? const Icon(FLucideIcons.check)
                          : null,
                      onTap: () {
                        ref
                            .read(spotSelectedMarketIdProvider.notifier)
                            .select(market.marketId);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final market = ref.watch(spotSelectedMarketProvider);
    final colors = Theme.of(context).colorScheme;
    final trading = TradingColors.of(context);
    return Padding(
      key: const Key('pairHeader'),
      padding: const EdgeInsets.symmetric(
        horizontal: TradingMetrics.pagePadding,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InkWell(
                key: const Key('pairSelector'),
                borderRadius: AppRadius.smAll,
                onTap: () => _selectMarket(context, ref),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      market?.symbol ?? '--',
                      style: AppTextStyle.heading(colors.onSurface),
                    ),
                    AppGap.h2,
                    Icon(
                      FLucideIcons.chevronDown,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Quote feed is not connected: null renders `--` in a
                  // neutral color instead of a fabricated up/down color.
                  PriceText(
                    key: const Key('pairLastPrice'),
                    value: null,
                    style: AppNumber.large(colors.onSurfaceVariant),
                  ),
                  AppGap.v2,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: trading.surfaceRaised,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: const ChangeText(
                      key: Key('pairChange'),
                      percent: null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppGap.v4,
          Row(
            children: [
              _Stat(label: strings.text(AppText.high24h)),
              _Stat(label: strings.text(AppText.low24h)),
              _Stat(label: strings.text(AppText.volume24h)),
            ],
          ),
        ],
      ),
    );
  }
}

/// One 24h stat column. Values stay `--` until the quote feed provides them.
class _Stat extends StatelessWidget {
  const _Stat({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.caption(colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '--',
            style: AppNumber.small(colors.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
