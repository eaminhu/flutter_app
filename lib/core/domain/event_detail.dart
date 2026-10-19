import 'package:decimal/decimal.dart';

import 'event_card.dart';

/// One leg of a prediction event detail: name, market id and YES-side quote
/// probability (0–100; null = unpriced).
class DetailOutcome {
  const DetailOutcome({required this.name, this.marketId, this.prob});

  final String name;
  final String? marketId;
  final Decimal? prob;
}

/// Event detail from /swap/pm/detail/{id}. Absent venue fields stay null.
class EventDetail {
  const EventDetail({
    required this.id,
    required this.title,
    required this.status,
    required this.outcomes,
    this.iconUrl,
    this.closesAt,
    this.startsAt,
    this.tradingStartsAt,
    this.volume,
    this.liquidity,
    this.resolutionRule,
    this.resolutionSourceUrl,
  });

  final String id;
  final String title;
  final String? iconUrl;
  final TradeStatus status;
  final List<DetailOutcome> outcomes;

  /// tradingCloseTime — when trading closes.
  final DateTime? closesAt;

  /// startTime — the event's own start (kick-off etc.).
  final DateTime? startsAt;

  /// tradingStartTime — when trading opens; drives LIVE vs UPCOMING.
  final DateTime? tradingStartsAt;

  final Decimal? volume;
  final Decimal? liquidity;
  final String? resolutionRule;
  final String? resolutionSourceUrl;
}
