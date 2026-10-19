import 'package:flutter/material.dart';

/// 全局投影/描边 token。浅色主题用「细描边 + 单层柔和投影」建立层级；
/// 深色主题依赖表面色分层，不加投影（深色投影不可见且显脏）。
class AppShadows {
  AppShadows._();

  /// 卡片投影（仅浅色主题使用）。
  static List<BoxShadow> card(Brightness brightness) =>
      brightness == Brightness.light
          ? const [
              BoxShadow(
                color: Color(0x0F000000), // 6% 黑
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ]
          : const [];

  /// 抬升元素（底部弹层、悬浮条）投影（仅浅色主题使用）。
  static List<BoxShadow> raised(Brightness brightness) =>
      brightness == Brightness.light
          ? const [
              BoxShadow(
                color: Color(0x14000000), // 8% 黑
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ]
          : const [];
}
