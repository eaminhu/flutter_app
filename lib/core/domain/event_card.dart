import 'package:decimal/decimal.dart';

/// Trading status of a prediction event (v1 PmMarketStatus crosswalk).
/// An absent wire status means the venue trades it normally → open.
enum TradeStatus { open, suspended, adjudicating, closed, resolved, settled, voided }

/// Card layout archetype (v1 cardLayout): MATCH→match (1X2),
/// SINGLE_BINARY→binary (Yes/No), everything else → leaderboard.
enum CardArchetype { match, binary, leaderboard }

/// One tradeable outcome of an event card. [prob] is 0–100; null means the
/// market is unpriced (rendered as `—`, never 0).
class EventOutcome {
  const EventOutcome({required this.name, this.prob, this.marketId});

  final String name;
  final Decimal? prob;
  final String? marketId;
}

/// A prediction-market card from the v1 home feed (/swap/pm/home).
/// Financial values stay Decimal and absent values stay null.
class EventCard {
  const EventCard({
    required this.id,
    required this.title,
    required this.outcomes,
    required this.status,
    required this.numMarkets,
    required this.pricingPending,
    this.archetype = CardArchetype.leaderboard,
    this.isParticipant = false,
    this.domain = '',
    this.iconUrl,
    this.closesAt,
    this.startsAt,
    this.tradingStartsAt,
    this.volume24h,
  });

  final String id;
  final String title;
  final String? iconUrl;
  final List<EventOutcome> outcomes;
  final TradeStatus status;

  /// Venue free-text domain path (e.g. "Crypto > Bitcoin"); '' when absent.
  final String domain;

  /// Card layout archetype (from the wire cardLayout).
  final CardArchetype archetype;

  /// The venue states the event has named participants (a fixture) — gates
  /// the kick-off time tag on match cards.
  final bool isParticipant;

  /// tradingCloseTime — when trading closes.
  final DateTime? closesAt;

  /// eventStartTime — the event's own start (kick-off etc.), shown as the
  /// start tag on participant (fixture) cards.
  final DateTime? startsAt;

  /// tradingStartTime — when trading opens; drives LIVE vs UPCOMING.
  final DateTime? tradingStartsAt;

  final int numMarkets;

  /// 24h volume in the venue's own figure; null when the venue has none.
  final Decimal? volume24h;

  /// True when the market is not ACTIVE or carries no quote at all.
  final bool pricingPending;
}

/// Listing query for the prediction home feed.
class CardQuery {
  const CardQuery({
    this.domain,
    this.search,
    this.sort = 'soon',
    this.page = 1,
    this.pageSize = 20,
  });

  /// Venue free-text domain (matched as a case-insensitive prefix); null = all.
  final String? domain;

  /// Server-side search text. Only non-CJK queries are sent (the backend
  /// does not support CJK search; the caller filters those client-side).
  final String? search;
  final String sort;
  final int page;
  final int pageSize;
}
