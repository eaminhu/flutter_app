import '../domain/country.dart';
import '../domain/event_card.dart';
import '../domain/event_detail.dart';
import '../domain/market.dart';
import '../domain/session.dart';
import 'stream.dart';

export 'stream.dart';

abstract interface class PlatformApi {
  CatalogApi get catalog;
  AuthApi get auth;
  PredictionApi get prediction;
  RealtimeApi get realtime;
}

abstract interface class CatalogApi {
  Future<Page<Market>> markets(MarketQuery query);
}

abstract interface class AuthApi {
  Future<AuthSession> login({
    required String username,
    required String password,
  });
  Future<AccountIdentity> me();

  /// Registration country list (v1: POST /uc/support/country?isReg=1).
  Future<List<Country>> countries();

  /// Sends the email registration code (v1: GET /uc/verify/email/register).
  Future<void> sendRegisterCode({required String email});

  /// Email registration (v1: POST /uc/register/email). An envelope with
  /// code 0 and empty data is success.
  Future<void> register(RegisterInput input);
}

/// A prediction category node from the v1 pmMenu tree (name + children).
/// [id] is a locally derived slug for keys/state; [label] is the venue's
/// localized name and is also what the home feed's domain filter matches.
class CategoryNode {
  const CategoryNode({required this.id, required this.label, this.children = const []});

  final String id;
  final String label;
  final List<CategoryNode> children;
}

abstract interface class PredictionApi {
  /// Prediction home feed (v1: GET /swap/pm/home).
  Future<Page<EventCard>> events(CardQuery query);

  /// One event with its legs (v1: GET /swap/pm/detail/{eventId}).
  Future<EventDetail> eventDetail(String eventId);

  /// Discovery categories (v1: GET /uc/member/application_config → pmMenu).
  /// An endpoint that requires sign-in (401/403) degrades to an empty list —
  /// the UI then shows only "All".
  Future<List<CategoryNode>> categories();
}
