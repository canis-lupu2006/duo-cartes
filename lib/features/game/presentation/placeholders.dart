import 'package:flutter/material.dart';

/// Placeholder P0 — remplacé dès que la sync Firestore Whot est branchée.
class WhotBoardPlaceholder extends StatelessWidget {
  const WhotBoardPlaceholder({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Whot')),
      body: Center(
        child: Text(
          'Plateau Whot synchronisé\n(salle $roomId)\nÀ brancher — P0.5',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class TruthOrDarePlaceholder extends StatelessWidget {
  const TruthOrDarePlaceholder({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Action ou Vérité')),
      body: Center(
        child: Text(
          'Action ou Vérité\n(salle $roomId)\nÀ brancher — P0.8',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ResultPlaceholder extends StatelessWidget {
  const ResultPlaceholder({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Résultat')),
      body: const Center(child: Text('Écran résultat — P0.6')),
    );
  }
}
