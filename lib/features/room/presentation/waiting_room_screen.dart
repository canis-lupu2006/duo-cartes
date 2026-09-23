import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_providers.dart';
import '../../game/models/game_state.dart';
import '../data/room_repository.dart';

class WaitingRoomScreen extends ConsumerWidget {
  const WaitingRoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(roomRepositoryProvider).watchRoom(roomId);
    final invite = AppConstants.inviteLink(roomId);

    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Salle')),
            body: Center(child: Text('Erreur: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final room = snapshot.data;
        if (room == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Salle')),
            body: const Center(child: Text('Salle introuvable')),
          );
        }

        // Navigation selon le statut
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (room.status == RoomStatus.choosingGame) {
            context.go('/room/$roomId/choose');
          } else if (room.status == RoomStatus.playing) {
            if (room.gameType == GameType.whot) {
              context.go('/room/$roomId/whot');
            } else if (room.gameType == GameType.truthOrDare) {
              context.go('/room/$roomId/tod');
            }
          } else if (room.status == RoomStatus.finished) {
            context.go('/room/$roomId/result');
          }
        });

        return Scaffold(
          appBar: AppBar(title: const Text('Salle d\'attente')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.hourglass_top,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  room.isFull
                      ? 'Les deux joueurs sont là !'
                      : 'En attente de l\'autre joueur…',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hôte : ${room.hostPseudo.isEmpty ? '…' : room.hostPseudo}'
                  '${room.guestPseudo.isNotEmpty ? '\nInvité : ${room.guestPseudo}' : ''}',
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                SelectableText(
                  invite,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: invite));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lien copié')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier le lien'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Rejoins-moi sur DuoCartes : $invite',
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Partager (WhatsApp, SMS…)'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Auto-join si l'utilisateur ouvre un deep link et n'est pas encore guest.
class JoinBootstrap extends ConsumerStatefulWidget {
  const JoinBootstrap({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<JoinBootstrap> createState() => _JoinBootstrapState();
}

class _JoinBootstrapState extends ConsumerState<JoinBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  Future<void> _join() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }
    try {
      await ref.read(roomRepositoryProvider).joinRoom(
            roomId: widget.roomId,
            guestId: user.uid,
            guestPseudo: user.displayName ?? 'Invité',
          );
    } catch (_) {
      // Si déjà hôte ou déjà dedans, on continue vers la salle.
    }
    if (mounted) context.go('/room/${widget.roomId}');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
