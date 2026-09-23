import 'package:flutter/material.dart';

import '../models/whot_card.dart';

class WhotCardView extends StatelessWidget {
  const WhotCardView({
    super.key,
    required this.card,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.compact = false,
  });

  final WhotCard card;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final bool compact;

  Color get _symbolColor {
    switch (card.symbol) {
      case WhotSymbol.circle:
        return const Color(0xFFD62828);
      case WhotSymbol.cross:
        return const Color(0xFF023E8A);
      case WhotSymbol.star:
        return const Color(0xFFCA6702);
      case WhotSymbol.triangle:
        return const Color(0xFF2D6A4F);
      case WhotSymbol.square:
        return const Color(0xFF6A4C93);
      case WhotSymbol.whot:
        return const Color(0xFF1B4332);
    }
  }

  String get _symbolLabel {
    switch (card.symbol) {
      case WhotSymbol.circle:
        return '●';
      case WhotSymbol.cross:
        return '✚';
      case WhotSymbol.star:
        return '★';
      case WhotSymbol.triangle:
        return '▲';
      case WhotSymbol.square:
        return '■';
      case WhotSymbol.whot:
        return 'W';
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = compact ? 56.0 : 72.0;
    final h = compact ? 80.0 : 104.0;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.white70,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? _symbolColor : const Color(0xFF1B4332),
          width: selected ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.isWhot ? 'WHOT' : '${card.number}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: card.isWhot ? 12 : 20,
              color: _symbolColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _symbolLabel,
            style: TextStyle(fontSize: 18, color: _symbolColor),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }
}
