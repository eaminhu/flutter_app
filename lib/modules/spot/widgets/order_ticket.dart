import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/domain/session.dart';
import '../../../core/providers/session_provider.dart';
import '../../../design_system/tokens/app_radius.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../design_system/tokens/trading_tokens.dart';
import '../../../design_system/trading/percent_selector.dart';
import '../../../design_system/trading/trade_side_switch.dart';
import '../spot_markets_view_model.dart';

class _TicketCta extends StatelessWidget {
  const _TicketCta({
    super.key,
    required this.color,
    required this.textColor,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final Color textColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      borderRadius: AppRadius.mdAll,
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: AppInsets.h(AppSpacing.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadius.mdAll,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.body(
            textColor,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}

(String, String) _symbolUnits(String? symbol) {
  if (symbol == null) return ('', '');
  final parts = symbol.split('/');
  if (parts.length != 2) return (symbol, '');
  return (parts[0], parts[1]);
}

/// Order ticket (demo): limit-order select, price/quantity/amount inputs,
/// percent selector, TP/SL checkbox. No value is computed or submitted;
/// the quote feed and trade-write path are not connected.
class OrderTicket extends ConsumerStatefulWidget {
  const OrderTicket({super.key});

  @override
  ConsumerState<OrderTicket> createState() => _OrderTicketState();
}

class _OrderTicketState extends ConsumerState<OrderTicket> {
  final _price = TextEditingController();
  final _quantity = TextEditingController();
  final _amount = TextEditingController();
  TradeSide _side = TradeSide.buy;
  int? _percent;
  bool _tpSl = false;

  @override
  void dispose() {
    _price.dispose();
    _quantity.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _hint(String message) {
    showFToast(context: context, title: Text(message));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final market = ref.watch(spotSelectedMarketProvider);
    final authenticated =
        ref.watch(sessionStateProvider).status == SessionStatus.authenticated;
    final trading = TradingColors.of(context);
    final colors = Theme.of(context).colorScheme;
    final (base, quote) = _symbolUnits(market?.symbol);
    String unit(String label, String symbol) =>
        symbol.isEmpty ? label : '$label($symbol)';

    return SingleChildScrollView(
      key: const Key('orderTicket'),
      padding: const EdgeInsets.symmetric(
        horizontal: TradingMetrics.pagePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TradeSideSwitch(
            key: const Key('tradeSideSwitch'),
            value: _side,
            onChanged: (side) => setState(() => _side = side),
            buyLabel: strings.text(AppText.buy),
            sellLabel: strings.text(AppText.sell),
          ),
          const SizedBox(height: TradingMetrics.formGap),
          FSelect<String>.rich(
            key: const Key('orderTypeSelect'),
            control: const FSelectControl.managed(initial: 'limit'),
            format: (value) => strings.text(
              value == 'limit' ? AppText.limitOrder : AppText.marketOrder,
            ),
            children: [
              FSelectItem.item(
                title: Text(strings.text(AppText.limitOrder)),
                value: 'limit',
              ),
              FSelectItem.item(
                title: Text(strings.text(AppText.marketOrder)),
                value: 'market',
                enabled: false,
              ),
            ],
          ),
          const SizedBox(height: TradingMetrics.formGap),
          FTextField(
            key: const Key('orderPriceField'),
            control: FTextFieldControl.managed(controller: _price),
            label: Text(unit(strings.text(AppText.price), quote)),
            hint: '--',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            suffixBuilder: (context, style, variants) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: TextButton(
                key: const Key('bestPriceButton'),
                onPressed: () =>
                    _hint(strings.text(AppText.marketDataUnavailable)),
                child: Text(strings.text(AppText.bestPrice)),
              ),
            ),
          ),
          const SizedBox(height: TradingMetrics.formGap),
          FTextField(
            key: const Key('orderQuantityField'),
            control: FTextFieldControl.managed(controller: _quantity),
            label: Text(unit(strings.text(AppText.quantity), base)),
            hint: '--',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(height: TradingMetrics.formGap),
          PercentSelector(
            key: const Key('percentSelector'),
            selected: _percent,
            onChanged: (value) => setState(() => _percent = value),
          ),
          const SizedBox(height: TradingMetrics.formGap),
          FTextField(
            key: const Key('orderAmountField'),
            control: FTextFieldControl.managed(controller: _amount),
            label: Text(unit(strings.text(AppText.amount), quote)),
            hint: '--',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(height: TradingMetrics.formGap),
          _infoRow(
            strings.text(AppText.available),
            '--${quote.isEmpty ? '' : ' $quote'}',
            colors,
          ),
          AppGap.v4,
          _infoRow(
            strings.text(AppText.canBuy),
            '--${base.isEmpty ? '' : ' $base'}',
            colors,
          ),
          FCheckbox(
            key: const Key('tpSlCheckbox'),
            value: _tpSl,
            onChange: (value) => setState(() => _tpSl = value),
            label: Text(strings.text(AppText.takeProfitStopLoss)),
          ),
          const SizedBox(height: TradingMetrics.formGap),
          _TicketCta(
            key: const Key('orderCta'),
            color: !authenticated
                ? colors.primary
                : (_side == TradeSide.buy ? trading.up : trading.down),
            textColor: !authenticated ? colors.onPrimary : Colors.white,
            label: !authenticated
                ? strings.text(AppText.signInOrRegister)
                : (_side == TradeSide.buy
                      ? strings.text(AppText.buy)
                      : strings.text(AppText.sell)),
            onTap: !authenticated
                ? () => context.go('/login')
                : () => _hint(strings.text(AppText.tradeWriteUnavailable)),
          ),
          const SizedBox(height: TradingMetrics.formGap),
          _infoRow(strings.text(AppText.highestBid), '--', colors),
          AppGap.v4,
          _infoRow(strings.text(AppText.feeRate), '--', colors),
          const SizedBox(height: TradingMetrics.formGap),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, ColorScheme colors) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: AppTextStyle.caption(colors.onSurfaceVariant)),
      Text(
        value,
        style: AppTextStyle.caption(colors.onSurface),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
