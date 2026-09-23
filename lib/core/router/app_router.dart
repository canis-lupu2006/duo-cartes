import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/game/presentation/local_whot_screen.dart';
import '../../features/game/presentation/result_screen.dart';
import '../../features/game/presentation/truth_or_dare_screen.dart';
import '../../features/game/presentation/whot_board_screen.dart';
import '../../features/room/presentation/choose_game_screen.dart';
import '../../features/room/presentation/home_screen.dart';
import '../../features/room/presentation/waiting_room_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(firebaseAuthProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthRefresh(auth),
    redirect: (context, state) {
      final loggedIn = auth.currentUser != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/join/:roomId',
        builder: (_, state) => JoinBootstrap(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/room/:roomId',
        builder: (_, state) => WaitingRoomScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/room/:roomId/choose',
        builder: (_, state) => ChooseGameScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/room/:roomId/whot',
        builder: (_, state) => WhotBoardScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/room/:roomId/tod',
        builder: (_, state) => TruthOrDareScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/room/:roomId/result',
        builder: (_, state) => ResultScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/dev/whot-local',
        builder: (_, __) => const LocalWhotScreen(),
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._auth) {
    _auth.authStateChanges().listen((_) => notifyListeners());
  }

  final FirebaseAuth _auth;
}

/// Écoute les deep links duocartes://join/<roomId>
final deepLinkBootstrapProvider = Provider<void>((ref) {
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    final roomId = _roomIdFromUri(uri);
    if (roomId == null) return;
    // Navigation gérée via un callback global léger dans DuoCartesApp.
    DeepLinkBus.emit(roomId);
  });
  appLinks.getInitialLink().then((uri) {
    if (uri == null) return;
    final roomId = _roomIdFromUri(uri);
    if (roomId != null) DeepLinkBus.emit(roomId);
  });
});

String? _roomIdFromUri(Uri uri) {
  if (uri.scheme == 'duocartes' && uri.host == 'join') {
    if (uri.pathSegments.isNotEmpty) return uri.pathSegments.first;
  }
  return null;
}

class DeepLinkBus {
  static void Function(String roomId)? onJoin;

  static void emit(String roomId) => onJoin?.call(roomId);
}
