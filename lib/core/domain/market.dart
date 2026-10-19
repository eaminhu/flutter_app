enum InstrumentType { spot, perp, cfd, event }

// The first catalog projection. Further venue fields are added with adapters.
class Market {
  const Market({
    required this.marketId,
    required this.symbol,
    required this.instrumentType,
  });
  final String marketId;
  final String symbol;
  final InstrumentType instrumentType;
}

class MarketQuery {
  const MarketQuery({required this.instrumentType, this.page = 1});
  final InstrumentType instrumentType;
  final int page;
}

class Page<T> {
  Page({
    required List<T> items,
    required this.page,
    required this.pageSize,
    required this.total,
  }) : items = List.unmodifiable(items);
  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
}
