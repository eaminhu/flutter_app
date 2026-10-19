import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/contract.dart';
import '../../core/domain/event_card.dart';
import '../../core/domain/session.dart';
import '../../core/providers/platform_provider.dart';
import '../../core/providers/session_provider.dart';
import 'prediction_repository.dart';

/// Category tree from the v1 pmMenu; auth failures degrade to empty (only
/// the "All" chip is rendered). Non-auth errors surface as AsyncError.
final predictionCategoriesProvider = FutureProvider<List<CategoryNode>>((ref) {
  ref.watch(
    sessionStateProvider.select(
      (s) => (s.generation, s.status == SessionStatus.authenticated),
    ),
  );
  return PredictionRepository(ref.watch(platformApiProvider)).categories();
}, name: 'predictionCategories');

/// The selected domain filter; null means "All".
final predictionDomainProvider =
    NotifierProvider<PredictionDomainController, String?>(
      PredictionDomainController.new,
      name: 'predictionDomain',
    );

class PredictionDomainController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? domain) => state = domain;
}

/// The active search text ('' = none). Debounced by the screen.
final predictionSearchProvider =
    NotifierProvider<PredictionSearchController, String>(
      PredictionSearchController.new,
      name: 'predictionSearch',
    );

class PredictionSearchController extends Notifier<String> {
  @override
  String build() => '';

  void search(String text) => state = text;
}

bool hasCjk(String text) => RegExp(r'[一-鿿]').hasMatch(text);

/// Client-side filter for CJK queries (the backend cannot search CJK).
bool cardMatchesQuery(EventCard card, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (card.title.toLowerCase().contains(q)) return true;
  return card.outcomes.any((o) => o.name.toLowerCase().contains(q));
}

class PredictionEventsState {
  const PredictionEventsState({
    this.items = const [],
    this.page = 1,
    this.total = 0,
    this.loading = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.error,
    this.loaded = false,
  });

  final List<EventCard> items;
  final int page;
  final int total;
  final bool loading;
  final bool loadingMore;

  /// The last page fetch failed; the loaded items stay visible.
  final bool loadMoreFailed;
  final Object? error;
  final bool loaded;

  bool get hasMore => items.length < total;
}

final predictionEventsProvider =
    NotifierProvider<PredictionEventsController, PredictionEventsState>(
      PredictionEventsController.new,
      name: 'predictionEvents',
    );

class PredictionEventsController extends Notifier<PredictionEventsState> {
  int _requestId = 0;

  @override
  PredictionEventsState build() {
    ref.watch(
      sessionStateProvider.select(
        (s) => (s.generation, s.status == SessionStatus.authenticated),
      ),
    );
    ref.watch(predictionDomainProvider);
    ref.watch(predictionSearchProvider);
    final id = ++_requestId;
    // ignore: discarded_futures
    Future(() => _loadFirst(id));
    return const PredictionEventsState(loading: true);
  }

  PredictionRepository get _repo =>
      PredictionRepository(ref.read(platformApiProvider));

  Future<void> _loadFirst(int id) async {
    try {
      final search = ref.read(predictionSearchProvider).trim();
      final cjk = search.isNotEmpty && hasCjk(search);
      final page = await _repo.events(
        CardQuery(
          domain: ref.read(predictionDomainProvider),
          // CJK queries are filtered client-side (Web parity: one bulk page).
          search: cjk || search.isEmpty ? null : search,
          pageSize: cjk ? 500 : 20,
        ),
      );
      if (id != _requestId) return;
      final items = cjk
          ? page.items.where((card) => cardMatchesQuery(card, search)).toList()
          : page.items;
      state = PredictionEventsState(
        items: items,
        page: page.page,
        total: cjk ? items.length : page.total,
        loaded: true,
      );
    } catch (error) {
      if (id != _requestId) return;
      state = PredictionEventsState(error: error, loaded: true);
    }
  }

  void retry() => ref.invalidateSelf();

  Future<void> loadMore() async {
    final current = state;
    if (current.loading ||
        current.loadingMore ||
        current.error != null ||
        !current.hasMore) {
      return;
    }
    // CJK searches are one bulk client-filtered page; nothing more to load.
    final search = ref.read(predictionSearchProvider).trim();
    if (search.isNotEmpty && hasCjk(search)) return;
    final id = _requestId;
    state = PredictionEventsState(
      items: current.items,
      page: current.page,
      total: current.total,
      loadingMore: true,
      loaded: true,
    );
    try {
      final next = await _repo.events(
        CardQuery(
          domain: ref.read(predictionDomainProvider),
          search: search.isEmpty ? null : search,
          page: current.page + 1,
        ),
      );
      if (id != _requestId) return;
      state = PredictionEventsState(
        items: [...current.items, ...next.items],
        page: next.page,
        total: next.total,
        loaded: true,
      );
    } catch (_) {
      if (id != _requestId) return;
      // Keep the loaded items; the footer offers an explicit retry.
      state = PredictionEventsState(
        items: current.items,
        page: current.page,
        total: current.total,
        loadMoreFailed: true,
        loaded: true,
      );
    }
  }
}
