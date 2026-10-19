import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/domain/event_card.dart';
import '../../../design_system/tokens/app_radius.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../design_system/tokens/trading_tokens.dart';

/// Status pill: open + inside the trading window → LIVE; open + before the
/// window → UPCOMING; open + past close → closed; other statuses map to
/// their own label. Wall-clock is a display concern only.
class EventStatusPill extends StatelessWidget {
  const EventStatusPill({
    super.key,
    required this.status,
    this.tradingStartsAt,
    this.closesAt,
  });

  /// Convenience constructor for list cards.
  EventStatusPill.ofCard({Key? key, required EventCard card})
    : this(
        key: key,
        status: card.status,
        tradingStartsAt: card.tradingStartsAt,
        closesAt: card.closesAt,
      );

  final TradeStatus status;
  final DateTime? tradingStartsAt;
  final DateTime? closesAt;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final trading = TradingColors.of(context);
    final now = DateTime.now();
    final String label;
    final Color color;
    if (status == TradeStatus.open) {
      final starts = tradingStartsAt;
      final closes = closesAt;
      if (starts != null && now.isBefore(starts)) {
        label = strings.text(AppText.upcoming);
        color = colors.onSurfaceVariant;
      } else if (closes != null && now.isAfter(closes)) {
        label = strings.text(AppText.statusClosed);
        color = colors.onSurfaceVariant;
      } else {
        label = strings.text(AppText.live);
        color = trading.up;
      }
    } else {
      label = strings.text(
        switch (status) {
          TradeStatus.suspended => AppText.statusSuspended,
          TradeStatus.adjudicating => AppText.statusAdjudicating,
          TradeStatus.closed => AppText.statusClosed,
          TradeStatus.resolved => AppText.statusResolved,
          TradeStatus.settled => AppText.statusSettled,
          TradeStatus.voided => AppText.statusVoided,
          TradeStatus.open => AppText.live,
        },
      );
      color = colors.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        label,
        style: AppTextStyle.caption(color).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
