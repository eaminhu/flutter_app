import 'package:flutter/widgets.dart';

/// 全局间距 token（8pt 网格，4 为最小步进）。
/// 页面/组件内边距一律从这里取，禁止散写 EdgeInsets 字面量。
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// 页面水平内边距。
  static const double pagePadding = lg;
}

/// 常用 EdgeInsets 工厂。
class AppInsets {
  AppInsets._();

  static const EdgeInsets page = EdgeInsets.symmetric(
    horizontal: AppSpacing.pagePadding,
  );

  static const EdgeInsets card = EdgeInsets.all(AppSpacing.lg);

  static EdgeInsets v(double value) => EdgeInsets.symmetric(vertical: value);

  static EdgeInsets h(double value) =>
      EdgeInsets.symmetric(horizontal: value);
}

/// 常用固定间隔。用于替代裸 SizedBox 字面量。
class AppGap {
  AppGap._();

  static const Widget v2 = SizedBox(height: AppSpacing.xxs);
  static const Widget v4 = SizedBox(height: AppSpacing.xs);
  static const Widget v8 = SizedBox(height: AppSpacing.sm);
  static const Widget v12 = SizedBox(height: AppSpacing.md);
  static const Widget v16 = SizedBox(height: AppSpacing.lg);
  static const Widget v24 = SizedBox(height: AppSpacing.xl);
  static const Widget v32 = SizedBox(height: AppSpacing.xxl);

  static const Widget h2 = SizedBox(width: AppSpacing.xxs);
  static const Widget h4 = SizedBox(width: AppSpacing.xs);
  static const Widget h8 = SizedBox(width: AppSpacing.sm);
  static const Widget h12 = SizedBox(width: AppSpacing.md);
  static const Widget h16 = SizedBox(width: AppSpacing.lg);
}
