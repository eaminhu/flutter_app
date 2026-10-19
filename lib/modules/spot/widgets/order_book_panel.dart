import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../design_system/tokens/trading_tokens.dart';
import '../../../design_system/trading/buy_sell_ratio_bar.dart';
import '../../../design_system/trading/order_book_list.dart';
import '../demo_order_book.dart';
import '../spot_markets_view_model.dart';

/// Order book panel (demo): locally generated demo levels labelled as demo
/// data; no market values come from or are sent to any API.
class OrderBookPanel extends ConsumerWidget {
  const OrderBookPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final market = ref.watch(spotSelectedMarketProvider);
    final colors = Theme.of(context).colorScheme;
    final symbol = market?.symbol ?? '';
    final parts = symbol.split('/');
    final base = parts.length == 2 ? parts[0] : '';
    final quote = parts.length == 2 ? parts[1] : '';
    String unit(String label, String symbol) =>
        symbol.isEmpty ? label : '$label($symbol)';

    final book = demoOrderBook(symbol.isEmpty ? '--' : symbol);

    return Padding(
      key: const Key('orderBookPanel'),
      padding: const EdgeInsets.only(right: TradingMetrics.pagePadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  unit(strings.text(AppText.price), quote),
                  style: AppTextStyle.caption(colors.onSurfaceVariant),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppGap.h8,
              Expanded(
                child: Text(
                  unit(strings.text(AppText.quantity), base),
                  style: AppTextStyle.caption(colors.onSurfaceVariant),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppGap.v4,
          Text(
            strings.text(AppText.demoData),
            key: const Key('orderBookDemoHint'),
            style: AppTextStyle.caption(colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          AppGap.v4,
          OrderBookList(
            asks: book.asks,
            bids: book.bids,
            midPrice: book.midPrice,
            midChange: book.midChangePercent,
          ),
          AppGap.v8,
          BuySellRatioBar(
            key: const Key('buySellRatioBar'),
            buyPercent: book.buyPercent,
          ),
          ],
        ),
      ),
    );
  }
}
