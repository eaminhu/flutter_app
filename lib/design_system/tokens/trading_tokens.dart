import 'package:flutter/material.dart';

/// Trading-specific design tokens. Values follow the user-approved
/// Binance dark screenshot (dark theme) with readable light counterparts.
/// See docs/design-tokens.md for the archived values and their sources.
class TradingColors {
  const TradingColors({
    required this.up,
    required this.down,
    required this.bidDepth,
    required this.askDepth,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
  });

  /// 涨/买方向（绿，Binance #2EBD85 系）。
  final Color up;

  /// 跌/卖方向（红，Binance #F6465D 系）。禁止用 Forui destructive 替代。
  final Color down;

  /// 买盘档位深度底色。
  final Color bidDepth;

  /// 卖盘档位深度底色。
  final Color askDepth;

  /// 交易面板底色（深色参考 Binance #0B0E11）。
  final Color surface;

  /// 交易面板内抬升区域底色（深色参考 #161A1E）。
  final Color surfaceRaised;

  /// 细描边 / 分隔线（hairline）。浅色下与卡片投影配合建立层级。
  final Color border;

  static const dark = TradingColors(
    up: Color(0xFF2EBD85),
    down: Color(0xFFF6465D),
    bidDepth: Color(0x1F2EBD85),
    askDepth: Color(0x1FF6465D),
    surface: Color(0xFF0B0E11),
    surfaceRaised: Color(0xFF161A1E),
    border: Color(0xFF2B2F36),
  );

  static const light = TradingColors(
    up: Color(0xFF2EBD85),
    down: Color(0xFFF6465D),
    bidDepth: Color(0x142EBD85),
    askDepth: Color(0x14F6465D),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF5F6F7),
    border: Color(0xFFE8EAED),
  );

  static TradingColors of(BuildContext context) =>
      forBrightness(Theme.of(context).brightness);

  static TradingColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Trading typography tokens. All numeric text must use tabular figures.
class TradingText {
  TradingText._();

  static const _figures = [FontFeature.tabularFigures()];

  /// 大号最新价（pair header）。
  static TextStyle priceLarge(Color color) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: color,
    fontFeatures: _figures,
  );

  /// 盘口/表单内价格数量。
  static TextStyle priceMedium(Color color) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: color,
    fontFeatures: _figures,
  );

  /// 次要说明与标签。
  static TextStyle caption(Color color) =>
      TextStyle(fontSize: 12, height: 1.3, color: color, fontFeatures: _figures);
}

/// Trading layout tokens (logical pixels).
class TradingMetrics {
  TradingMetrics._();

  /// 盘口档位行高。
  static const double orderBookRowHeight = 20;

  /// 页面水平内边距。
  static const double pagePadding = 12;

  /// 下单表单与盘口栏之间的间距。
  static const double columnGutter = 10;

  /// 表单内部段间距。
  static const double formGap = 10;
}
