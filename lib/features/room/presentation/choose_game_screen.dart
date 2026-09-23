import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/models/game_state.dart';
import '../data/room_model.dart';
import '../data/room_repository.dart';

class ChooseGameScreen extends ConsumerWidget {
  const ChooseGameScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(roomRepositoryProvider).watchRoom(roomId);

    Future<void> pick(GameType type) async {
      try {
        await ref.read(roomRepositoryProvider).chooseGame(
              roomId: roomId,
              gameType: type,
            );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }

    return StreamBuilder<RoomModel?>(
      stream: stream,
      builder: (context, snapshot) {
        final room = snapshot.data;
        if (room != null && room.status == RoomStatus.playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            if (room.gameType == GameType.whot) {
              context.go('/room/$roomId/whot');
            } else if (room.gameType == GameType.truthOrDare) {
              context.go('/room/$roomId/tod');
            }
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Choix du jeu')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choisissez ensemble',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Un des deux joueurs lance le jeu — l\'autre suit automatiquement.',
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                _GameChoiceCard(
                  title: 'Whot',
                  subtitle: 'Jeu de cartes classique',
                  onTap: () => pick(GameType.whot),
                ),
                const SizedBox(height: 16),
                _GameChoiceCard(
                  title: 'Action ou Vérité',
                  subtitle: 'Questions & défis en duo',
                  onTap: () => pick(GameType.truthOrDare),
                ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GameChoiceCard extends StatelessWidget {
  const _GameChoiceCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
