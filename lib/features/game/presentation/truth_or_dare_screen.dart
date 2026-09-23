import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../room/data/room_model.dart';
import '../../room/data/room_repository.dart';
import '../models/game_state.dart';

class PromptItem {
  const PromptItem({
    required this.id,
    required this.type,
    required this.text,
  });

  final String id;
  final String type;
  final String text;

  factory PromptItem.fromJson(Map<String, dynamic> json) {
    return PromptItem(
      id: json['id'] as String,
      type: json['type'] as String,
      text: json['text'] as String,
    );
  }
}

final promptsProvider = FutureProvider<List<PromptItem>>((ref) async {
  final raw = await rootBundle.loadString('assets/prompts/truth_or_dare.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => PromptItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

class TruthOrDareScreen extends ConsumerStatefulWidget {
  const TruthOrDareScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<TruthOrDareScreen> createState() => _TruthOrDareScreenState();
}

class _TruthOrDareScreenState extends ConsumerState<TruthOrDareScreen> {
  final _recentIds = <String>[];
  final _rng = Random();
  bool _busy = false;

  PromptItem? _pick(List<PromptItem> all, String type) {
    final pool = all
        .where((p) => p.type == type && !_recentIds.contains(p.id))
        .toList();
    final source = pool.isEmpty
        ? all.where((p) => p.type == type).toList()
        : pool;
    if (source.isEmpty) return null;
    return source[_rng.nextInt(source.length)];
  }

  Future<void> _choose(String type, RoomModel room, String uid) async {
    final prompts = await ref.read(promptsProvider.future);
    final picked = _pick(prompts, type);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(roomRepositoryProvider).setTruthOrDarePrompt(
            roomId: widget.roomId,
            uid: uid,
            promptId: picked.id,
            promptType: type,
          );
      _recentIds.add(picked.id);
      if (_recentIds.length > 8) _recentIds.removeAt(0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final promptsAsync = ref.watch(promptsProvider);
    final stream = ref.watch(roomRepositoryProvider).watchRoom(widget.roomId);

    return StreamBuilder<RoomModel?>(
      stream: stream,
      builder: (context, snapshot) {
        final room = snapshot.data;
        if (room == null || uid == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final myRole =
            uid == room.hostId ? TurnOwner.host : TurnOwner.guest;
        final myTurn = room.currentTurn == myRole;

        final currentPrompt = promptsAsync.whenOrNull(
          data: (list) {
            if (room.currentPromptId == null) return null;
            try {
              return list.firstWhere((p) => p.id == room.currentPromptId);
            } catch (_) {
              return null;
            }
          },
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Action ou Vérité'),
            actions: [
              TextButton(
                onPressed: () async {
                  await ref
                      .read(roomRepositoryProvider)
                      .backToGameChoice(widget.roomId);
                  if (context.mounted) {
                    context.go('/room/${widget.roomId}/choose');
                  }
                },
                child: const Text(
                  'Terminer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  myTurn ? 'À toi de choisir' : 'Tour de l\'autre joueur',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (currentPrompt != null) ...[
                  Text(
                    currentPrompt.type == 'action' ? 'ACTION' : 'VÉRITÉ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentPrompt.text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ] else
                  const Text(
                    'Choisis Action ou Vérité',
                    textAlign: TextAlign.center,
                  ),
                const Spacer(),
                if (myTurn && room.currentPromptId == null) ...[
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () => _choose('action', room, uid),
                    child: const Text('Action'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _choose('verite', room, uid),
                    child: const Text('Vérité'),
                  ),
                ],
                if (myTurn && room.currentPromptId != null) ...[
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            try {
                              await ref
                                  .read(roomRepositoryProvider)
                                  .nextTruthOrDareTurn(
                                    roomId: widget.roomId,
                                    uid: uid,
                                  );
                            } finally {
                              if (mounted) setState(() => _busy = false);
                            }
                          },
                    child: const Text('Suivant'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
