import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../room/data/room_model.dart';
import '../../room/data/room_repository.dart';
import '../engine/whot_engine.dart';
import '../models/game_state.dart';
import '../models/whot_card.dart';
import '../widgets/whot_card_view.dart';

class WhotBoardScreen extends ConsumerWidget {
  const WhotBoardScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final stream = ref.watch(roomRepositoryProvider).watchRoom(roomId);

    return StreamBuilder<RoomModel?>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final room = snapshot.data;
        if (room == null) {
          return const Scaffold(
            body: Center(child: Text('Salle introuvable')),
          );
        }

        if (room.status == RoomStatus.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/room/$roomId/result');
          });
        }

        if (uid == null) {
          return const Scaffold(body: Center(child: Text('Non connecté')));
        }

        return _WhotBoardBody(room: room, uid: uid);
      },
    );
  }
}

class _WhotBoardBody extends ConsumerStatefulWidget {
  const _WhotBoardBody({required this.room, required this.uid});

  final RoomModel room;
  final String uid;

  @override
  ConsumerState<_WhotBoardBody> createState() => _WhotBoardBodyState();
}

class _WhotBoardBodyState extends ConsumerState<_WhotBoardBody> {
  final _engine = WhotEngine();
  bool _busy = false;
  String? _error;

  TurnOwner get _myRole {
    if (widget.uid == widget.room.hostId) return TurnOwner.host;
    return TurnOwner.guest;
  }

  bool get _myTurn => widget.room.currentTurn == _myRole;

  List<WhotCard> get _myHand {
    final ids =
        _myRole == TurnOwner.host ? widget.room.hostHand : widget.room.guestHand;
    return ids.map(WhotCard.fromId).toList();
  }

  List<WhotCard> get _opponentHand {
    final ids =
        _myRole == TurnOwner.host ? widget.room.guestHand : widget.room.hostHand;
    return ids.map(WhotCard.fromId).toList();
  }

  WhotGameState get _state {
    return WhotGameState(
      deck: widget.room.deck.map(WhotCard.fromId).toList(),
      discardPile: widget.room.discardPile.map(WhotCard.fromId).toList(),
      hostHand: widget.room.hostHand.map(WhotCard.fromId).toList(),
      guestHand: widget.room.guestHand.map(WhotCard.fromId).toList(),
      currentTurn: widget.room.currentTurn ?? TurnOwner.host,
      calledSymbol: widget.room.calledSymbol == null
          ? null
          : WhotSymbol.values.byName(widget.room.calledSymbol!),
      winnerId: widget.room.winnerId,
      pendingDraw: widget.room.pendingDraw,
    );
  }

  Future<void> _play(WhotCard card) async {
    WhotSymbol? announced;
    if (card.isWhot) {
      announced = await showDialog<WhotSymbol>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Choisis un symbole'),
          children: WhotSymbol.values
              .where((s) => s != WhotSymbol.whot)
              .map(
                (s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s),
                  child: Text(s.name),
                ),
              )
              .toList(),
        ),
      );
      if (announced == null) return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(roomRepositoryProvider).playWhotCard(
            roomId: widget.room.roomId,
            uid: widget.uid,
            cardId: card.id,
            announcedSymbol: announced,
          );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _draw() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(roomRepositoryProvider).drawWhot(
            roomId: widget.room.roomId,
            uid: widget.uid,
          );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = _state.topDiscard;
    final playable = _myTurn ? _engine.playableCards(_state) : <WhotCard>[];
    final opponentName = _myRole == TurnOwner.host
        ? (widget.room.guestPseudo.isEmpty ? 'Adversaire' : widget.room.guestPseudo)
        : (widget.room.hostPseudo.isEmpty ? 'Adversaire' : widget.room.hostPseudo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Whot'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text('$opponentName · ${_opponentHand.length} cartes'),
                  const Spacer(),
                  Text(
                    _myTurn ? 'À toi de jouer' : 'Tour adverse',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _myTurn
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.room.calledSymbol != null)
              Text('Symbole demandé : ${widget.room.calledSymbol}'),
            if (widget.room.pendingDraw > 0)
              Text('À piocher : ${widget.room.pendingDraw}'),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Container(
                      width: 72,
                      height: 104,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4332),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.room.deck.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Pioche'),
                  ],
                ),
                const SizedBox(width: 24),
                if (top != null) WhotCardView(card: top),
              ],
            ),
            const Spacer(),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _myHand.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final card = _myHand[i];
                  final ok = playable.any((c) => c.id == card.id);
                  return WhotCardView(
                    card: card,
                    enabled: ok && !_busy && _myTurn,
                    onTap: () => _play(card),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ElevatedButton(
                onPressed: _busy || !_myTurn ? null : _draw,
                child: Text(
                  widget.room.pendingDraw > 0
                      ? 'Piocher ${widget.room.pendingDraw}'
                      : 'Piocher',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
