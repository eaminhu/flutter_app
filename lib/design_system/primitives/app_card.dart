import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/trading_tokens.dart';

/// 统一卡片容器。浅色=细描边+柔和投影，深色=抬升表面色+细描边。
/// 所有业务卡片（预测卡片、资产卡片、信息区）一律用它，不再散写 Card/Container 装饰。
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final trading = TradingColors.of(context);
    final decoration = BoxDecoration(
      color: brightness == Brightness.light
          ? trading.surface
          : trading.surfaceRaised,
      borderRadius: AppRadius.lgAll,
      border: Border.all(color: trading.border),
      boxShadow: AppShadows.card(brightness),
    );
    final content = Padding(
      padding: padding ?? AppInsets.card,
      child: child,
    );
    if (onTap == null) {
      return Container(decoration: decoration, child: content);
    }
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: content,
        ),
      ),
    );
  }
}
