import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';

/// Trade mode tabs (spot / futures / cfd / prediction). Controlled: the
/// selection lives in the shell so each tab can swap the page body.
class InstrumentTabs extends StatelessWidget {
  const InstrumentTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final tabs = [
      ('instrumentTab.spot', strings.text(AppText.spot)),
      ('instrumentTab.futures', strings.text(AppText.futures)),
      ('instrumentTab.cfd', strings.text(AppText.cfd)),
      ('instrumentTab.prediction', strings.text(AppText.prediction)),
    ];
    Widget tab(int index, String key, String label) {
      final active = selected == index;
      return Flexible(
        child: InkWell(
          key: Key(key),
          onTap: () => onChanged(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: _duration,
                  curve: Curves.easeOut,
                  style: active
                      ? AppTextStyle.heading(colors.onSurface)
                      : AppTextStyle.label(colors.onSurfaceVariant),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppGap.v4,
                AnimatedContainer(
                  duration: _duration,
                  curve: Curves.easeOut,
                  height: 2,
                  width: active ? 18 : 0,
                  decoration: BoxDecoration(
                    color: active ? colors.onSurface : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      key: const Key('instrumentTabs'),
      height: 46,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) tab(i, tabs[i].$1, tabs[i].$2),
        ],
      ),
    );
  }
}
