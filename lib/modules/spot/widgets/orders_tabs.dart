import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/domain/session.dart';
import '../../../core/providers/session_provider.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../design_system/tokens/trading_tokens.dart';
import '../demo_orders.dart';
import '../spot_markets_view_model.dart';

/// Orders / positions section below the chart entry (demo data, labelled).
/// Anonymous users see a sign-in banner above the demo lists.
class OrdersTabs extends ConsumerStatefulWidget {
  const OrdersTabs({super.key});

  @override
  ConsumerState<OrdersTabs> createState() => _OrdersTabsState();
}

class _OrdersTabsState extends ConsumerState<OrdersTabs> {
  int _tab = 0;

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final trading = TradingColors.of(context);
    final market = ref.watch(spotSelectedMarketProvider);
    final authenticated =
        ref.watch(sessionStateProvider).status == SessionStatus.authenticated;
    final demo = demoOrders(market?.symbol ?? '--');
    final tabs = [
      '${strings.text(AppText.openOrders)}(${demo.openOrders.length})',
      '${strings.text(AppText.orderHistory)}(${demo.history.length})',
      '${strings.text(AppText.positions)}(${demo.positions.length})',
    ];

    Widget tab(int index, String label) {
      final active = _tab == index;
      return Flexible(
        child: InkWell(
          key: Key('ordersTab.$index'),
          onTap: () => setState(() => _tab = index),
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              left: AppSpacing.xs,
              right: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: _duration,
                  curve: Curves.easeOut,
                  style: active
                      ? AppTextStyle.label(
                          colors.onSurface,
                        ).copyWith(fontWeight: FontWeight.w700)
                      : AppTextStyle.label(colors.onSurfaceVariant),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppGap.v4,
                AnimatedContainer(
                  duration: _duration,
                  curve: Curves.easeOut,
                  height: 2,
                  width: active ? 16 : 0,
                  color: active ? colors.onSurface : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      key: const Key('ordersTabs'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: trading.border)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: TradingMetrics.pagePadding,
          ),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++) tab(i, tabs[i]),
              AppGap.h8,
              Text(
                strings.text(AppText.demoData),
                key: const Key('ordersDemoHint'),
                style: AppTextStyle.caption(colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (!authenticated)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TradingMetrics.pagePadding,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              strings.text(AppText.signInToTrade),
              key: const Key('ordersSignInHint'),
              style: AppTextStyle.caption(colors.onSurfaceVariant),
            ),
          ),
        Expanded(
          child: switch (_tab) {
            0 => _OpenOrdersList(orders: demo.openOrders),
            1 => _HistoryList(orders: demo.history),
            _ => _PositionsList(positions: demo.positions),
          },
        ),
      ],
    );
  }
}

String _hhmm(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

class _RowShell extends StatelessWidget {
  const _RowShell({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: TradingMetrics.pagePadding,
      vertical: AppSpacing.xs,
    ),
    child: Row(children: children),
  );
}

TextStyle _cell(BuildContext context, [Color? color]) => TradingText.caption(
  color ?? Theme.of(context).colorScheme.onSurface,
);

/// Unified empty state for order/history/position lists.
class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      '—',
      style: AppTextStyle.caption(Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _OpenOrdersList extends StatelessWidget {
  const _OpenOrdersList({required this.orders});

  final List<DemoOpenOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const _EmptyList();
    final strings = AppLocalizations.of(context);
    final trading = TradingColors.of(context);
    final colors = Theme.of(context).colorScheme;
    return ListView(
      key: const Key('openOrdersList'),
      children: [
        for (final order in orders)
          _RowShell(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  strings.text(order.isBuy ? AppText.buy : AppText.sell),
                  style: _cell(
                    context,
                    order.isBuy ? trading.up : trading.down,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  order.price.toString(),
                  style: _cell(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  '${strings.text(AppText.filled)} ${order.filledPercent}%',
                  style: _cell(context, colors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(_hhmm(order.time), style: _cell(context, colors.onSurfaceVariant)),
            ],
          ),
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.orders});

  final List<DemoHistoryOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const _EmptyList();
    final strings = AppLocalizations.of(context);
    final trading = TradingColors.of(context);
    final colors = Theme.of(context).colorScheme;
    return ListView(
      key: const Key('historyList'),
      children: [
        for (final order in orders)
          _RowShell(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  strings.text(order.isBuy ? AppText.buy : AppText.sell),
                  style: _cell(
                    context,
                    order.isBuy ? trading.up : trading.down,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  order.price.toString(),
                  style: _cell(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  strings.text(
                    order.status == DemoOrderStatus.filled
                        ? AppText.statusFilled
                        : AppText.statusCanceled,
                  ),
                  style: _cell(context, colors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(_hhmm(order.time), style: _cell(context, colors.onSurfaceVariant)),
            ],
          ),
      ],
    );
  }
}

class _PositionsList extends StatelessWidget {
  const _PositionsList({required this.positions});

  final List<DemoPosition> positions;

  Widget _row(BuildContext context, TradingColors trading, DemoPosition p) {
    final pnl = p.pnl;
    final negative = pnl < Decimal.zero;
    final pnlColor = negative ? trading.down : trading.up;
    return _RowShell(
      children: [
        SizedBox(
          width: 52,
          child: Text(p.currency, style: _cell(context)),
        ),
        Expanded(
          child: Text(
            p.amount.toString(),
            style: _cell(context),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            '${negative ? '' : '+'}${p.pnlPercent.toStringAsFixed(2)}%',
            key: const Key('positionPnl'),
            style: _cell(context, pnlColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (positions.isEmpty) return const _EmptyList();
    final trading = TradingColors.of(context);
    return ListView(
      key: const Key('positionsList'),
      children: [for (final position in positions) _row(context, trading, position)],
    );
  }
}
