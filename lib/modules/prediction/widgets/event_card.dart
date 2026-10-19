import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/domain/event_card.dart';
import '../../../design_system/primitives/app_card.dart';
import '../../../design_system/primitives/app_icon_button.dart';
import '../../../design_system/tokens/app_radius.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../design_system/tokens/trading_tokens.dart';
import '../../../design_system/trading/compact_volume.dart';
import 'event_status_pill.dart';

String _hhmm(DateTime t) {
  final l = t.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
}

String _probText(Decimal? prob) =>
    prob == null ? '—' : '${prob.round().toStringAsFixed(0)}%';

/// The last domain segment ("Crypto > Bitcoin" → "Bitcoin"), else the whole
/// domain; empty when the venue states none.
String domainLabel(String domain) {
  if (domain.trim().isEmpty) return '';
  final parts = domain.split('>');
  return parts.last.trim();
}

/// Prediction event card following the user's Polymarket-style reference:
/// big percent figures, capsule buttons (green/red by side), and a footer of
/// compact volume · category · close time plus a bookmark placeholder.
/// The whole card opens the detail page; quick trading is out of scope.
class EventCardTile extends StatelessWidget {
  const EventCardTile({super.key, required this.card, required this.onTap});

  final EventCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: Key('eventCard.${card.id}'),
      onTap: onTap,
      child: switch (card.archetype) {
        CardArchetype.match => _MatchLayout(card: card),
        CardArchetype.binary => _BinaryLayout(card: card),
        CardArchetype.leaderboard => _LeaderboardLayout(card: card),
      },
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.card});

  final EventCard card;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Monogram(name: card.title),
        AppGap.h12,
        Expanded(
          child: Text(
            card.title,
            style: AppTextStyle.heading(colors.onSurface),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppGap.h8,
        EventStatusPill.ofCard(card: card),
      ],
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trading = TradingColors.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: trading.surfaceRaised,
        borderRadius: AppRadius.smAll,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name.characters.first,
        style: AppTextStyle.label(colors.onSurface),
      ),
    );
  }
}

/// Outcome line: monogram + name + big percent on the right.
class _OutcomeLine extends StatelessWidget {
  const _OutcomeLine({super.key, required this.outcome});

  final EventOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: AppInsets.v(AppSpacing.xs),
      child: Row(
        children: [
          _Monogram(name: outcome.name),
          AppGap.h8,
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
            _probText(outcome.prob),
            style: AppNumber.large(colors.onSurface),
          ),
        ],
      ),
    );
  }
}

/// Capsule button. [tone]: positive (light green), negative (light red),
/// neutral (light blue), disabled (gray when unpriced).
enum _CapsuleTone { positive, negative, neutral, disabled }

class _Capsule extends StatelessWidget {
  const _Capsule({
    super.key,
    required this.label,
    required this.tone,
    this.big = false,
  });

  final String label;
  final _CapsuleTone tone;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final trading = TradingColors.of(context);
    final colors = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      _CapsuleTone.positive => (
        trading.up.withValues(alpha: 0.15),
        trading.up,
      ),
      _CapsuleTone.negative => (
        trading.down.withValues(alpha: 0.15),
        trading.down,
      ),
      _CapsuleTone.neutral => (
        colors.primary.withValues(alpha: 0.10),
        colors.primary,
      ),
      _CapsuleTone.disabled => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };
    return Container(
      height: big ? 36 : 28,
      padding: EdgeInsets.symmetric(
        horizontal: big ? AppSpacing.md : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: big ? AppRadius.mdAll : AppRadius.pillAll,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: big
            ? AppTextStyle.label(fg).copyWith(fontWeight: FontWeight.w600)
            : AppTextStyle.caption(fg).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.card});

  final EventCard card;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final volume = formatCompactVolume(card.volume24h);
    final category = domainLabel(card.domain);
    final segments = <String>[
      if (volume != null) '\$$volume ${strings.text(AppText.volume)}',
      if (category.isNotEmpty) category,
      if (card.closesAt != null) _hhmm(card.closesAt!),
    ];
    return Row(
      children: [
        Expanded(
          child: Text(
            segments.join(' · '),
            style: AppTextStyle.caption(colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppIconButton(
          key: Key('bookmark.${card.id}'),
          icon: FLucideIcons.bookmark,
          iconSize: 20,
          onPressed: () => showComingSoon(context),
        ),
      ],
    );
  }
}

void showComingSoon(BuildContext context) {
  showFToast(
    context: context,
    title: Text(AppLocalizations.of(context).text(AppText.comingSoon)),
  );
}

// ─── MATCH (1X2) ────────────────────────────────────────────────────────────

class _MatchLayout extends StatelessWidget {
  const _MatchLayout({required this.card});

  final EventCard card;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final outcomes = card.outcomes;
    final cells = outcomes.take(3).toList();
    // Rows show home and away; the Draw leg only appears as the middle button.
    final rows = cells.length >= 3
        ? [cells[0], cells[2]]
        : cells.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TitleRow(card: card),
        AppGap.v8,
        for (var i = 0; i < rows.length; i++)
          _OutcomeLine(
            key: Key('eventRow.${card.id}.$i'),
            outcome: rows[i],
          ),
        AppGap.v8,
        Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) AppGap.h8,
              Expanded(
                child: _Capsule(
                  key: Key('eventCell.${card.id}.$i'),
                  // 1X2: home (blue) / Draw (gray, centered) / away (blue).
                  label: cells.length >= 3 && i == 1
                      ? strings.text(AppText.draw)
                      : cells[i].name,
                  tone: cells[i].prob == null
                      ? _CapsuleTone.disabled
                      : (cells.length >= 3 && i == 1
                            ? _CapsuleTone.disabled
                            : _CapsuleTone.neutral),
                  big: true,
                ),
              ),
            ],
          ],
        ),
        AppGap.v8,
        _CardFooter(card: card),
      ],
    );
  }
}

// ─── BINARY (Yes/No) ────────────────────────────────────────────────────────

class _BinaryLayout extends StatelessWidget {
  const _BinaryLayout({required this.card});

  final EventCard card;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final yes = card.outcomes.isNotEmpty ? card.outcomes[0] : null;
    final no = card.outcomes.length >= 2 ? card.outcomes[1] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TitleRow(card: card),
        AppGap.v8,
        if (yes != null)
          _OutcomeLine(
            key: Key('eventRow.${card.id}.0'),
            outcome: yes,
          ),
        if (no != null)
          _OutcomeLine(
            key: Key('eventRow.${card.id}.1'),
            outcome: no,
          ),
        AppGap.v8,
        Row(
          children: [
            Expanded(
              child: _Capsule(
                key: Key('eventYes.${card.id}'),
                label: yes == null
                    ? strings.text(AppText.yes)
                    : '${strings.text(AppText.yes)} ${_probText(yes.prob)}',
                tone: yes?.prob == null
                    ? _CapsuleTone.disabled
                    : _CapsuleTone.positive,
                big: true,
              ),
            ),
            AppGap.h8,
            Expanded(
              child: _Capsule(
                key: Key('eventNo.${card.id}'),
                label: no == null
                    ? strings.text(AppText.no)
                    : '${strings.text(AppText.no)} ${_probText(no.prob)}',
                tone: no?.prob == null
                    ? _CapsuleTone.disabled
                    : _CapsuleTone.negative,
                big: true,
              ),
            ),
          ],
        ),
        AppGap.v8,
        _CardFooter(card: card),
      ],
    );
  }
}

// ─── LEADERBOARD (multi-outcome) ────────────────────────────────────────────

class _LeaderboardLayout extends StatelessWidget {
  const _LeaderboardLayout({required this.card});

  final EventCard card;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final sorted = [...card.outcomes]
      ..sort((a, b) => (b.prob ?? Decimal.zero).compareTo(a.prob ?? Decimal.zero));
    final shown = sorted.take(4).toList();
    final rest = sorted.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TitleRow(card: card),
        AppGap.v8,
        for (var i = 0; i < shown.length; i++)
          _LeaderboardRow(
            key: Key('eventRow.${card.id}.$i'),
            outcome: shown[i],
            yesLabel: strings.text(AppText.yes),
            noLabel: strings.text(AppText.no),
          ),
        if (rest > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Text(
              '+$rest',
              key: Key('eventMore.${card.id}'),
              style: AppTextStyle.caption(colors.onSurfaceVariant),
            ),
          ),
        AppGap.v8,
        _CardFooter(card: card),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    super.key,
    required this.outcome,
    required this.yesLabel,
    required this.noLabel,
  });

  final EventOutcome outcome;
  final String yesLabel;
  final String noLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final priced = outcome.prob != null;
    return Padding(
      padding: AppInsets.v(AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              outcome.name,
              style: AppTextStyle.body(colors.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _probText(outcome.prob),
            style: AppNumber.medium(colors.onSurface),
          ),
          AppGap.h8,
          _Capsule(
            label: yesLabel,
            tone: priced ? _CapsuleTone.positive : _CapsuleTone.disabled,
          ),
          AppGap.h4,
          _Capsule(
            label: noLabel,
            tone: priced ? _CapsuleTone.negative : _CapsuleTone.disabled,
          ),
        ],
      ),
    );
  }
}
