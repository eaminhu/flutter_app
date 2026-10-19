import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/event_detail.dart';
import '../../../core/domain/session.dart';
import '../../../core/providers/platform_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../prediction_repository.dart';

/// Event detail read. Session generation changes invalidate the read, same
/// posture as the spot catalog.
final eventDetailProvider =
    FutureProvider.autoDispose.family<EventDetail, String>((ref, eventId) {
      ref.watch(
        sessionStateProvider.select(
          (s) => (s.generation, s.status == SessionStatus.authenticated),
        ),
      );
      return PredictionRepository(
        ref.watch(platformApiProvider),
      ).eventDetail(eventId);
    }, name: 'eventDetail');

/// Live YES probability (0–100) for one auction tick. Ask first, else bid;
/// a degenerate full-range spread (ask-bid ≥ 0.9) is a placeholder and is
/// skipped — the last value stays. Returns null when nothing quotable.
Decimal? liveProbOf({Decimal? bestBid, Decimal? bestAsk}) {
  final spreadLimit = Decimal.parse('0.9');
  final hundred = Decimal.fromInt(100);
  final b = bestBid;
  final a = bestAsk;
  if (b != null && b > Decimal.zero && a != null && a > Decimal.zero) {
    if (a - b >= spreadLimit) return null;
    return a * hundred;
  }
  if (a != null && a > Decimal.zero) {
    return a * hundred;
  }
  if (b != null && b > Decimal.zero) {
    return b * hundred;
  }
  return null;
}
