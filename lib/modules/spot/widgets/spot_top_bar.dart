import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/domain/session.dart';
import '../../../core/providers/session_provider.dart';
import '../../../design_system/primitives/app_icon_button.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';

void showComingSoon(BuildContext context) {
  showFToast(
    context: context,
    title: Text(AppLocalizations.of(context).text(AppText.comingSoon)),
  );
}

/// In-page top bar: brand, search, register (guest) / account (signed in),
/// and a menu entry. Search and menu are placeholders.
class SpotTopBar extends ConsumerWidget {
  const SpotTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final session = ref.watch(sessionStateProvider);
    final authenticated = session.status == SessionStatus.authenticated;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      key: const Key('spotTopBar'),
      height: 56,
      child: Padding(
        padding: AppInsets.page,
        child: Row(
          children: [
            Text(
              strings.text(AppText.appName),
              style: AppTextStyle.title(colors.onSurface),
            ),
            const Spacer(),
            AppIconButton(
              key: const Key('spotSearch'),
              tooltip: strings.text(AppText.search),
              icon: FLucideIcons.search,
              color: colors.onSurface,
              onPressed: () => showComingSoon(context),
            ),
            if (!authenticated)
              Padding(
                padding: AppInsets.h(AppSpacing.xs),
                child: FButton(
                  key: const Key('spotRegister'),
                  variant: FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
                  onPress: () => context.go('/login'),
                  child: Text(strings.text(AppText.register)),
                ),
              )
            else
              AppIconButton(
                key: const Key('spotAccount'),
                tooltip: strings.text(AppText.account),
                icon: FLucideIcons.userRound,
                color: colors.onSurface,
                onPressed: () => context.go('/account'),
              ),
            AppIconButton(
              key: const Key('settingsAction'),
              tooltip: strings.text(AppText.settings),
              icon: FLucideIcons.settings,
              color: colors.onSurface,
              onPressed: () => context.go('/settings'),
            ),
            AppIconButton(
              key: const Key('spotMenu'),
              icon: FLucideIcons.menu,
              color: colors.onSurface,
              onPressed: () => showComingSoon(context),
            ),
          ],
        ),
      ),
    );
  }
}
