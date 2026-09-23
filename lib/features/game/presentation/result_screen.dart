import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../room/data/room_model.dart';
import '../../room/data/room_repository.dart';
import '../models/game_state.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final stream = ref.watch(roomRepositoryProvider).watchRoom(roomId);

    return StreamBuilder<RoomModel?>(
      stream: stream,
      builder: (context, snapshot) {
        final room = snapshot.data;
        if (room == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si on relance / change de jeu, suivre le statut.
        if (room.status == RoomStatus.playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            if (room.gameType == GameType.whot) {
              context.go('/room/$roomId/whot');
            } else if (room.gameType == GameType.truthOrDare) {
              context.go('/room/$roomId/tod');
            }
          });
        } else if (room.status == RoomStatus.choosingGame) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/room/$roomId/choose');
          });
        }

        final won = uid != null && room.winnerId == uid;

        return Scaffold(
          appBar: AppBar(title: const Text('Résultat')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  won ? 'Victoire !' : 'Défaite',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  won
                      ? 'Tu as vidé ta main.'
                      : 'Ton adversaire a vidé sa main.',
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(roomRepositoryProvider)
                        .rematchWhot(roomId);
                  },
                  child: const Text('Rejouer'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    await ref
                        .read(roomRepositoryProvider)
                        .backToGameChoice(roomId);
                  },
                  child: const Text('Changer de jeu'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Quitter la salle'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
