import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/api/contract.dart';
import '../../../design_system/tokens/app_radius.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../design_system/tokens/trading_tokens.dart';

/// Horizontally scrolling category chips: "All" plus the pmMenu level-1 and
/// level-2 nodes flattened. Selection filters the feed by domain (the
/// node's venue label).
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<CategoryNode> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final trading = TradingColors.of(context);
    final entries = <(String id, String label, String domain)>[
      ('all', strings.text(AppText.allCategories), ''),
      for (final node in categories) ...[
        (node.id, node.label, node.label),
        for (final child in node.children)
          ('${node.id}/${child.id}', child.label, '${node.label} > ${child.label}'),
      ],
    ];
    return SizedBox(
      key: const Key('categoryChips'),
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppInsets.page,
        children: [
          for (final (id, label, domain) in entries) ...[
            Builder(
              builder: (context) {
                final active = (selected ?? '') == domain;
                return InkWell(
                  key: Key('categoryChip.$id'),
                  borderRadius: AppRadius.pillAll,
                  onTap: () => onSelected(domain.isEmpty ? null : domain),
                  child: Container(
                    alignment: Alignment.center,
                    padding: AppInsets.h(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: active ? colors.onSurface : Colors.transparent,
                      borderRadius: AppRadius.pillAll,
                      border: active
                          ? null
                          : Border.all(color: trading.border),
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      style: AppTextStyle.label(
                        active ? colors.surface : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
            AppGap.h8,
          ],
        ],
      ),
    );
  }
}
