import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duo_cartes/features/game/presentation/local_whot_screen.dart';

void main() {
  testWidgets('LocalWhotScreen s\'affiche', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LocalWhotScreen()),
      ),
    );
    expect(find.textContaining('Tour'), findsOneWidget);
    expect(find.textContaining('Piocher'), findsOneWidget);
  });
}
