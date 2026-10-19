import 'package:decimal/decimal.dart';

/// Demo asset snapshot. Fixed local values for UI development only; clearly
/// labelled as demo data in the UI and never sent to any API.
class DemoAsset {
  const DemoAsset({
    required this.currency,
    required this.available,
    required this.frozen,
    required this.estimatedUsd,
  });

  final String currency;
  final Decimal available;
  final Decimal frozen;

  /// Estimated USD value of available + frozen.
  final Decimal estimatedUsd;
}

class DemoAssets {
  const DemoAssets({required this.assets, required this.todayPnl});

  final List<DemoAsset> assets;
  final Decimal todayPnl;

  Decimal get totalUsd =>
      assets.fold(Decimal.zero, (sum, asset) => sum + asset.estimatedUsd);
}

/// Deterministic: fixed values, same on every call.
DemoAssets demoAssets() => DemoAssets(
  assets: [
    DemoAsset(
      currency: 'USDT',
      available: Decimal.parse('12500.00'),
      frozen: Decimal.parse('300.00'),
      estimatedUsd: Decimal.parse('12800.00'),
    ),
    DemoAsset(
      currency: 'BTC',
      available: Decimal.parse('0.2540'),
      frozen: Decimal.zero,
      estimatedUsd: Decimal.parse('21346.80'),
    ),
    DemoAsset(
      currency: 'ETH',
      available: Decimal.parse('3.5020'),
      frozen: Decimal.parse('0.5000'),
      estimatedUsd: Decimal.parse('14620.35'),
    ),
  ],
  todayPnl: Decimal.parse('486.25'),
);
