import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import '../tokens/trading_tokens.dart';

/// 统一列表行（设置项/菜单项）：图标 + 标题 + 可选副标题 + 尾部。
/// 替代 Material ListTile。最小高度 56，触摸反馈一致。
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
  });

  final String title;
  final IconData? leading;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// 显示尾部 chevron（可导航行）。
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trading = TradingColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  Icon(leading, size: 22, color: scheme.onSurfaceVariant),
                  AppGap.h12,
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: AppTextStyle.body(scheme.onSurface)),
                      if (subtitle != null) ...[
                        AppGap.v2,
                        Text(
                          subtitle!,
                          style: AppTextStyle.caption(scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[AppGap.h8, trailing!],
                if (showChevron) ...[
                  AppGap.h4,
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: trading.border,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
