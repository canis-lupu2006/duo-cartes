import 'whot_card.dart';

enum RoomStatus { waiting, choosingGame, playing, finished }

enum GameType { whot, truthOrDare }

enum TurnOwner { host, guest }

class WhotGameState {
  const WhotGameState({
    required this.deck,
    required this.discardPile,
    required this.hostHand,
    required this.guestHand,
    required this.currentTurn,
    this.calledSymbol,
    this.winnerId,
    this.pendingDraw = 0,
  });

  final List<WhotCard> deck;
  final List<WhotCard> discardPile;
  final List<WhotCard> hostHand;
  final List<WhotCard> guestHand;
  final TurnOwner currentTurn;
  final WhotSymbol? calledSymbol;
  final String? winnerId;

  /// Cartes à piocher à cause d'un Pick Two / Pick Three / General Market.
  final int pendingDraw;

  WhotCard? get topDiscard =>
      discardPile.isEmpty ? null : discardPile.last;

  List<WhotCard> handOf(TurnOwner owner) =>
      owner == TurnOwner.host ? hostHand : guestHand;

  WhotGameState copyWith({
    List<WhotCard>? deck,
    List<WhotCard>? discardPile,
    List<WhotCard>? hostHand,
    List<WhotCard>? guestHand,
    TurnOwner? currentTurn,
    WhotSymbol? calledSymbol,
    bool clearCalledSymbol = false,
    String? winnerId,
    int? pendingDraw,
  }) {
    return WhotGameState(
      deck: deck ?? this.deck,
      discardPile: discardPile ?? this.discardPile,
      hostHand: hostHand ?? this.hostHand,
      guestHand: guestHand ?? this.guestHand,
      currentTurn: currentTurn ?? this.currentTurn,
      calledSymbol:
          clearCalledSymbol ? null : (calledSymbol ?? this.calledSymbol),
      winnerId: winnerId ?? this.winnerId,
      pendingDraw: pendingDraw ?? this.pendingDraw,
    );
  }
}
