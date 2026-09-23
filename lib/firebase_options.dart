// Fichier généré manuellement en attendant `flutterfire configure`.
// Remplace ce contenu en lançant : flutterfire configure
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web hors périmètre MVP.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions non supporté pour cette plateforme.',
        );
    }
  }

  /// Placeholders — à remplacer via flutterfire configure.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCeED2P0ZAYNBewogPvKkYcnUiIn35PKZM',
    appId: '1:128342632505:android:3c9a0b2e562114fcebc5e8',
    messagingSenderId: '128342632505',
    projectId: 'duocartes',
    storageBucket: 'duocartes.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBFNRU9RR63ICqoc3q9sUuAOaSedkKHKKU',
    appId: '1:128342632505:ios:e929e80c20d7d64febc5e8',
    messagingSenderId: '128342632505',
    projectId: 'duocartes',
    storageBucket: 'duocartes.firebasestorage.app',
    iosBundleId: 'y',
  );
}
