enum WhotSymbol { circle, cross, star, triangle, square, whot }

class WhotCard {
  const WhotCard({
    required this.number,
    required this.symbol,
  });

  final int number;
  final WhotSymbol symbol;

  bool get isWhot => symbol == WhotSymbol.whot;

  String get id {
    if (isWhot) return 'whot-$number';
    return '$number-${symbol.name}';
  }

  static WhotCard fromId(String id) {
    if (id.startsWith('whot')) {
      final parts = id.split('-');
      final n = parts.length > 1 ? int.parse(parts[1]) : 20;
      return WhotCard(number: n, symbol: WhotSymbol.whot);
    }
    final parts = id.split('-');
    return WhotCard(
      number: int.parse(parts[0]),
      symbol: WhotSymbol.values.byName(parts[1]),
    );
  }

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WhotCard && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
