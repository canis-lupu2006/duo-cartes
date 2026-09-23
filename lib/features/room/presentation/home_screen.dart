import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/room_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _roomLinkCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _roomLinkCtrl.dispose();
    super.dispose();
  }

  String? _extractRoomId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    // ID brut collé
    if (RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(trimmed)) return trimmed;
    return null;
  }

  Future<void> _createRoom() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final room = await ref.read(roomRepositoryProvider).createRoom(
            hostId: user.uid,
            hostPseudo: user.displayName ?? 'Hôte',
          );
      if (mounted) context.go('/room/${room.roomId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinFromField() async {
    final roomId = _extractRoomId(_roomLinkCtrl.text);
    if (roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien ou code de salle invalide')),
      );
      return;
    }
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(roomRepositoryProvider).joinRoom(
            roomId: roomId,
            guestId: user.uid,
            guestPseudo: user.displayName ?? 'Invité',
          );
      if (mounted) context.go('/room/$roomId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('DuoCartes'),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Salut ${user?.displayName ?? ''}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Crée une salle privée et invite une seule personne.',
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _busy ? null : _createRoom,
                child: const Text('Créer une partie'),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _roomLinkCtrl,
                decoration: const InputDecoration(
                  hintText: 'Coller le lien ou le code de salle',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : _joinFromField,
                child: const Text('Rejoindre via un lien'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
