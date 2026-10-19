import 'package:flutter/material.dart';

/// 全局文字阶梯。所有文字样式从这里取，禁止散写 fontSize 字面量。
/// 数字一律走 [AppNumber]（等宽数字，防止行情跳动时布局抖动）。
class AppTextStyle {
  AppTextStyle._();

  /// 页面大标题 / 特大数字（28）。
  static TextStyle display(Color color) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: color,
  );

  /// 区块标题（20）。
  static TextStyle title(Color color) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: color,
  );

  /// 小节标题 / 列表主标题（16）。
  static TextStyle heading(Color color) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: color,
  );

  /// 正文（15）。
  static TextStyle body(Color color) =>
      TextStyle(fontSize: 15, height: 1.45, color: color);

  /// 标签 / 次要操作文字（13）。
  static TextStyle label(Color color) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: color,
  );

  /// 辅助说明 / 元信息（12）。
  static TextStyle caption(Color color) =>
      TextStyle(fontSize: 12, height: 1.35, color: color);
}

/// 数字专用档（价格、金额、百分比），全部 tabular figures。
class AppNumber {
  AppNumber._();

  static const _figures = [FontFeature.tabularFigures()];

  /// 大数字（最新价、总资产，24）。
  static TextStyle large(Color color) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: color,
    fontFeatures: _figures,
  );

  /// 中数字（卡片百分比、行内价格，16）。
  static TextStyle medium(Color color) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: color,
    fontFeatures: _figures,
  );

  /// 小数字（盘口档位、列表副行，13）。
  static TextStyle small(Color color) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: color,
    fontFeatures: _figures,
  );
}
