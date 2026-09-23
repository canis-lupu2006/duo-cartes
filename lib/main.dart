import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: DuoCartesApp()));
}

class DuoCartesApp extends ConsumerStatefulWidget {
  const DuoCartesApp({super.key});

  @override
  ConsumerState<DuoCartesApp> createState() => _DuoCartesAppState();
}

class _DuoCartesAppState extends ConsumerState<DuoCartesApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deepLinkBootstrapProvider);
      DeepLinkBus.onJoin = (roomId) {
        ref.read(routerProvider).go('/join/$roomId');
      };
    });
  }

  @override
  void dispose() {
    DeepLinkBus.onJoin = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'DuoCartes',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
