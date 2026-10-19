import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/domain/preferences.dart';
import '../../core/providers/preferences_provider.dart';
import '../../design_system/primitives/app_list_row.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../design_system/tokens/trading_tokens.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<SettingsScreen> {
  bool _storageFailed = false;
  Future<void> _save(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) setState(() => _storageFailed = false);
    } catch (_) {
      if (mounted) setState(() => _storageFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final prefs = ref.watch(preferencesProvider);
    final controller = ref.read(preferencesProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      key: const Key('settingsScreen'),
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppGap.v8,
          Text(
            strings.text(AppText.settings),
            style: AppTextStyle.display(colors.onSurface),
          ),
          AppGap.v24,
          _SectionHeader(label: strings.text(AppText.language)),
          AppGap.v8,
          _OptionGroup(
            rows: [
              for (final language in AppLanguage.values)
                AppListRow(
                  key: ValueKey('language.${language.name}'),
                  title: languageLabel(language),
                  trailing: (prefs.language ?? strings.language) == language
                      ? Icon(
                          FLucideIcons.check,
                          size: 20,
                          color: colors.primary,
                        )
                      : null,
                  onTap: () =>
                      _save(() => controller.selectLanguage(language)),
                ),
            ],
          ),
          AppGap.v24,
          _SectionHeader(label: strings.text(AppText.theme)),
          AppGap.v8,
          _OptionGroup(
            rows: [
              for (final theme in AppTheme.values)
                AppListRow(
                  key: ValueKey('theme.${theme.name}'),
                  title: strings.text(switch (theme) {
                    AppTheme.system => AppText.system,
                    AppTheme.light => AppText.light,
                    AppTheme.dark => AppText.dark,
                  }),
                  trailing: prefs.theme == theme
                      ? Icon(
                          FLucideIcons.check,
                          size: 20,
                          color: colors.primary,
                        )
                      : null,
                  onTap: () => _save(() => controller.selectTheme(theme)),
                ),
            ],
          ),
          if (_storageFailed) ...[
            AppGap.v16,
            Text(
              strings.text(AppText.storageFailed),
              key: const Key('storageError'),
              style: AppTextStyle.caption(colors.error),
            ),
          ],
          AppGap.v32,
          FButton(
            key: const Key('accountButton'),
            onPress: () => context.go('/account'),
            child: Text(strings.text(AppText.account)),
          ),
        ],
      ),
    );
  }
}

/// Section title (语言 / 主题): caption size, muted color.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AppTextStyle.caption(Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

/// Single-choice option list: AppListRow rows separated by hairlines.
class _OptionGroup extends StatelessWidget {
  const _OptionGroup({required this.rows});

  final List<AppListRow> rows;

  @override
  Widget build(BuildContext context) {
    final trading = TradingColors.of(context);
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: trading.border),
          rows[i],
        ],
      ],
    );
  }
}
