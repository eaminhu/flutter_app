import 'package:flutter/widgets.dart';

/// 全局圆角 token。禁止散写 BorderRadius.circular 字面量。
class AppRadius {
  AppRadius._();

  /// 小元素（pill 状态标、输入框内嵌件）。
  static const double sm = 6;

  /// 按钮、输入框、小卡片。
  static const double md = 10;

  /// 卡片、弹层。
  static const double lg = 14;

  /// 胶囊。
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
