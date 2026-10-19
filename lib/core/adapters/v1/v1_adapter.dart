import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../api/contract.dart';
import '../../api/errors.dart';
import '../../domain/country.dart';
import '../../domain/event_card.dart';
import '../../domain/event_detail.dart';
import '../../domain/market.dart';
import '../../domain/money.dart';
import '../../domain/session.dart';
import '../../http/dio_http.dart';
import '../../realtime/stomp_client.dart';

PlatformError _malformed(String field) => PlatformError(
  PlatformErrorCode.responseMalformed,
  'v1 field is malformed: $field',
);
Map<String, dynamic> _row(Object? value, String field) {
  if (value is! Map<String, dynamic>) throw _malformed(field);
  return value;
}

String _string(Map<String, dynamic> row, String field) {
  final value = row[field];
  if (value is! String || value.trim().isEmpty) throw _malformed(field);
  return value;
}

List<Market> decodeSpotMarkets(Object? value) {
  if (value is! List) throw _malformed('market.symbol');
  final items = <Market>[];
  final ids = <String>{};
  for (final item in value) {
    final row = _row(item, 'market.symbol.row');
    final symbol = _string(row, 'symbol');
    final enable = row['enable'];
    if (enable != null && enable is! int) throw _malformed('enable');
    if (enable == 0) continue;
    final id = symbol.split('_').first.replaceAll('/', '-');
    if (!ids.add(id)) throw _malformed('duplicate marketId');
    items.add(
      Market(marketId: id, symbol: symbol, instrumentType: InstrumentType.spot),
    );
  }
  return items;
}

// ─── prediction home feed (/swap/pm/home) ─────────────────────────────────

Decimal? _decPositive(Object? value) {
  final raw = switch (value) {
    num v => v.toString(),
    String v => v.trim(),
    _ => '',
  };
  if (raw.isEmpty) return null;
  final parsed = Decimal.tryParse(raw);
  if (parsed == null || parsed <= Decimal.zero) return null;
  return parsed;
}

DateTime? _instant(Object? value) {
  if (value is! num || value <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
}

final _degenerateSpread = Decimal.parse('0.9');
final _hundred = Decimal.fromInt(100);

/// Quote probability (0–100) from one book: degenerate full-range spread
/// (ask-bid ≥ 0.9) is a placeholder → unpriced (null). ask → bid → mid →
/// lastTraded. Mirrors the Web adapter's bookQuoteProb.
Decimal? _quoteProb(Object? lastTraded, Object? mid, Object? bid, Object? ask) {
  final b = _decPositive(bid);
  final a = _decPositive(ask);
  if (b != null && a != null) {
    if (a - b >= _degenerateSpread) return null;
    return (a * _hundred).round();
  }
  if (a != null) return (a * _hundred).round();
  if (b != null) return (b * _hundred).round();
  final m = _decPositive(mid);
  if (m != null) return (m * _hundred).round();
  final lt = _decPositive(lastTraded);
  if (lt != null) return (lt * _hundred).round();
  return null;
}

const _statusCrosswalk = {
  'open': TradeStatus.open,
  'active': TradeStatus.open,
  'suspended': TradeStatus.suspended,
  'closed': TradeStatus.closed,
  'resolved': TradeStatus.resolved,
  'settled': TradeStatus.settled,
  'cancelled': TradeStatus.voided,
  'voided': TradeStatus.voided,
  'market_adj_pending': TradeStatus.adjudicating,
  'adjudication_pending': TradeStatus.adjudicating,
};

/// Decodes one /swap/pm/home item. Match/h2h special layouts are rendered
/// as generic outcome rows; only SINGLE_BINARY gets the Yes/No pair.
EventCard decodeEventCard(Object? raw) {
  final item = _row(raw, 'pm.homeItem');
  final id = _string(item, 'id');
  final title = _string(item, 'title');
  final layout = item['cardLayout'];
  final layoutText = layout is String ? layout.toUpperCase() : '';
  final isBinary = layoutText == 'SINGLE_BINARY';
  // Unknown/missing layouts render as leaderboard rows, never dropped.
  final archetype = switch (layoutText) {
    'MATCH' => CardArchetype.match,
    'SINGLE_BINARY' => CardArchetype.binary,
    _ => CardArchetype.leaderboard,
  };
  final preview = item['previewItems'];
  final rows = preview is List ? preview : const [];
  final statusText = _string(item, 'status');
  final status =
      _statusCrosswalk[statusText.toLowerCase()] ??
      (throw _malformed('status'));

  final List<EventOutcome> outcomes;
  if (isBinary) {
    final p = rows.isNotEmpty ? _row(rows.first, 'previewItems') : null;
    final marketId = p?['marketId'];
    outcomes = [
      EventOutcome(
        name: p?['yesLabel'] is String ? p!['yesLabel'] as String : 'Yes',
        prob: _quoteProb(
          p?['yesPrice'],
          p?['midPrice'],
          p?['yesBid'],
          p?['yesAsk'],
        ),
        marketId: marketId is String ? marketId : null,
      ),
      EventOutcome(
        name: p?['noLabel'] is String ? p!['noLabel'] as String : 'No',
        prob: _quoteProb(p?['noPrice'], null, p?['noBid'], p?['noAsk']),
        marketId: marketId is String ? marketId : null,
      ),
    ];
  } else {
    outcomes = [
      for (final entry in rows)
        () {
          final p = _row(entry, 'previewItems.row');
          final label = p['label'];
          final marketId = p['marketId'];
          return EventOutcome(
            name: label is String && label.trim().isNotEmpty ? label : '—',
            prob: _quoteProb(
              p['yesPrice'],
              p['midPrice'],
              p['yesBid'],
              p['yesAsk'],
            ),
            marketId: marketId is String ? marketId : null,
          );
        }(),
    ];
  }

  final numMarkets = item['marketCount'] ?? item['totalOutcomeCount'];
  final icon = item['uiConfig'];
  final iconUrl = icon is Map<String, dynamic> ? icon['iconUrl'] : null;
  return EventCard(
    id: id,
    title: title,
    iconUrl: iconUrl is String && iconUrl.trim().isNotEmpty ? iconUrl : null,
    outcomes: outcomes,
    status: status,
    archetype: archetype,
    isParticipant: item['isParticipant'] == true,
    domain: item['domain'] is String ? item['domain'] as String : '',
    numMarkets: numMarkets is num ? numMarkets.toInt() : outcomes.length,
    pricingPending:
        statusText != 'ACTIVE' || outcomes.every((o) => o.prob == null),
    closesAt: _instant(item['tradingCloseTime']),
    startsAt: _instant(item['eventStartTime']),
    tradingStartsAt: _instant(item['tradingStartTime']),
    volume24h: _decPositive(item['totalVolumeUsd']) ?? _decPositive(item['totalVolume']),
  );
}

String _categoryId(String name) {
  final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  final trimmed = slug.replaceAll(RegExp(r'^-+|-+$'), '');
  return trimmed.isEmpty ? name : trimmed;
}

/// Decodes one /swap/pm/detail/{id} payload. Legs are mapped to generic
/// outcome rows; itemType SINGLE gets the canonical Yes/No pair.
EventDetail decodeEventDetail(Object? raw) {
  final d = _row(raw, 'pm.detail');
  final id = _string(d, 'id');
  final title = _string(d, 'title');
  final statusRaw = d['status'];
  final status = statusRaw == null
      ? TradeStatus.open
      : _statusCrosswalk[_string(d, 'status').toLowerCase()] ??
            (throw _malformed('status'));
  final rawLegs = d['markets'];
  final legs = rawLegs is List ? rawLegs : const [];
  final isSingle = d['itemType'] == 'SINGLE';

  List<DetailOutcome> outcomes;
  if (isSingle && legs.isNotEmpty) {
    final leg = _row(legs.first, 'pm.detail.leg');
    final marketId = leg['id'];
    final mid = marketId == null ? null : '$marketId';
    final yesLabel = leg['yesLabel'];
    final noLabel = leg['noLabel'];
    outcomes = [
      DetailOutcome(
        name: yesLabel is String && yesLabel.trim().isNotEmpty ? yesLabel : 'Yes',
        marketId: mid,
        prob: _quoteProb(
          _yesTradedPrice(leg),
          leg['midPrice'],
          leg['yesBid'],
          leg['yesAsk'],
        ),
      ),
      DetailOutcome(
        name: noLabel is String && noLabel.trim().isNotEmpty ? noLabel : 'No',
        marketId: mid,
        prob: _quoteProb(null, null, leg['noBid'], leg['noAsk']),
      ),
    ];
  } else {
    outcomes = [
      for (final entry in legs)
        () {
          final leg = _row(entry, 'pm.detail.leg');
          final name = leg['title'] ?? leg['betType'] ?? leg['id'];
          final marketId = leg['id'];
          return DetailOutcome(
            name: name == null ? '—' : '$name',
            marketId: marketId == null ? null : '$marketId',
            prob: _quoteProb(
              _yesTradedPrice(leg),
              leg['midPrice'],
              leg['yesBid'],
              leg['yesAsk'],
            ),
          );
        }(),
    ];
  }

  final icon = d['uiConfig'];
  final iconUrl = icon is Map<String, dynamic> ? icon['iconUrl'] : null;
  final rule = d['resolutionRule'];
  final source = d['resolutionSourceUrl'];
  return EventDetail(
    id: id,
    title: title,
    iconUrl: iconUrl is String && iconUrl.trim().isNotEmpty ? iconUrl : null,
    status: status,
    outcomes: outcomes,
    closesAt: _instant(d['tradingCloseTime']),
    startsAt: _instant(d['startTime']),
    tradingStartsAt: _instant(d['tradingStartTime']),
    volume: _decPositive(d['totalVolumeUsd']) ?? _decPositive(d['totalVolume']),
    liquidity: _decPositive(d['liquidity']),
    resolutionRule: rule is String && rule.trim().isNotEmpty ? rule : null,
    resolutionSourceUrl: source is String && source.trim().isNotEmpty ? source : null,
  );
}

/// The YES side's last-traded price from a leg's tradingPairs.
Object? _yesTradedPrice(Map<String, dynamic> leg) {
  final pairs = leg['tradingPairs'];
  if (pairs is! List) return null;
  for (final pair in pairs) {
    if (pair is Map<String, dynamic> &&
        '${pair['tokenSide']}'.toUpperCase() == 'YES') {
      return pair['currentPrice'];
    }
  }
  return null;
}

/// Decodes one /topic/pm/auction/{marketId} frame body. Returns null for a
/// malformed frame (dropped, never fatal to the socket).
AuctionTick? decodeAuctionTick(String marketId, String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } catch (_) {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  Decimal? dec(Object? v) {
    final raw = switch (v) {
      num n => n.toString(),
      String s => s.trim(),
      _ => '',
    };
    if (raw.isEmpty) return null;
    return Decimal.tryParse(raw);
  }

  return AuctionTick(
    marketId: marketId,
    indicativePrice: dec(decoded['indicativePrice']),
    bestBid: dec(decoded['bestBid']),
    bestAsk: dec(decoded['bestAsk']),
  );
}

/// Parses the pmMenu tree (3 levels of {name, children}) from the
/// application_config JSON blob.
List<CategoryNode> parsePmMenu(Object? raw) {  if (raw is! List) return const [];
  return [
    for (final node in raw)
      if (node is Map<String, dynamic> && node['name'] is String)
        CategoryNode(
          id: _categoryId(node['name'] as String),
          label: node['name'] as String,
          children: parsePmMenu(node['children']),
        ),
  ];
}

class V1Adapter implements PlatformApi, CatalogApi, AuthApi, PredictionApi, RealtimeApi {
  V1Adapter(this.http);
  final DioHttp http;
  @override
  CatalogApi get catalog => this;
  @override
  AuthApi get auth => this;
  @override
  PredictionApi get prediction => this;
  @override
  RealtimeApi get realtime => this;
  Future<Object?> _envelopeChecked(HttpReply reply) async {
    final row = _row(reply.body, 'envelope');
    final code = row['code'];
    if (code is! int) throw _malformed('code');
    if (code == 401) return await http.rejectCredentials(reply.generation);
    if (code == 403) {
      throw const PlatformError(
        PlatformErrorCode.permissionDenied,
        'v1 refused permission.',
      );
    }
    if (code != 0) {
      // Keep the backend message so auth screens can show it verbatim.
      final message = row['message'];
      throw PlatformError(
        PlatformErrorCode.serverError,
        message is String && message.trim().isNotEmpty
            ? message
            : 'v1 rejected the request.',
      );
    }
    return row['data'];
  }

  Future<Object?> _envelope(HttpReply reply) async {
    final data = await _envelopeChecked(reply);
    if (data == null) throw _malformed('data');
    return data;
  }

  @override
  Future<Page<Market>> markets(MarketQuery query) async {
    if (query.instrumentType != InstrumentType.spot || query.page < 1) {
      throw const PlatformError(
        PlatformErrorCode.unsupported,
        'Only the spot catalog is supported.',
      );
    }
    final reply = await http.request('/market/symbol');
    // Public catalog is a raw array; an error envelope must not be treated as empty.
    if (reply.body is Map<String, dynamic>) {
      await _envelope(reply);
      throw _malformed('market.symbol');
    }
    final items = decodeSpotMarkets(reply.body);
    const size = 50;
    final start = (query.page - 1) * size;
    return Page(
      items: items.skip(start).take(size).toList(),
      page: query.page,
      pageSize: size,
      total: items.length,
    );
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      throw _malformed('login input');
    }
    final reply = await http.request(
      '/uc/login_auth_data',
      method: 'POST',
      data: FormData.fromMap({
        'username': username.trim(),
        'password': password,
      }),
      authenticated: false,
    );
    final row = _row(await _envelope(reply), 'login');
    if (row['token'] == null && row['securityToken'] != null) {
      throw const PlatformError(
        PlatformErrorCode.unsupported,
        'This login requires MFA, which is not migrated yet.',
      );
    }
    final token = _string(row, 'token');
    final raw = row['expiresAt'];
    final DateTime? expiry;
    if (raw == null) {
      expiry = null;
    } else if (raw is int) {
      expiry = DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
    } else if (raw is String) {
      expiry = DateTime.tryParse(raw)?.toUtc();
      if (expiry == null) throw _malformed('expiresAt');
    } else {
      throw _malformed('expiresAt');
    }
    return AuthSession(accessToken: token, expiresAt: expiry);
  }

  @override
  Future<AccountIdentity> me() async {
    final row = _row(
      await _envelope(await http.request('/uc/member/my-info', method: 'POST')),
      'identity',
    );
    final id = row.containsKey('accountId') ? row['accountId'] : row['uid'];
    if (id is String && id.trim().isNotEmpty) {
      return AccountIdentity(accountId: id);
    }
    if (id is int) return AccountIdentity(accountId: id.toString());
    throw _malformed('accountId/uid');
  }

  @override
  Future<List<Country>> countries() async {
    final data = await _envelope(
      await http.request(
        '/uc/support/country?isReg=1',
        method: 'POST',
        authenticated: false,
      ),
    );
    if (data is! List) throw _malformed('country');
    final countries = <Country>[];
    for (final item in data) {
      final row = _row(item, 'country.row');
      final zhName = _string(row, 'zhName');
      countries.add(
        Country(
          zhName: zhName,
          enName: row['enName'] is String ? row['enName'] as String : zhName,
          areaCode: row['areaCode'] is String ? row['areaCode'] as String : '',
        ),
      );
    }
    return countries;
  }

  @override
  Future<void> sendRegisterCode({required String email}) async {
    if (email.trim().isEmpty) throw _malformed('email');
    // v1 answers code 0 with null data — success with nothing to return.
    await _envelopeChecked(
      await http.request(
        '/uc/verify/email/register?email=${Uri.encodeQueryComponent(email.trim())}',
        authenticated: false,
      ),
    );
  }

  @override
  Future<void> register(RegisterInput input) async {
    // Empty data on code 0 is success for this endpoint.
    await _envelopeChecked(
      await http.request(
        '/uc/register/email',
        method: 'POST',
        authenticated: false,
        data: FormData.fromMap({
          'email': input.email.trim(),
          'username': input.username.trim(),
          'password': input.password,
          'code': input.code.trim(),
          'protocol': 'true',
          'promotion': input.promotion.trim(),
          'superPartner': '',
          // The backend matches on the Chinese country name.
          'country': input.country,
          'phone': input.phone.trim(),
        }),
      ),
    );
  }

  @override
  Future<Page<EventCard>> events(CardQuery query) async {
    final buffer = StringBuffer(
      '/swap/pm/home?sort=${Uri.encodeQueryComponent(query.sort)}'
      '&page=${query.page}&pageSize=${query.pageSize}',
    );
    final domain = query.domain;
    if (domain != null && domain.trim().isNotEmpty) {
      buffer.write('&domain=${Uri.encodeQueryComponent(domain)}');
    }
    // The backend does not support CJK search; the caller filters those
    // client-side, so only non-CJK queries are sent.
    final search = query.search;
    if (search != null &&
        search.trim().isNotEmpty &&
        !RegExp(r'[一-鿿]').hasMatch(search)) {
      buffer.write('&search=${Uri.encodeQueryComponent(search.trim())}');
    }
    final data = _row(await _envelope(await http.request(buffer.toString())), 'pm.home');
    final markets = _row(data['markets'], 'pm.home.markets');
    final rawItems = markets['items'];
    if (rawItems is! List) throw _malformed('pm.home.items');
    final cards = <EventCard>[];
    for (final raw in rawItems) {
      try {
        cards.add(decodeEventCard(raw));
      } on PlatformError {
        // One malformed row must not empty the whole list; skip it.
      }
    }
    if (cards.isEmpty && rawItems.isNotEmpty) throw _malformed('pm.home.items');
    final pagination = markets['pagination'];
    int field(String name, int fallback) {
      if (pagination is! Map<String, dynamic>) return fallback;
      final value = pagination[name];
      return value is num ? value.toInt() : fallback;
    }

    return Page(
      items: cards,
      page: field('page', query.page),
      pageSize: field('pageSize', query.pageSize),
      total: field('total', cards.length),
    );
  }

  @override
  Future<List<CategoryNode>> categories() async {
    final Object? data;
    try {
      data = await _envelope(await http.request('/uc/member/application_config'));
    } on PlatformError catch (error) {
      // The config endpoint may require sign-in; the list page then shows
      // only the "All" category instead of failing.
      if (error.code == PlatformErrorCode.authTokenExpired ||
          error.code == PlatformErrorCode.permissionDenied) {
        return const [];
      }
      rethrow;
    }
    // The blob arrives as a JSON string carrying the pmMenu tree.
    if (data is! String) throw _malformed('application_config');
    final Object? decoded;
    try {
      decoded = jsonDecode(data);
    } catch (_) {
      throw _malformed('application_config.json');
    }
    if (decoded is! Map<String, dynamic>) throw _malformed('application_config.json');
    return parsePmMenu(decoded['pmMenu']);
  }

  @override
  Future<EventDetail> eventDetail(String eventId) async {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(eventId)) {
      throw _malformed('eventId');
    }
    return decodeEventDetail(
      await _envelope(await http.request('/swap/pm/detail/$eventId')),
    );
  }

  // ─── realtime (SockJS + STOMP over /swap_market/ws) ─────────────────────

  StompClient? _stomp;
  StompClient get _client {
    final existing = _stomp;
    if (existing != null) return existing;
    final base = http.baseUrl;
    final wsBase = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/swap_market/ws',
      query: null,
      fragment: null,
    );
    final client = StompClient(wsBase: wsBase);
    client.messages.listen(_routeMessage);
    _stomp = client;
    return client;
  }

  /// marketId → open pipe controllers.
  final _auctionPipes = <String, Set<StreamController<AuctionTick>>>{};

  /// marketId → STOMP subscription id.
  final _auctionSubIds = <String, String>{};

  void _routeMessage(StompMessage message) {
    const prefix = '/topic/pm/auction/';
    if (!message.destination.startsWith(prefix)) return;
    final marketId = message.destination.substring(prefix.length);
    final pipes = _auctionPipes[marketId];
    if (pipes == null || pipes.isEmpty) return;
    final tick = decodeAuctionTick(marketId, message.body);
    if (tick == null) return;
    for (final pipe in pipes) {
      if (!pipe.isClosed) pipe.add(tick);
    }
  }

  @override
  Stream<AuctionTick> watchAuction(String marketId) {
    late StreamController<AuctionTick> controller;
    controller = StreamController<AuctionTick>(
      onListen: () {
        final pipes = _auctionPipes.putIfAbsent(marketId, () => {});
        pipes.add(controller);
        // One STOMP subscription per marketId, shared by every watcher.
        _auctionSubIds.putIfAbsent(
          marketId,
          () => _client.subscribe('/topic/pm/auction/$marketId'),
        );
      },
      onCancel: () async {
        final pipes = _auctionPipes[marketId];
        if (pipes == null) return;
        pipes.remove(controller);
        await controller.close();
        if (pipes.isEmpty) {
          _auctionPipes.remove(marketId);
          final subId = _auctionSubIds.remove(marketId);
          if (subId != null) _client.unsubscribe(subId);
        }
      },
    );
    return controller.stream;
  }

  @override
  void revalidate() => _stomp?.revalidate();
}
