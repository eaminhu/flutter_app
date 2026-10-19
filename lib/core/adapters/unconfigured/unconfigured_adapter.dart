import '../../domain/country.dart';
import '../../domain/event_card.dart';
import '../../domain/event_detail.dart';
import '../../api/contract.dart';
import '../../api/errors.dart';
import '../../domain/market.dart';
import '../../domain/session.dart';

class UnconfiguredAdapter
    implements PlatformApi, CatalogApi, AuthApi, PredictionApi, RealtimeApi {
  const UnconfiguredAdapter();
  @override
  CatalogApi get catalog => this;
  @override
  AuthApi get auth => this;
  @override
  PredictionApi get prediction => this;
  @override
  RealtimeApi get realtime => this;
  Never _fail() => throw const PlatformError(
    PlatformErrorCode.backendNotConfigured,
    'No backend adapter is configured.',
  );
  @override
  Future<Page<Market>> markets(MarketQuery query) async => _fail();
  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async => _fail();
  @override
  Future<AccountIdentity> me() async => _fail();
  @override
  Future<List<Country>> countries() async => _fail();
  @override
  Future<void> sendRegisterCode({required String email}) async => _fail();
  @override
  Future<void> register(RegisterInput input) async => _fail();
  @override
  Future<Page<EventCard>> events(CardQuery query) async => _fail();
  @override
  Future<List<CategoryNode>> categories() async => _fail();
  @override
  Future<EventDetail> eventDetail(String eventId) async => _fail();
  @override
  Stream<AuctionTick> watchAuction(String marketId) => const Stream.empty();
  @override
  void revalidate() {}
}
