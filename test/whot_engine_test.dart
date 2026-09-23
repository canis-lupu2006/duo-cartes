import 'package:flutter_test/flutter_test.dart';

import 'package:duo_cartes/features/game/engine/whot_engine.dart';
import 'package:duo_cartes/features/game/models/game_state.dart';
import 'package:duo_cartes/features/game/models/whot_card.dart';

void main() {
  late WhotEngine engine;

  setUp(() {
    engine = WhotEngine(random: null);
  });

  test('buildDeck produit assez de cartes (5 familles + whots)', () {
    final deck = engine.buildDeck();
    expect(deck.length, greaterThanOrEqualTo(50));
    expect(deck.where((c) => c.isWhot).length, 5);
  });

  test('canPlayCard : même symbole ou même numéro ou Whot', () {
    const top = WhotCard(number: 7, symbol: WhotSymbol.circle);
    expect(
      engine.canPlayCard(
        card: const WhotCard(number: 3, symbol: WhotSymbol.circle),
        topCard: top,
      ),
      isTrue,
    );
    expect(
      engine.canPlayCard(
        card: const WhotCard(number: 7, symbol: WhotSymbol.star),
        topCard: top,
      ),
      isTrue,
    );
    expect(
      engine.canPlayCard(
        card: const WhotCard(number: 21, symbol: WhotSymbol.whot),
        topCard: top,
      ),
      isTrue,
    );
    expect(
      engine.canPlayCard(
        card: const WhotCard(number: 4, symbol: WhotSymbol.cross),
        topCard: top,
      ),
      isFalse,
    );
  });

  test('canPlayCard respecte calledSymbol après un Whot', () {
    const top = WhotCard(number: 21, symbol: WhotSymbol.whot);
    expect(
      engine.canPlayCard(
        card: const WhotCard(number: 5, symbol: WhotSymbol.star),
        topCard: top,
        calledSymbol: WhotSymbol.star,
      ),
      isTrue,
    );
    expect(
      engine.canPlayCard(
        card: const WhotCard(number: 5, symbol: WhotSymbol.circle),
        topCard: top,
        calledSymbol: WhotSymbol.star,
      ),
      isFalse,
    );
  });

  test('dealNewGame distribue 6 cartes à chaque joueur', () {
    final state = engine.dealNewGame();
    expect(state.hostHand.length, 6);
    expect(state.guestHand.length, 6);
    expect(state.discardPile.length, 1);
    expect(state.discardPile.first.isWhot, isFalse);
  });

  test('playCard Hold on (1) fait rejouer le même joueur', () {
    final state = WhotGameState(
      deck: const [],
      discardPile: const [WhotCard(number: 3, symbol: WhotSymbol.circle)],
      hostHand: const [WhotCard(number: 1, symbol: WhotSymbol.circle)],
      guestHand: const [WhotCard(number: 4, symbol: WhotSymbol.star)],
      currentTurn: TurnOwner.host,
    );
    final next = engine.playCard(
      state: state,
      card: const WhotCard(number: 1, symbol: WhotSymbol.circle),
      hostId: 'h',
      guestId: 'g',
    );
    expect(next.currentTurn, TurnOwner.host);
    expect(next.hostHand, isEmpty);
    expect(next.winnerId, 'h');
  });

  test('Pick two met pendingDraw à 2', () {
    final state = WhotGameState(
      deck: List.generate(
        5,
        (i) => WhotCard(number: 10 + i, symbol: WhotSymbol.triangle),
      ),
      discardPile: const [WhotCard(number: 8, symbol: WhotSymbol.cross)],
      hostHand: const [
        WhotCard(number: 2, symbol: WhotSymbol.cross),
        WhotCard(number: 7, symbol: WhotSymbol.star),
      ],
      guestHand: const [WhotCard(number: 4, symbol: WhotSymbol.star)],
      currentTurn: TurnOwner.host,
    );
    final next = engine.playCard(
      state: state,
      card: const WhotCard(number: 2, symbol: WhotSymbol.cross),
      hostId: 'h',
      guestId: 'g',
    );
    expect(next.pendingDraw, 2);
    expect(next.currentTurn, TurnOwner.guest);
  });

  test('drawCards vide pendingDraw et passe le tour', () {
    final state = WhotGameState(
      deck: const [
        WhotCard(number: 10, symbol: WhotSymbol.triangle),
        WhotCard(number: 11, symbol: WhotSymbol.triangle),
      ],
      discardPile: const [WhotCard(number: 2, symbol: WhotSymbol.cross)],
      hostHand: const [],
      guestHand: const [],
      currentTurn: TurnOwner.guest,
      pendingDraw: 2,
    );
    final next = engine.drawCards(state: state);
    expect(next.pendingDraw, 0);
    expect(next.guestHand.length, 2);
    expect(next.currentTurn, TurnOwner.host);
  });
}
