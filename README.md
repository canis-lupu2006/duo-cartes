# DuoCartes

> Application mobile de jeu de cartes à distance, en duo, avec appel vidéo intégré.

DuoCartes permet à **deux personnes qui se connaissent** (couple, ami·e, famille) de se retrouver
autour d'un jeu de cartes à distance : on crée une salle privée, on invite l'autre par un simple
lien, on se voit en vidéo, et on joue en temps réel — comme une soirée à deux en visio.

Le MVP couvre **Whot** et **Action ou Vérité**. Le Ludo suivra en V1.1.

---

## 🎯 Vision & problème résolu

Les apps de cartes existantes (Whot King, iWhot, Rami, Belote...) sont construites autour du
**matchmaking public** : adversaires inconnus, classement, ligues. Aucune n'est pensée pour :

- Jouer **avec une personne précise**, choisie (pas un inconnu) ;
- Recréer la sensation d'être **à la même table** via un appel vidéo/audio couplé au jeu ;
- Sans inscription lourde : **un lien, on clique, on joue**.

**Hypothèse du MVP** : *« Deux personnes qui se connaissent peuvent créer une salle privée,
s'appeler en vidéo et jouer une partie de cartes synchronisée, sans friction. »*

---

## ✨ Fonctionnalités

### Implémenté (P0 — fonctionnel)

- 🔐 **Connexion minimale** — pseudo + téléphone/email via Firebase Auth
- 🏠 **Création de salle privée** par un hôte (un document Firestore par salle)
- 🔗 **Lien d'invitation unique** partageable (copie, WhatsApp natif) via `duocartes://join/<roomId>`
- 🛡 **Salle d'attente** « en attente de l'autre joueur » avec partage du lien
- 🎮 **Choix du jeu** visible par les deux joueurs à l'arrivée du 2e joueur
- 🃏 **Whot multi-joueurs synchronisé** (Firestore temps réel, transactions) : main, pile centrale, tour actif
- 🧠 **Moteur Whot local** (`/dev/whot-local`) pour valider les règles hors réseau
- ❓ **Action ou Vérité** : banque de 30 prompts (15 actions, 15 vérités), tour synchronisé, bouton « Suivant » / « Terminer »
- 🏆 **Fin de partie Whot** détectée + écran de résultat (victoire/défaite)
- 🔄 **Rejouer / Changer de jeu** dans la même salle, sans recréer de lien

### En cours (P1 — après P0)

- 🎥 **Appel vidéo/audio Agora.io** en incrustation pendant la partie
- 🔔 **Notification push** simple à l'invitation (Firebase Cloud Messaging)
- 🔌 **Reconnexion basique** si un joueur perd le réseau

---

## 🃏 Règles du jeu

### Whot

Jeu de **54 cartes**, 5 familles (`circle`, `cross`, `star`, `triangle`, `square`) numérotées,
plus des cartes spéciales **Whot** (jokers).

- Chaque joueur reçoit **6 cartes** ; le reste forme la pioche ; la première carte est retournée pour démarrer la pile.
- **Jouer une carte** : même symbole, même numéro, ou carte Whot (jouable à tout moment).

| Carte | Effet |
|---|---|
| **Whot** (joker) | Jouable à tout moment ; annoncer un symbole (`calledSymbol`) que l'adversaire doit respecter |
| **1 (Hold on)** | Le joueur rejoue immédiatement |
| **2 (Pick two)** | L'adversaire pioche 2 cartes et passe son tour |
| **5 (Pick three)** | L'adversaire pioche 3 cartes et passe son tour |
| **8 (Suspension)** | L'adversaire passe son tour |
| **14 (General market)** | L'adversaire pioche une carte |

- Un joueur qui ne peut pas jouer **pioche** une carte ; si le deck est vide, la défausse (sauf la carte du dessus) est remélangée.
- **Le premier joueur à vider sa main gagne.**

### Action ou Vérité

- Tour qui alterne strictement entre les deux joueurs.
- Le joueur choisit **Action** ou **Vérité** ; un prompt du type correspondant est tiré (les derniers prompts de la session sont exclus pour éviter les répétitions immédiates).
- Le prompt est écrit dans la salle et s'affiche chez les deux joueurs.
- Bouton « Suivant » pour passer le tour, « Terminer » pour revenir au choix du jeu. Pas de condition de victoire.

---

## 🧱 Stack technique

| Couche | Technologie |
|---|---|
| Application | **Flutter** (Dart) — cible **Android** |
| Authentification | **Firebase Authentication** (téléphone/email) |
| Base de données temps réel | **Cloud Firestore** (snapshots/listeners + transactions) |
| Appel vidéo/audio | **Agora.io** (P1) |
| Liens d'invitation | Deep link custom `duocartes://` via `app_links` |
| Gestion d'état | **Riverpod** + **go_router** |
| Partage | `share_plus` |

---

## 📁 Structure du projet

```
lib/
├── main.dart                      # Point d'entrée, initialisation Firebase, écoute des deep links
├── firebase_options.dart          # Config Firebase (flutterfire)
├── core/
│   ├── constants/app_constants.dart
│   ├── router/app_router.dart     # Routes go_router + deep links
│   └── theme/app_theme.dart
├── features/
│   ├── auth/                      # Connexion (login), providers Firebase Auth
│   ├── room/                      # Création de salle, salle d'attente, choix du jeu, lien
│   │   ├── data/room_model.dart   # Modèle Room ↔ Firestore
│   │   ├── data/room_repository.dart  # CRUD + transactions de jeu
│   │   └── presentation/          # home, waiting_room, choose_game
│   └── game/
│       ├── engine/whot_engine.dart    # Règles Whot (fonctions pures, testables)
│       ├── models/                # whot_card, game_state
│       ├── presentation/          # whot_board, truth_or_dare, result, local_whot
│       └── widgets/whot_card_view.dart
├── assets/prompts/truth_or_dare.json   # Banque de prompts (30)
test/
├── whot_engine_test.dart          # Tests unitaires du moteur
└── widget_test.dart               # Test de smoke test
```

## 💾 Modèle de données Firestore

Collection **`rooms`** — un document par salle :

| Champ | Type | Description |
|---|---|---|
| `roomId` | string | Identifiant unique de la salle (ID du document) |
| `hostId` / `guestId` | string \| null | UID Firebase des joueurs (`guestId` null tant que personne n'a rejoint) |
| `hostPseudo` / `guestPseudo` | string | Pseudos affichés |
| `status` | string | `waiting` \| `choosingGame` \| `playing` \| `finished` |
| `gameType` | string \| null | `"whot"` ou `"truthOrDare"` |
| `deck` / `discardPile` | array\<string\> | Cartes codées `ex: "7-circle", "whot-20"` |
| `hostHand` / `guestHand` | array\<string\> | Mains des joueurs |
| `currentTurn` | string | `"host"` ou `"guest"` |
| `calledSymbol` | string \| null | Symbole demandé après un Whot |
| `pendingDraw` | int | Cartes à piocher (Pick two / three / General market) |
| `winnerId` | string \| null | Gagnant quand la partie est finie |
| `currentPromptId` / `currentPromptType` | string \| null | Action ou Vérité : prompt en cours |

> ⚠️ Chaque action (jouer une carte, piocher, tirer un prompt) passe par **`runTransaction`**
> pour éviter les conflits si les deux joueurs agissent en même temps.

---

## 🚀 Démarrage

### Prérequis

- Flutter ≥ 3.44 (Dart ≥ 3.12)
- Un projet **Firebase** avec Auth (email/téléphone) + Firestore activés

### Installation

```bash
flutter pub get
flutterfire configure        # génère lib/firebase_options.dart + android/app/google-services.json
flutter run                  # sur un appareil Android branché en USB
```

> Sans configuration Firebase valide, l'app propose **Tester Whot en local**
> (moteur P0, accessible via la route `/dev/whot-local`).

### Tester sur un vrai téléphone (USB)

1. Activer les **Options développeur** (taper 7× sur le numéro de build) puis **Débogage USB** sur le téléphone.
2. Brancher en **Transfert de fichiers (MTP)** (obligatoire sur Huawei/Samsung).
3. Accepter la demande « Autoriser le débogage USB ».
4. Vérifier la détection : `flutter devices`.
5. `flutter run` — l'app utilise le réseau du téléphone (la connexion internet est nécessaire pour Firebase).

---

## 🧪 Tests

```bash
flutter test
```

8 tests actuels : moteur Whot (construction du deck, règles de pose, `calledSymbol`,
distribution, cartes spéciales, pioche) + smoke test de l'écran local.

---

## 🗺 Avancement (ordre strict P0 → P1 → P2)

- [x] **P0.1** Authentification minimale (pseudo + téléphone/email)
- [x] **P0.2** Création de salle + génération du lien
- [x] **P0.3** Rejoindre via le lien → salle d'attente
- [x] **P0.4** Moteur Whot local, testable (2 mains simulées)
- [x] **P0.5** Synchronisation Firestore du Whot (2 appareils)
- [x] **P0.6** Fin de partie + écran de résultat
- [x] **P0.7** Écran de choix du jeu
- [x] **P0.8** Action ou Vérité : banque de prompts + écran synchronisé
- [ ] **P1.1** Agora : appel vidéo/audio en incrustation (les deux jeux)
- [ ] **P1.2** Boutons « Rejouer » (déjà branché) / « Changer de jeu » → polish UX
- [ ] **P1.3** Gestion de la reconnexion basique
- [ ] **P1.4** Notification push à l'invitation (FCM)
- [ ] **P2** Animations de cartes, sons, accueil soigné *(si le temps le permet)*

---

## ⛔ Hors périmètre du MVP

Matchmaking public, salle > 2 joueurs, classements/ligues, chat/emojis, monnaie/IAP/publicité,
historique/statistiques, mode hors-ligne/IA, web/desktop, notifications push avancées,
personnalisation visuelle, **Ludo** (prévu V1.1).

---

## 🔭 Roadmap post-MVP

1. **Ludo** (V1.1) — moteur complet dédié (plateau, dés, pions, captures)
2. Autres jeux (Belote, Uno-like)
3. Mode 3-4 joueurs
4. Salons favoris / amis récurrents
5. Version iOS
6. Personnalisation (thèmes, dos de cartes)
7. Monétisation non intrusive

---

## ✅ Criteria d'acceptation (Definition of Done)

- [ ] Deux téléphones : créer une salle, rejoindre via lien, jouer un Whot complet
- [ ] Chaque action visible chez l'adversaire en **< 2 s**
- [ ] Cartes spéciales (Whot, Pick two/three, Hold on, Suspension, General market) correctes
- [ ] Appel vidéo/audio stable en 4G pendant toute la partie
- [ ] Fin de partie détectée et affichée aux deux joueurs
- [ ] « Rejouer » sans bug de synchro résiduel
- [ ] Aucune fonctionnalité « hors périmètre » ajoutée

---

*Documentation basée sur la spécification `DuoCartes_MVP_Spec.docx` (document interne, non versionné).*