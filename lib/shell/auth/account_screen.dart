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

/// Profile page ("我的"). Guests get a full-width sign-in CTA plus settings /
/// language entries; authenticated users see an identity card, the same menu
/// list and a danger-styled sign-out action.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final session = ref.watch(sessionStateProvider);
    final authenticated = session.status == SessionStatus.authenticated;
    final colors = Theme.of(context).colorScheme;
    return Material(
      child: SingleChildScrollView(
        key: const Key('accountScreen'),
        padding: AppInsets.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppGap.v8,
            Text(
              strings.text(AppText.profile),
              style: AppTextStyle.display(colors.onSurface),
            ),
            AppGap.v16,
            if (!authenticated) ...[
              FButton(
                key: const Key('profileSignIn'),
                onPress: () => context.go('/login'),
                child: Text(strings.text(AppText.signInOrRegister)),
              ),
              AppGap.v24,
              _MenuList(strings: strings),
            ] else ...[
              _IdentityCard(
                strings: strings,
                accountId: session.identity?.accountId,
              ),
              AppGap.v24,
              _MenuList(strings: strings),
              AppGap.v24,
              FButton(
                key: const Key('profileSignOut'),
                variant: FButtonVariant.outline,
                onPress: () async {
                  try {
                    await ref.read(sessionManagerProvider).signOut();
                  } catch (_) {
                    // SessionManager surfaces storage failures via session state.
                  }
                },
                child: Text(
                  strings.text(AppText.signOut),
                  style: TextStyle(color: colors.error),
                ),
              ),
            ],
            AppGap.v24,
          ],
        ),
      ),
    );
  }
}

/// Menu entries (settings, language & theme) as AppListRow list separated by
/// hairlines. Visible to guests and signed-in users alike.
class _MenuList extends StatelessWidget {
  const _MenuList({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final trading = TradingColors.of(context);
    final entries = [
      (
        key: const Key('profileSettings'),
        icon: FLucideIcons.settings,
        label: strings.text(AppText.settings),
      ),
      (
        key: const Key('profileLanguageTheme'),
        icon: FLucideIcons.languages,
        label:
            '${strings.text(AppText.language)} / ${strings.text(AppText.theme)}',
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: trading.border),
          AppListRow(
            key: entries[i].key,
            leading: entries[i].icon,
            title: entries[i].label,
            onTap: () => context.go('/settings'),
            showChevron: true,
          ),
        ],
      ],
    );
  }
}

/// Signed-in header: 48dp rounded-square avatar block on a raised surface,
/// account id label over its value.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.strings, required this.accountId});

  final AppLocalizations strings;
  final String? accountId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trading = TradingColors.of(context);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: trading.surfaceRaised,
              borderRadius: AppRadius.mdAll,
            ),
            alignment: Alignment.center,
            child: Icon(
              FLucideIcons.userRound,
              size: 24,
              color: colors.onSurfaceVariant,
            ),
          ),
          AppGap.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.text(AppText.accountId),
                  style: AppTextStyle.caption(colors.onSurfaceVariant),
                ),
                AppGap.v2,
                Text(
                  accountId ?? '--',
                  key: const Key('profileAccountId'),
                  style: AppTextStyle.heading(colors.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
