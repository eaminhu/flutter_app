import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/api/errors.dart';
import '../../design_system/primitives/page_status.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/trading_tokens.dart';
import 'spot_markets_view_model.dart';
import 'widgets/chart_entry_bar.dart';
import 'widgets/order_book_panel.dart';
import 'widgets/order_ticket.dart';
import 'widgets/orders_tabs.dart';
import 'widgets/pair_header.dart';

/// Spot trading body. The shell's TradeHomeScreen hosts the top bar and the
/// instrument tabs; this widget keeps the catalog three-state logic.
class SpotScreen extends ConsumerWidget {
  const SpotScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final markets = ref.watch(spotMarketsProvider);
    return markets.when(
      skipLoadingOnRefresh: false,
      loading: () => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
          semanticsLabel: strings.text(AppText.loading),
        ),
      ),
      error: (error, stack) {
        final disconnected =
            error is PlatformError &&
            error.code == PlatformErrorCode.backendNotConfigured;
        final retryable = error is! PlatformError || error.retryable;
        return PageStatus(
          key: const Key('marketError'),
          message: strings.text(
            disconnected ? AppText.disconnected : AppText.marketUnavailable,
          ),
          icon: Icons.cloud_off_outlined,
          actionLabel: retryable ? strings.text(AppText.retry) : null,
          onAction: retryable
              ? () => ref.read(spotMarketsProvider.notifier).retry()
              : null,
        );
      },
      data: (page) => page.items.isEmpty
          ? PageStatus(
              key: const Key('marketEmpty'),
              message: strings.text(AppText.noMarkets),
              icon: Icons.search_off_outlined,
            )
          : const _SpotTradingBody(),
    );
  }
}

class _SpotTradingBody extends StatelessWidget {
  const _SpotTradingBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PairHeader(),
        AppGap.v4,
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: SingleChildScrollView(child: OrderTicket()),
              ),
              SizedBox(width: TradingMetrics.columnGutter),
              Expanded(flex: 4, child: OrderBookPanel()),
            ],
          ),
        ),
        ChartEntryBar(),
        Expanded(child: OrdersTabs()),
      ],
    );
  }
}
