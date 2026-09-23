import 'dart:math';

import '../models/game_state.dart';
import '../models/whot_card.dart';

/// Moteur Whot — fonctions pures, testables, sans dépendance réseau/UI.
class WhotEngine {
  WhotEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Jeu standard ~54 cartes : 5 familles + jokers Whot.
  List<WhotCard> buildDeck() {
    const numberedSymbols = [
      WhotSymbol.circle,
      WhotSymbol.cross,
      WhotSymbol.star,
      WhotSymbol.triangle,
      WhotSymbol.square,
    ];
    // Numéros courants du Whot nigérian (hors jokers).
    const numbers = [1, 2, 3, 4, 5, 7, 8, 10, 11, 12, 13, 14];

    final cards = <WhotCard>[];
    for (final symbol in numberedSymbols) {
      for (final n in numbers) {
        cards.add(WhotCard(number: n, symbol: symbol));
      }
    }
    // 5 cartes Whot (jokers)
    for (var i = 1; i <= 5; i++) {
      cards.add(WhotCard(number: 20 + i, symbol: WhotSymbol.whot));
    }
    return cards;
  }

  List<WhotCard> shuffle(List<WhotCard> deck) {
    final copy = List<WhotCard>.from(deck);
    copy.shuffle(_random);
    return copy;
  }

  WhotGameState dealNewGame({TurnOwner firstTurn = TurnOwner.host}) {
    var deck = shuffle(buildDeck());
    final hostHand = deck.take(6).toList();
    deck = deck.skip(6).toList();
    final guestHand = deck.take(6).toList();
    deck = deck.skip(6).toList();

    // Première carte non-Whot pour démarrer la défausse.
    WhotCard starter;
    final remaining = <WhotCard>[];
    starter = deck.first;
    var i = 0;
    for (; i < deck.length; i++) {
      if (!deck[i].isWhot) {
        starter = deck[i];
        break;
      }
    }
    for (var j = 0; j < deck.length; j++) {
      if (j != i) remaining.add(deck[j]);
    }

    return WhotGameState(
      deck: remaining,
      discardPile: [starter],
      hostHand: hostHand,
      guestHand: guestHand,
      currentTurn: firstTurn,
    );
  }

  bool canPlayCard({
    required WhotCard card,
    required WhotCard topCard,
    WhotSymbol? calledSymbol,
    int pendingDraw = 0,
  }) {
    if (pendingDraw > 0) {
      // Seules les cartes Pick Two (2) / Pick Three (5) peuvent s'empiler,
      // sinon le joueur doit piocher. Whot ne contre pas un pick pour le MVP.
      if (card.number == 2 || card.number == 5) {
        return card.number == 2 && (topCard.number == 2 || pendingDraw == 2) ||
            card.number == 5 && (topCard.number == 5 || pendingDraw == 3);
      }
      // Simplification MVP : on peut aussi poser une carte 2/5 correspondant
      // au dernier effet. Sinon → piocher obligatoire.
      return false;
    }

    if (card.isWhot) return true;

    if (calledSymbol != null) {
      return card.symbol == calledSymbol;
    }

    return card.symbol == topCard.symbol || card.number == topCard.number;
  }

  int drawPenaltyFor(WhotCard card) {
    switch (card.number) {
      case 2:
        return 2;
      case 5:
        return 3;
      case 14:
        return 1;
      default:
        return 0;
    }
  }

  bool grantsExtraTurn(WhotCard card) {
    // 1 Hold on, 8 Suspension → adversaire passe = on rejoue.
    return card.number == 1 || card.number == 8;
  }

  bool skipsOpponent(WhotCard card) {
    return card.number == 1 ||
        card.number == 2 ||
        card.number == 5 ||
        card.number == 8 ||
        card.number == 14;
  }

  TurnOwner other(TurnOwner owner) =>
      owner == TurnOwner.host ? TurnOwner.guest : TurnOwner.host;

  WhotGameState playCard({
    required WhotGameState state,
    required WhotCard card,
    WhotSymbol? announcedSymbol,
    required String hostId,
    required String guestId,
  }) {
    final top = state.topDiscard;
    if (top == null) {
      throw StateError('Pas de carte sur la défausse');
    }
    if (!canPlayCard(
      card: card,
      topCard: top,
      calledSymbol: state.calledSymbol,
      pendingDraw: state.pendingDraw,
    )) {
      throw StateError('Carte non jouable: ${card.id}');
    }
    if (card.isWhot && announcedSymbol == null) {
      throw StateError('Un symbole doit être annoncé après une carte Whot');
    }

    final hand = List<WhotCard>.from(state.handOf(state.currentTurn));
    final idx = hand.indexWhere((c) => c.id == card.id);
    if (idx < 0) {
      throw StateError('Carte absente de la main');
    }
    hand.removeAt(idx);

    final discard = List<WhotCard>.from(state.discardPile)..add(card);

    var next = state.copyWith(
      discardPile: discard,
      hostHand:
          state.currentTurn == TurnOwner.host ? hand : state.hostHand,
      guestHand:
          state.currentTurn == TurnOwner.guest ? hand : state.guestHand,
      calledSymbol: card.isWhot ? announcedSymbol : null,
      clearCalledSymbol: !card.isWhot,
      pendingDraw: state.pendingDraw > 0
          ? state.pendingDraw + drawPenaltyFor(card)
          : drawPenaltyFor(card),
    );

    // Victoire si main vide.
    if (hand.isEmpty) {
      final winner =
          state.currentTurn == TurnOwner.host ? hostId : guestId;
      return next.copyWith(winnerId: winner);
    }

    // Si on empile un pick, le tour passe à l'adversaire qui doit répondre
    // ou piocher. Sinon effets spéciaux.
    if (next.pendingDraw > 0 && (card.number == 2 || card.number == 5)) {
      return next.copyWith(currentTurn: other(state.currentTurn));
    }

    if (grantsExtraTurn(card) ||
        (card.number == 14 && next.pendingDraw == 0)) {
      // Hold on / Suspension : on rejoue. General market géré via pendingDraw.
      if (card.number == 1 || card.number == 8) {
        return next.copyWith(currentTurn: state.currentTurn);
      }
    }

    if (card.number == 14) {
      return next.copyWith(currentTurn: other(state.currentTurn));
    }

    if (card.number == 2 || card.number == 5) {
      return next.copyWith(currentTurn: other(state.currentTurn));
    }

    return next.copyWith(currentTurn: other(state.currentTurn));
  }

  WhotGameState drawCards({
    required WhotGameState state,
    int? count,
  }) {
    final n = count ?? (state.pendingDraw > 0 ? state.pendingDraw : 1);
    var deck = List<WhotCard>.from(state.deck);
    var discard = List<WhotCard>.from(state.discardPile);
    final drawn = <WhotCard>[];

    for (var i = 0; i < n; i++) {
      if (deck.isEmpty) {
        if (discard.length <= 1) break;
        final top = discard.removeLast();
        deck = shuffle(discard);
        discard = [top];
      }
      if (deck.isEmpty) break;
      drawn.add(deck.removeAt(0));
    }

    final hand = List<WhotCard>.from(state.handOf(state.currentTurn))
      ..addAll(drawn);

    return state.copyWith(
      deck: deck,
      discardPile: discard,
      hostHand:
          state.currentTurn == TurnOwner.host ? hand : state.hostHand,
      guestHand:
          state.currentTurn == TurnOwner.guest ? hand : state.guestHand,
      pendingDraw: 0,
      currentTurn: other(state.currentTurn),
      clearCalledSymbol: false,
    );
  }

  List<WhotCard> playableCards(WhotGameState state) {
    final top = state.topDiscard;
    if (top == null) return const [];
    return state.handOf(state.currentTurn).where((c) {
      return canPlayCard(
        card: c,
        topCard: top,
        calledSymbol: state.calledSymbol,
        pendingDraw: state.pendingDraw,
      );
    }).toList();
  }
}
