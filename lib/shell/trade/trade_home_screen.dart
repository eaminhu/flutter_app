import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_localizations.dart';
import '../../design_system/primitives/page_status.dart';
import '../../design_system/tokens/trading_tokens.dart';
import '../../modules/prediction/prediction_screen.dart';
import '../../modules/spot/spot_screen.dart';
import '../../modules/spot/widgets/spot_top_bar.dart';
import 'instrument_tabs.dart';

/// Selected trade-mode tab: 0 spot, 1 futures, 2 cfd, 3 prediction.
final tradeTabProvider = NotifierProvider<TradeTabController, int>(
  TradeTabController.new,
  name: 'tradeTab',
);

class TradeTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

/// Trade home (/spot route): hosts the top bar and the instrument tabs, and
/// swaps the body per mode. Futures/CFD show a coming-soon placeholder;
/// prediction renders the real events list.
class TradeHomeScreen extends ConsumerWidget {
  const TradeHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final tab = ref.watch(tradeTabProvider);
    return Material(
      color: TradingColors.of(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SpotTopBar(),
          InstrumentTabs(
            selected: tab,
            onChanged: (index) =>
                ref.read(tradeTabProvider.notifier).select(index),
          ),
          Expanded(
            child: switch (tab) {
              0 => const SpotScreen(),
              3 => const PredictionScreen(),
              _ => PageStatus(
                key: const Key('tradeModePlaceholder'),
                message: strings.text(AppText.comingSoon),
                icon: Icons.rocket_launch_outlined,
              ),
            },
          ),
        ],
      ),
    );
  }
}
