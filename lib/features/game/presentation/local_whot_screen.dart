import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/whot_engine.dart';
import '../models/game_state.dart';
import '../models/whot_card.dart';

/// Plateau Whot 100% local (P0.4) — 2 mains sur le même appareil.
/// Sert à valider les règles avant le branchement Firestore.
class LocalWhotScreen extends ConsumerStatefulWidget {
  const LocalWhotScreen({super.key});

  @override
  ConsumerState<LocalWhotScreen> createState() => _LocalWhotScreenState();
}

class _LocalWhotScreenState extends ConsumerState<LocalWhotScreen> {
  final _engine = WhotEngine();
  late WhotGameState _state;
  String? _message;

  @override
  void initState() {
    super.initState();
    _state = _engine.dealNewGame();
  }

  void _play(WhotCard card) {
    try {
      WhotSymbol? announced;
      if (card.isWhot) {
        announced = WhotSymbol.circle; // défaut UI locale ; dialogue plus tard
      }
      setState(() {
        _state = _engine.playCard(
          state: _state,
          card: card,
          announcedSymbol: announced,
          hostId: 'host',
          guestId: 'guest',
        );
        _message = null;
        if (_state.winnerId != null) {
          _message = 'Victoire : ${_state.winnerId}';
        }
      });
    } catch (e) {
      setState(() => _message = e.toString());
    }
  }

  void _draw() {
    setState(() {
      _state = _engine.drawCards(state: _state);
      _message = null;
    });
  }

  void _redeal() {
    setState(() {
      _state = _engine.dealNewGame();
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final playable = _engine.playableCards(_state);
    final hand = _state.handOf(_state.currentTurn);
    final top = _state.topDiscard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Whot (local)'),
        actions: [
          IconButton(onPressed: _redeal, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Tour : ${_state.currentTurn.name}'
              '${_state.calledSymbol != null ? ' · symbole demandé : ${_state.calledSymbol!.name}' : ''}'
              '${_state.pendingDraw > 0 ? ' · à piocher : ${_state.pendingDraw}' : ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _message!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          const Spacer(),
          if (top != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  top.id,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
          Text('Pioche : ${_state.deck.length}'),
          const Spacer(),
          Text(
            'Main ${_state.currentTurn.name} (${hand.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              itemCount: hand.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final card = hand[i];
                final ok = playable.any((c) => c.id == card.id);
                return ElevatedButton(
                  onPressed: ok && _state.winnerId == null
                      ? () => _play(card)
                      : null,
                  child: Text(card.id),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _state.winnerId == null ? _draw : null,
              child: Text(
                _state.pendingDraw > 0
                    ? 'Piocher ${_state.pendingDraw}'
                    : 'Piocher 1',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
