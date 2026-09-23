import 'package:cloud_firestore/cloud_firestore.dart';

import '../../game/models/game_state.dart';

class RoomModel {
  const RoomModel({
    required this.roomId,
    required this.hostId,
    this.guestId,
    required this.status,
    this.gameType,
    this.deck = const [],
    this.discardPile = const [],
    this.hostHand = const [],
    this.guestHand = const [],
    this.currentTurn,
    this.calledSymbol,
    this.winnerId,
    this.currentPromptId,
    this.currentPromptType,
    this.createdAt,
    this.hostPseudo = '',
    this.guestPseudo = '',
    this.pendingDraw = 0,
  });

  final String roomId;
  final String hostId;
  final String? guestId;
  final RoomStatus status;
  final GameType? gameType;
  final List<String> deck;
  final List<String> discardPile;
  final List<String> hostHand;
  final List<String> guestHand;
  final TurnOwner? currentTurn;
  final String? calledSymbol;
  final String? winnerId;
  final String? currentPromptId;
  final String? currentPromptType;
  final DateTime? createdAt;
  final String hostPseudo;
  final String guestPseudo;
  final int pendingDraw;

  bool get isFull => guestId != null && guestId!.isNotEmpty;

  factory RoomModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return RoomModel(
      roomId: doc.id,
      hostId: d['hostId'] as String? ?? '',
      guestId: d['guestId'] as String?,
      status: _parseStatus(d['status'] as String?),
      gameType: _parseGameType(d['gameType'] as String?),
      deck: List<String>.from(d['deck'] as List? ?? const []),
      discardPile: List<String>.from(d['discardPile'] as List? ?? const []),
      hostHand: List<String>.from(d['hostHand'] as List? ?? const []),
      guestHand: List<String>.from(d['guestHand'] as List? ?? const []),
      currentTurn: _parseTurn(d['currentTurn'] as String?),
      calledSymbol: d['calledSymbol'] as String?,
      winnerId: d['winnerId'] as String?,
      currentPromptId: d['currentPromptId'] as String?,
      currentPromptType: d['currentPromptType'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      hostPseudo: d['hostPseudo'] as String? ?? '',
      guestPseudo: d['guestPseudo'] as String? ?? '',
      pendingDraw: d['pendingDraw'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'hostId': hostId,
      'guestId': null,
      'status': RoomStatus.waiting.name,
      'gameType': null,
      'deck': <String>[],
      'discardPile': <String>[],
      'hostHand': <String>[],
      'guestHand': <String>[],
      'currentTurn': null,
      'calledSymbol': null,
      'winnerId': null,
      'currentPromptId': null,
      'currentPromptType': null,
      'createdAt': FieldValue.serverTimestamp(),
      'hostPseudo': hostPseudo,
      'guestPseudo': '',
      'pendingDraw': 0,
    };
  }

  static RoomStatus _parseStatus(String? v) {
    return RoomStatus.values.firstWhere(
      (e) => e.name == v,
      orElse: () => RoomStatus.waiting,
    );
  }

  static GameType? _parseGameType(String? v) {
    if (v == null) return null;
    if (v == 'truthOrDare') return GameType.truthOrDare;
    if (v == 'whot') return GameType.whot;
    return null;
  }

  static TurnOwner? _parseTurn(String? v) {
    if (v == null) return null;
    return TurnOwner.values.firstWhere(
      (e) => e.name == v,
      orElse: () => TurnOwner.host,
    );
  }
}
