import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/domain/session.dart';
import '../../core/providers/session_provider.dart';
import '../../design_system/primitives/app_card.dart';
import '../../design_system/primitives/app_list_row.dart';
import '../../design_system/tokens/app_radius.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../design_system/tokens/trading_tokens.dart';
import 'demo_assets.dart';

/// Assets home (demo): total valuation card, quick actions, per-currency
/// list and account section. Values are local demo data, clearly labelled;
/// no balances come from or are sent to any API.
class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  void _comingSoon(BuildContext context) {
    showFToast(
      context: context,
      title: Text(AppLocalizations.of(context).text(AppText.comingSoon)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final session = ref.watch(sessionStateProvider);
    final authenticated = session.status == SessionStatus.authenticated;
    final demo = demoAssets();
    return SingleChildScrollView(
      key: const Key('assetsScreen'),
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppGap.v8,
          Text(
            strings.text(AppText.assets),
            style: AppTextStyle.display(Theme.of(context).colorScheme.onSurface),
          ),
          AppGap.v16,
          _TotalCard(strings: strings, demo: demo),
          AppGap.v16,
          _QuickActions(
            strings: strings,
            onTap: () => _comingSoon(context),
          ),
          AppGap.v24,
          _AssetList(strings: strings, assets: demo.assets),
          AppGap.v24,
          _AccountSection(
            strings: strings,
            authenticated: authenticated,
            accountId: session.identity?.accountId,
          ),
          AppGap.v24,
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.strings, required this.demo});

  final AppLocalizations strings;
  final DemoAssets demo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trading = TradingColors.of(context);
    final pnl = demo.todayPnl;
    final negative = pnl < Decimal.zero;
    return AppCard(
      key: const Key('totalAssetsCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${strings.text(AppText.totalAssets)} (USD)',
                style: AppTextStyle.caption(colors.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                strings.text(AppText.demoData),
                key: const Key('assetsDemoHint'),
                style: AppTextStyle.caption(colors.onSurfaceVariant),
              ),
            ],
          ),
          AppGap.v8,
          Text(
            demo.totalUsd.toStringAsFixed(2),
            style: AppNumber.large(colors.onSurface),
          ),
          AppGap.v4,
          Text(
            '${strings.text(AppText.todayPnl)} '
            '${negative ? '' : '+'}${pnl.toStringAsFixed(2)} USD',
            style: AppNumber.small(negative ? trading.down : trading.up),
          ),
        ],
      ),
    );
  }
}

/// Binance-style quick actions: three equal columns of icon-over-label,
/// plain InkWell feedback instead of outline buttons.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.strings, required this.onTap});

  final AppLocalizations strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final entries = [
      ('assetsDeposit', FLucideIcons.arrowDownToLine, AppText.deposit),
      ('assetsWithdraw', FLucideIcons.arrowUpFromLine, AppText.withdraw),
      ('assetsTransfer', FLucideIcons.arrowLeftRight, AppText.transfer),
    ];
    return Material(
      color: Colors.transparent,
      child: Row(
        children: [
          for (final (key, icon, label) in entries)
            Expanded(
              child: InkWell(
                key: Key(key),
                borderRadius: AppRadius.mdAll,
                onTap: onTap,
                child: Padding(
                  padding: AppInsets.v(AppSpacing.sm),
                  child: Column(
                    children: [
                      Icon(icon, size: 24, color: colors.onSurface),
                      AppGap.v4,
                      Text(
                        strings.text(label),
                        style: AppTextStyle.caption(colors.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AssetList extends StatelessWidget {
  const _AssetList({required this.strings, required this.assets});

  final AppLocalizations strings;
  final List<DemoAsset> assets;

  @override
  Widget build(BuildContext context) {
    final trading = TradingColors.of(context);
    return Column(
      key: const Key('assetList'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < assets.length; i++) ...[
          if (i > 0)
            Divider(height: 1, thickness: 1, color: trading.border),
          _AssetRow(strings: strings, asset: assets[i]),
        ],
      ],
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.strings, required this.asset});

  final AppLocalizations strings;
  final DemoAsset asset;

  /// Leading letter-block edge length.
  static const double _blockSize = 36;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trading = TradingColors.of(context);
    return ConstrainedBox(
      key: ValueKey('asset.${asset.currency}'),
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: AppInsets.v(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: _blockSize,
              height: _blockSize,
              decoration: BoxDecoration(
                color: trading.surfaceRaised,
                borderRadius: AppRadius.smAll,
              ),
              alignment: Alignment.center,
              child: Text(
                asset.currency.characters.first,
                style: AppTextStyle.label(colors.onSurface),
              ),
            ),
            AppGap.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.currency,
                    style: AppTextStyle.heading(colors.onSurface),
                  ),
                  AppGap.v2,
                  Text(
                    '${strings.text(AppText.available)} ${asset.available} · '
                    '${strings.text(AppText.frozen)} ${asset.frozen}',
                    style: AppTextStyle.caption(colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppGap.h12,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '≈ ${asset.estimatedUsd.toStringAsFixed(2)}',
                  style: AppNumber.small(colors.onSurface),
                ),
                AppGap.v2,
                Text(
                  'USD',
                  style: AppTextStyle.caption(colors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection({
    required this.strings,
    required this.authenticated,
    required this.accountId,
  });

  final AppLocalizations strings;
  final bool authenticated;
  final String? accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!authenticated) {
      return FButton(
        key: const Key('assetsSignIn'),
        onPress: () => context.go('/login'),
        child: Text(strings.text(AppText.signInOrRegister)),
      );
    }
    return Column(
      key: const Key('assetsAccount'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListRow(
          leading: FLucideIcons.circleUserRound,
          title: strings.text(AppText.accountId),
          subtitle: accountId ?? '--',
        ),
        AppGap.v12,
        FButton(
          key: const Key('assetsSignOut'),
          variant: FButtonVariant.outline,
          onPress: () async {
            try {
              await ref.read(sessionManagerProvider).signOut();
            } catch (_) {
              // SessionManager surfaces storage failures via session state.
            }
          },
          child: Text(strings.text(AppText.signOut)),
        ),
      ],
    );
  }
}
