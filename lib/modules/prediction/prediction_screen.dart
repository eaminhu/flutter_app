import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/api/errors.dart';
import '../../design_system/primitives/app_card.dart';
import '../../design_system/primitives/app_icon_button.dart';
import '../../design_system/primitives/page_status.dart';
import '../../design_system/tokens/app_radius.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import 'prediction_view_model.dart';
import 'widgets/category_chips.dart';
import 'widgets/event_card.dart';

/// Prediction market list (real API): search, category chips and event
/// cards with loading / error / empty states and scroll pagination.
class PredictionScreen extends ConsumerStatefulWidget {
  const PredictionScreen({super.key});

  @override
  ConsumerState<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends ConsumerState<PredictionScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final text = _search.text;
    setState(() {}); // toggle the clear-button suffix
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(predictionSearchProvider.notifier).search(text.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    ref.read(predictionSearchProvider.notifier).search('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(predictionEventsProvider);
    final categories = ref.watch(predictionCategoriesProvider);
    final domain = ref.watch(predictionDomainProvider);
    final searching = ref.watch(predictionSearchProvider).trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.pagePadding,
            right: AppSpacing.pagePadding,
            top: AppSpacing.xs,
          ),
          child: FTextField(
            key: const Key('eventSearch'),
            control: FTextFieldControl.managed(controller: _search),
            hint: strings.text(AppText.searchEvents),
            autocorrect: false,
            suffixBuilder: _search.text.isEmpty
                ? null
                : (context, style, variants) => AppIconButton(
                    key: const Key('clearSearch'),
                    icon: FLucideIcons.x,
                    iconSize: 16,
                    tooltip: strings.text(AppText.clearSearch),
                    onPressed: _clearSearch,
                  ),
          ),
        ),
        AppGap.v8,
        if (searching)
          Padding(
            padding: AppInsets.page,
            child: Text(
              '${strings.text(AppText.searchResults)}: ${state.items.length}',
              key: const Key('searchResultCount'),
              style: AppTextStyle.caption(
                Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          CategoryChips(
            categories: categories.value ?? const [],
            selected: domain,
            onSelected: (value) =>
                ref.read(predictionDomainProvider.notifier).select(value),
          ),
        AppGap.v8,
        Expanded(child: _body(context, ref, strings, state, searching)),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations strings,
    PredictionEventsState state,
    bool searching,
  ) {
    if (state.loading && !state.loaded) {
      return ListView(
        key: const Key('eventsSkeleton'),
        padding: AppInsets.page,
        children: const [
          _EventCardSkeleton(),
          AppGap.v12,
          _EventCardSkeleton(),
          AppGap.v12,
          _EventCardSkeleton(),
        ],
      );
    }
    final error = state.error;
    if (error != null) {
      final disconnected =
          error is PlatformError &&
          error.code == PlatformErrorCode.backendNotConfigured;
      final retryable = error is! PlatformError || error.retryable;
      return PageStatus(
        key: const Key('eventsError'),
        message: strings.text(
          disconnected ? AppText.disconnected : AppText.eventsUnavailable,
        ),
        icon: Icons.cloud_off_outlined,
        actionLabel: retryable ? strings.text(AppText.retry) : null,
        onAction: retryable
            ? () => ref.read(predictionEventsProvider.notifier).retry()
            : null,
      );
    }
    if (state.items.isEmpty) {
      return PageStatus(
        key: const Key('eventsEmpty'),
        message: strings.text(
          searching ? AppText.noSearchResults : AppText.noEvents,
        ),
        icon: Icons.search_off_outlined,
      );
    }
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 120) {
          ref.read(predictionEventsProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        key: const Key('eventsList'),
        padding: AppInsets.page,
        itemCount: state.items.length + 1,
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            if (state.loadingMore) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: CircularProgressIndicator(
                    key: const Key('eventsLoadingMore'),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            }
            if (state.loadMoreFailed) {
              return Padding(
                padding: AppInsets.v(AppSpacing.sm),
                child: Center(
                  child: TextButton(
                    key: const Key('loadMoreRetry'),
                    onPressed: () =>
                        ref.read(predictionEventsProvider.notifier).loadMore(),
                    child: Text(strings.text(AppText.retry)),
                  ),
                ),
              );
            }
            return const SizedBox(height: AppSpacing.md);
          }
          final card = state.items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: EventCardTile(
              card: card,
              onTap: () => context.push('/prediction/${card.id}'),
            ),
          );
        },
      ),
    );
  }
}

/// Static skeleton placeholder for the first-page loading state: an AppCard
/// with a title bar and two row bars (no animation, no extra dependency).
class _EventCardSkeleton extends StatelessWidget {
  const _EventCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final barColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.08);
    Widget bar(double height, [double? width]) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: AppRadius.smAll,
      ),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(AppSpacing.lg, 160),
          AppGap.v12,
          bar(AppSpacing.md),
          AppGap.v8,
          bar(AppSpacing.md),
        ],
      ),
    );
  }
}
