import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_providers.dart';
import '../../game/engine/whot_engine.dart';
import '../../game/models/game_state.dart';
import '../../game/models/whot_card.dart';
import 'room_model.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(ref.watch(firestoreProvider));
});

class RoomRepository {
  RoomRepository(this._db);

  final FirebaseFirestore _db;
  final WhotEngine _engine = WhotEngine();

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection(AppConstants.roomsCollection);

  Stream<RoomModel?> watchRoom(String roomId) {
    return _rooms.doc(roomId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return RoomModel.fromFirestore(snap);
    });
  }

  Future<RoomModel> createRoom({
    required String hostId,
    required String hostPseudo,
  }) async {
    final doc = _rooms.doc();
    final room = RoomModel(
      roomId: doc.id,
      hostId: hostId,
      status: RoomStatus.waiting,
      hostPseudo: hostPseudo,
    );
    await doc.set(room.toCreateMap());
    return room;
  }

  Future<void> joinRoom({
    required String roomId,
    required String guestId,
    required String guestPseudo,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _rooms.doc(roomId);
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw StateError('Salle introuvable');
      }
      final data = snap.data()!;
      final existingGuest = data['guestId'] as String?;
      if (existingGuest != null &&
          existingGuest.isNotEmpty &&
          existingGuest != guestId) {
        throw StateError('Cette salle est déjà complète');
      }
      if (data['hostId'] == guestId) {
        return;
      }
      tx.update(ref, {
        'guestId': guestId,
        'guestPseudo': guestPseudo,
        'status': RoomStatus.choosingGame.name,
      });
    });
  }

  Future<void> chooseGame({
    required String roomId,
    required GameType gameType,
  }) async {
    if (gameType == GameType.whot) {
      await rematchWhot(roomId);
    } else {
      await _rooms.doc(roomId).update({
        'gameType': 'truthOrDare',
        'status': RoomStatus.playing.name,
        'currentTurn': TurnOwner.host.name,
        'currentPromptId': null,
        'currentPromptType': null,
        'winnerId': null,
      });
    }
  }

  WhotGameState _toWhotState(RoomModel room) {
    return WhotGameState(
      deck: room.deck.map(WhotCard.fromId).toList(),
      discardPile: room.discardPile.map(WhotCard.fromId).toList(),
      hostHand: room.hostHand.map(WhotCard.fromId).toList(),
      guestHand: room.guestHand.map(WhotCard.fromId).toList(),
      currentTurn: room.currentTurn ?? TurnOwner.host,
      calledSymbol: room.calledSymbol == null
          ? null
          : WhotSymbol.values.byName(room.calledSymbol!),
      winnerId: room.winnerId,
      pendingDraw: room.pendingDraw,
    );
  }

  TurnOwner _roleFor(RoomModel room, String uid) {
    if (uid == room.hostId) return TurnOwner.host;
    if (uid == room.guestId) return TurnOwner.guest;
    throw StateError('Tu n\'es pas dans cette salle');
  }

  Map<String, dynamic> _whotFields(WhotGameState state) {
    return {
      'deck': state.deck.map((c) => c.id).toList(),
      'discardPile': state.discardPile.map((c) => c.id).toList(),
      'hostHand': state.hostHand.map((c) => c.id).toList(),
      'guestHand': state.guestHand.map((c) => c.id).toList(),
      'currentTurn': state.currentTurn.name,
      'calledSymbol': state.calledSymbol?.name,
      'pendingDraw': state.pendingDraw,
      'winnerId': state.winnerId,
      if (state.winnerId != null) 'status': RoomStatus.finished.name,
    };
  }

  Future<void> playWhotCard({
    required String roomId,
    required String uid,
    required String cardId,
    WhotSymbol? announcedSymbol,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _rooms.doc(roomId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Salle introuvable');
      final room = RoomModel.fromFirestore(snap);
      final role = _roleFor(room, uid);
      if (room.status != RoomStatus.playing) {
        throw StateError('La partie n\'est pas en cours');
      }
      if (room.currentTurn != role) {
        throw StateError('Ce n\'est pas ton tour');
      }
      final next = _engine.playCard(
        state: _toWhotState(room),
        card: WhotCard.fromId(cardId),
        announcedSymbol: announcedSymbol,
        hostId: room.hostId,
        guestId: room.guestId ?? '',
      );
      tx.update(ref, _whotFields(next));
    });
  }

  Future<void> drawWhot({
    required String roomId,
    required String uid,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _rooms.doc(roomId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Salle introuvable');
      final room = RoomModel.fromFirestore(snap);
      final role = _roleFor(room, uid);
      if (room.currentTurn != role) {
        throw StateError('Ce n\'est pas ton tour');
      }
      final next = _engine.drawCards(state: _toWhotState(room));
      tx.update(ref, _whotFields(next));
    });
  }

  Future<void> rematchWhot(String roomId) async {
    final dealt = _engine.dealNewGame();
    await _rooms.doc(roomId).update({
      'gameType': 'whot',
      'status': RoomStatus.playing.name,
      'deck': dealt.deck.map((c) => c.id).toList(),
      'discardPile': dealt.discardPile.map((c) => c.id).toList(),
      'hostHand': dealt.hostHand.map((c) => c.id).toList(),
      'guestHand': dealt.guestHand.map((c) => c.id).toList(),
      'currentTurn': dealt.currentTurn.name,
      'calledSymbol': null,
      'winnerId': null,
      'pendingDraw': 0,
      'currentPromptId': null,
      'currentPromptType': null,
    });
  }

  Future<void> backToGameChoice(String roomId) async {
    await _rooms.doc(roomId).update({
      'status': RoomStatus.choosingGame.name,
      'gameType': null,
      'deck': <String>[],
      'discardPile': <String>[],
      'hostHand': <String>[],
      'guestHand': <String>[],
      'currentTurn': null,
      'calledSymbol': null,
      'winnerId': null,
      'pendingDraw': 0,
      'currentPromptId': null,
      'currentPromptType': null,
    });
  }

  Future<void> setTruthOrDarePrompt({
    required String roomId,
    required String uid,
    required String promptId,
    required String promptType,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _rooms.doc(roomId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Salle introuvable');
      final room = RoomModel.fromFirestore(snap);
      final role = _roleFor(room, uid);
      if (room.currentTurn != role) {
        throw StateError('Ce n\'est pas ton tour');
      }
      tx.update(ref, {
        'currentPromptId': promptId,
        'currentPromptType': promptType,
      });
    });
  }

  Future<void> nextTruthOrDareTurn({
    required String roomId,
    required String uid,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _rooms.doc(roomId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Salle introuvable');
      final room = RoomModel.fromFirestore(snap);
      final role = _roleFor(room, uid);
      if (room.currentTurn != role) {
        throw StateError('Ce n\'est pas ton tour');
      }
      final next = role == TurnOwner.host ? TurnOwner.guest : TurnOwner.host;
      tx.update(ref, {
        'currentTurn': next.name,
        'currentPromptId': null,
        'currentPromptType': null,
      });
    });
  }
}
