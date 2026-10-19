import 'package:decimal/decimal.dart';

/// Compact 24h volume for card footers: $52M / $975K / $1.2B. K/M/B suffixes
/// are kept in all locales (simplest consistent lens); null → null (the
/// footer omits the segment). Pure and unit-tested.
String? formatCompactVolume(Decimal? volume) {
  if (volume == null) return null;
  final billion = Decimal.fromInt(1000000000);
  final million = Decimal.fromInt(1000000);
  final thousand = Decimal.fromInt(1000);
  String trim(Decimal scaled) {
    final fixed = scaled.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  if (volume >= billion) return '${trim((volume / billion).toDecimal(scaleOnInfinitePrecision: 2))}B';
  if (volume >= million) return '${trim((volume / million).toDecimal(scaleOnInfinitePrecision: 2))}M';
  if (volume >= thousand) return '${trim((volume / thousand).toDecimal(scaleOnInfinitePrecision: 2))}K';
  return volume.toStringAsFixed(0);
}
