import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/api/errors.dart';
import '../../../core/domain/event_detail.dart';
import '../../../core/providers/platform_provider.dart';
import '../../../design_system/primitives/app_card.dart';
import '../../../design_system/primitives/app_icon_button.dart';
import '../../../design_system/primitives/page_status.dart';
import '../../../design_system/tokens/app_radius.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../design_system/tokens/trading_tokens.dart';
import '../widgets/event_status_pill.dart';
import 'event_detail_view_model.dart';

/// How many leading outcomes hold a live auction subscription (Web parity:
/// the leaders tick; the tail renders its REST snapshot).
const liveOutcomeLimit = 12;

/// Event detail page (route /prediction/:eventId, outside the shell). REST
/// snapshot first, then live auction ticks overlay the probability bars.
class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailState();
}

class _EventDetailState extends ConsumerState<EventDetailScreen> {
  final _liveProb = <String, Decimal>{};
  final _subs = <StreamSubscription<dynamic>>[];

  @override
  void dispose() {
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    super.dispose();
  }

  void _subscribeOutcomes(EventDetail detail) {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    final ranked = [...detail.outcomes]
      ..sort((a, b) => (b.prob ?? Decimal.zero).compareTo(a.prob ?? Decimal.zero));
    final api = ref.read(platformApiProvider);
    for (final outcome in ranked.take(liveOutcomeLimit)) {
      final marketId = outcome.marketId;
      if (marketId == null) continue;
      _subs.add(
        api.realtime.watchAuction(marketId).listen((tick) {
          final prob = liveProbOf(
            bestBid: tick.bestBid,
            bestAsk: tick.bestAsk,
          );
          // A degenerate/unquotable tick never wipes the last value.
          if (prob == null || !mounted) return;
          setState(() => _liveProb[marketId] = prob);
        }),
      );
    }
  }

  Decimal? _probOf(DetailOutcome outcome) {
    final marketId = outcome.marketId;
    if (marketId != null && _liveProb.containsKey(marketId)) {
      return _liveProb[marketId];
    }
    return outcome.prob;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final detail = ref.watch(eventDetailProvider(widget.eventId));
    final value = detail.value;
    return Material(
      color: TradingColors.of(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  AppGap.h4,
                  AppIconButton(
                    key: const Key('eventDetailBack'),
                    icon: FLucideIcons.arrowLeft,
                    tooltip: strings.text(AppText.eventDetail),
                    onPressed: () => context.pop(),
                  ),
                  AppGap.h4,
                  Expanded(
                    child: Text(
                      value?.title ?? strings.text(AppText.eventDetail),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.heading(colors.onSurface),
                    ),
                  ),
                  if (value != null) ...[
                    AppGap.h8,
                    EventStatusPill(
                      status: value.status,
                      tradingStartsAt: value.tradingStartsAt,
                      closesAt: value.closesAt,
                    ),
                  ],
                  AppGap.h12,
                ],
              ),
            ),
          ),
          Expanded(
            child: detail.when(
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
                  key: const Key('eventDetailError'),
                  message: strings.text(
                    disconnected
                        ? AppText.disconnected
                        : AppText.eventsUnavailable,
                  ),
                  icon: Icons.cloud_off_outlined,
                  actionLabel: retryable ? strings.text(AppText.retry) : null,
                  onAction: retryable
                      ? () => ref.invalidate(eventDetailProvider(widget.eventId))
                      : null,
                );
              },
              data: (value) {
                _subscribeOutcomesOnce(value);
                return _DetailBody(
                  detail: value,
                  probOf: _probOf,
                  liveMarkets: _liveProb.keys.toSet(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  EventDetail? _subscribedFor;

  void _subscribeOutcomesOnce(EventDetail detail) {
    if (identical(_subscribedFor, detail)) return;
    _subscribedFor = detail;
    // Subscribe after the frame: mutating streams during build is unsafe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(_subscribedFor, detail)) {
        _subscribeOutcomes(detail);
      }
    });
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.probOf,
    required this.liveMarkets,
  });

  final EventDetail detail;
  final Decimal? Function(DetailOutcome) probOf;
  final Set<String> liveMarkets;

  @override
  Widget build(BuildContext context) {
    final hasInfo =
        detail.closesAt != null ||
        detail.volume != null ||
        detail.liquidity != null;
    return ListView(
      key: const Key('eventDetailBody'),
      padding: AppInsets.page.add(AppInsets.v(AppSpacing.lg)),
      children: [
        _OutcomesCard(
          detail: detail,
          probOf: probOf,
          liveMarkets: liveMarkets,
        ),
        if (hasInfo) ...[
          AppGap.v16,
          _InfoSection(detail: detail),
        ],
        if (detail.resolutionRule != null) ...[
          AppGap.v16,
          _ResolutionCard(detail: detail),
        ],
      ],
    );
  }
}

/// All outcome rows in one card, separated by hairlines.
class _OutcomesCard extends StatelessWidget {
  const _OutcomesCard({
    required this.detail,
    required this.probOf,
    required this.liveMarkets,
  });

  final EventDetail detail;
  final Decimal? Function(DetailOutcome) probOf;
  final Set<String> liveMarkets;

  @override
  Widget build(BuildContext context) {
    final trading = TradingColors.of(context);
    final outcomes = detail.outcomes;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < outcomes.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: trading.border),
            _OutcomeTile(
              // Index in the key: distinct legs can share a marketId.
              key: ValueKey(
                'detailOutcome.$i.${outcomes[i].marketId ?? outcomes[i].name}',
              ),
              outcome: outcomes[i],
              prob: probOf(outcomes[i]),
              live: outcomes[i].marketId != null &&
                  liveMarkets.contains(outcomes[i].marketId),
            ),
          ],
        ],
      ),
    );
  }
}

/// One outcome row: name + percent + Yes/No placeholder buttons on the first
/// line, the probability bar below.
class _OutcomeTile extends StatelessWidget {
  const _OutcomeTile({
    super.key,
    required this.outcome,
    required this.prob,
    required this.live,
  });

  final DetailOutcome outcome;
  final Decimal? prob;
  final bool live;

  Color _barColor(BuildContext context, AppLocalizations strings) {
    final name = outcome.name.trim().toLowerCase();
    final trading = TradingColors.of(context);
    if (name == strings.text(AppText.yes).toLowerCase()) return trading.up;
    if (name == strings.text(AppText.no).toLowerCase()) return trading.down;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final trading = TradingColors.of(context);
    final prob = this.prob;
    void placeholder() => showFToast(
      context: context,
      title: Text(strings.text(AppText.tradeWriteUnavailable)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  outcome.name,
                  style: AppTextStyle.body(colors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppGap.h8,
              Text(
                prob == null ? '—' : '${prob.toStringAsFixed(0)}%',
                key: live ? const Key('liveProb') : null,
                style: AppNumber.medium(
                  prob == null ? colors.onSurfaceVariant : colors.onSurface,
                ),
              ),
              AppGap.h8,
              _SideButton(
                label: strings.text(AppText.yes),
                color: trading.up,
                onTap: placeholder,
              ),
              AppGap.h8,
              _SideButton(
                label: strings.text(AppText.no),
                color: trading.down,
                onTap: placeholder,
              ),
            ],
          ),
          AppGap.v8,
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: SizedBox(
              height: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: trading.border),
                  if (prob != null)
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (prob.toDouble() / 100).clamp(0.0, 1.0),
                      child: ColoredBox(color: _barColor(context, strings)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yes/No capsule button: 36 high, tinted background, colored label — same
/// visual language as the list card's big capsules.
class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        constraints: const BoxConstraints(minWidth: 56),
        padding: AppInsets.h(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: AppRadius.mdAll,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.label(
            color,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.detail});

  final EventDetail detail;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final trading = TradingColors.of(context);
    String two(int v) => v.toString().padLeft(2, '0');
    final rows = <(String, String)>[
      if (detail.closesAt != null)
        (
          strings.text(AppText.closesAt),
          () {
            final t = detail.closesAt!.toLocal();
            return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
          }(),
        ),
      if (detail.volume != null)
        (strings.text(AppText.volume), detail.volume!.toStringAsFixed(2)),
      if (detail.liquidity != null)
        (strings.text(AppText.liquidity), detail.liquidity!.toStringAsFixed(2)),
    ];
    return AppCard(
      padding: AppInsets.h(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: trading.border),
            Padding(
              padding: AppInsets.v(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: AppTextStyle.caption(colors.onSurfaceVariant),
                  ),
                  AppGap.h8,
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      style: AppNumber.small(colors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResolutionCard extends StatelessWidget {
  const _ResolutionCard({required this.detail});

  final EventDetail detail;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.text(AppText.resolutionRule),
            style: AppTextStyle.heading(colors.onSurface),
          ),
          AppGap.v8,
          Text(
            detail.resolutionRule!,
            key: const Key('resolutionRuleText'),
            style: AppTextStyle.body(colors.onSurface),
          ),
          if (detail.resolutionSourceUrl != null) ...[
            AppGap.v4,
            Text(
              '${strings.text(AppText.resolutionSource)}: ${detail.resolutionSourceUrl}',
              style: AppTextStyle.caption(colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
