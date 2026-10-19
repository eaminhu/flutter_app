import '../../core/api/contract.dart';
import '../../core/domain/event_card.dart';
import '../../core/domain/event_detail.dart';
import '../../core/domain/market.dart';

class PredictionRepository {
  const PredictionRepository(this.api);
  final PlatformApi api;

  Future<Page<EventCard>> events(CardQuery query) => api.prediction.events(query);

  Future<EventDetail> eventDetail(String eventId) =>
      api.prediction.eventDetail(eventId);

  Future<List<CategoryNode>> categories() => api.prediction.categories();
}
