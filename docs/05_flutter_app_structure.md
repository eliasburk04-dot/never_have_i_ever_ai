# 5. Flutter App Structure

## State Management: flutter_bloc (BLoC + Cubit)

**Why BLoC:**
- Complex async state (Realtime subscriptions, AI calls, lobby lifecycle)
- Clear separation of UI and business logic
- Built-in testing support
- Event-driven architecture fits game rounds perfectly
- Large ecosystem, production-proven

---

## Folder Architecture

```
lib/
├── main.dart                          # Entry point, app bootstrap
├── app.dart                           # MaterialApp, routing, theme
│
├── core/                              # Shared infrastructure
│   ├── constants/
│   │   ├── app_constants.dart         # Timeouts, limits, defaults
│   │   └── env.dart                   # API_URL from dart-define
│   ├── errors/
│   │   ├── failures.dart              # Failure types
│   │   └── exceptions.dart            # Custom exceptions
│   ├── extensions/
│   │   └── context_extensions.dart    # BuildContext helpers
│   ├── router/
│   │   └── app_router.dart            # GoRouter configuration
│   ├── theme/
│   │   ├── app_theme.dart             # ThemeData definitions
│   │   ├── app_colors.dart            # Color palette
│   │   ├── app_typography.dart        # Text styles
│   │   └── app_spacing.dart           # Spacing constants
│   ├── utils/
│   │   ├── logger.dart                # Logging utility
│   │   └── validators.dart            # Input validation
│   └── widgets/                       # Shared widgets
│       ├── app_button.dart            # Primary/secondary buttons
│       ├── app_card.dart              # Styled card
│       ├── loading_overlay.dart       # Loading state
│       ├── animated_emoji.dart        # Player avatar animations
│       └── countdown_timer.dart       # Round timer widget
│
├── l10n/                              # Localization
│   ├── app_en.arb                     # English strings
│   ├── app_de.arb                     # German strings
│   ├── app_es.arb                     # Spanish strings
│   └── l10n.dart                      # Generated localization class
│
├── data/                              # Data layer
│   ├── repositories/                  # Repository implementations
│       ├── auth_repository.dart       # JWT anonymous auth via BackendSessionService
│       ├── lobby_repository.dart      # HTTP API calls via BackendApiService
│       ├── game_repository.dart       # HTTP API calls via BackendApiService
│       └── premium_repository.dart    # Local StoreKit 2 premium
│
├── domain/                            # Business logic layer
│   ├── entities/                      # Domain entities
│   │   ├── user.dart
│   │   ├── lobby.dart
│   │   ├── player.dart
│   │   ├── round.dart
│   │   └── game_state.dart
│   └── repositories/                  # Abstract repository interfaces
│       ├── i_auth_repository.dart
│       ├── i_lobby_repository.dart
│       ├── i_game_repository.dart
│       └── i_premium_repository.dart
│
├── features/                          # Feature modules
│   ├── splash/
│   │   └── splash_screen.dart
│   │
│   ├── language/
│   │   ├── cubit/
│   │   │   ├── language_cubit.dart
│   │   │   └── language_state.dart
│   │   └── view/
│   │       └── language_select_screen.dart
│   │
│   ├── home/
│   │   └── view/
│   │       └── home_screen.dart
│   │
│   ├── lobby/
│   │   ├── bloc/
│   │   │   ├── lobby_bloc.dart
│   │   │   ├── lobby_event.dart
│   │   │   └── lobby_state.dart
│   │   └── view/
│   │       ├── create_lobby_screen.dart
│   │       ├── join_lobby_screen.dart
│   │       └── lobby_waiting_screen.dart
│   │
│   ├── game/
│   │   ├── bloc/
│   │   │   ├── game_bloc.dart
│   │   │   ├── game_event.dart
│   │   │   └── game_state.dart
│   │   ├── widgets/
│   │   │   ├── question_card.dart
│   │   │   ├── answer_buttons.dart
│   │   │   ├── player_answer_grid.dart
│   │   │   ├── round_transition.dart
│   │   │   └── answer_reveal.dart
│   │   └── view/
│   │       ├── game_round_screen.dart
│   │       └── results_screen.dart
│   │
│   ├── premium/
│   │   ├── cubit/
│   │   │   ├── premium_cubit.dart
│   │   │   └── premium_state.dart
│   │   └── view/
│   │       └── premium_screen.dart
│   │
│   └── settings/
│       ├── cubit/
│       │   ├── settings_cubit.dart
│       │   └── settings_state.dart
│       └── view/
│           └── settings_screen.dart
│
└── services/                          # Platform services
    ├── backend_api_service.dart       # HTTP client (Fastify API)
    ├── backend_session_service.dart   # Anonymous JWT auth
    ├── realtime_service.dart          # Socket.IO realtime subscriptions
    ├── local_question_pool.dart       # Offline JSON question pool
    ├── store_kit_service.dart         # Apple StoreKit 2 (in_app_purchase)
    └── reconnect_service.dart         # Auto-reconnect with exponential backoff
```

---

## Dependency Injection

Using `get_it` + `injectable` for DI:

```dart
// service_locator.dart
final getIt = GetIt.instance;

void setupServiceLocator() {
    // Services
    getIt.registerLazySingleton(() => BackendSessionService());
    getIt.registerLazySingleton(() => BackendApiService(getIt()));
    getIt.registerLazySingleton(() => RealtimeService(getIt()));
    getIt.registerLazySingleton(() => StoreKitService());
    getIt.registerLazySingleton(() => LocalQuestionPool());

    // Repositories
    getIt.registerLazySingleton<IAuthRepository>(
        () => AuthRepository(getIt()));
    getIt.registerLazySingleton<ILobbyRepository>(
        () => LobbyRepository(getIt(), getIt()));
    getIt.registerLazySingleton<IGameRepository>(
        () => GameRepository(getIt(), getIt()));
    getIt.registerLazySingleton<IPremiumRepository>(
        () => PremiumRepository(getIt()));
    getIt.registerLazySingleton<IOfflineSessionRepository>(
        () => OfflineSessionRepository());
}
```

---

## Routing (GoRouter)

```dart
final appRouter = GoRouter(
    initialLocation: '/',
    routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/language', builder: (_, __) => const LanguageSelectScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/lobby/create', builder: (_, __) => const CreateLobbyScreen()),
        GoRoute(path: '/lobby/join', builder: (_, __) => const JoinLobbyScreen()),
        GoRoute(
            path: '/lobby/:id/waiting',
            builder: (_, state) => LobbyWaitingScreen(
                lobbyId: state.pathParameters['id']!,
            ),
        ),
        GoRoute(
            path: '/game/:lobbyId',
            builder: (_, state) => GameRoundScreen(
                lobbyId: state.pathParameters['lobbyId']!,
            ),
        ),
        GoRoute(
            path: '/game/:lobbyId/results',
            builder: (_, state) => ResultsScreen(
                lobbyId: state.pathParameters['lobbyId']!,
            ),
        ),
        GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
);
```

---

## Theme System

```dart
// app_colors.dart
class AppColors {
    // Light theme
    static const background = Color(0xFFF8F5FF);    // Soft lavender white
    static const surface = Color(0xFFFFFFFF);
    static const primary = Color(0xFF6C5CE7);        // Electric purple
    static const secondary = Color(0xFFFF6B9D);      // Party pink
    static const accent = Color(0xFF00D2FF);          // Cyan accent
    static const textPrimary = Color(0xFF1A1A2E);
    static const textSecondary = Color(0xFF6B7280);
    
    // Tone-specific colors
    static const toneSafe = Color(0xFF4ADE80);        // Green
    static const toneDeeper = Color(0xFFFBBF24);      // Amber
    static const toneSecretive = Color(0xFFF97316);   // Orange
    static const toneFreaky = Color(0xFFEF4444);      // Red
    
    // Button colors
    static const iHave = Color(0xFF6C5CE7);           // Purple (bold)
    static const iHaveNot = Color(0xFFE5E7EB);        // Light gray (safe)
}

// app_typography.dart
class AppTypography {
    static const questionStyle = TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.3,
        letterSpacing: -0.5,
    );
    
    static const buttonStyle = TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
    );
    
    static const lobbyCode = TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: 8.0,
        fontFamily: 'SpaceMono', // Monospace for codes
    );
}
```

---

## Key Packages

```yaml
dependencies:
    flutter:
        sdk: flutter
    flutter_localizations:
        sdk: flutter
    
    # State Management
    flutter_bloc: ^8.1.0
    equatable: ^2.0.0
    
    # Navigation
    go_router: ^14.0.0
    
    # Backend
    http: ^1.2.2
    socket_io_client: ^3.1.2
    
    # DI
    get_it: ^7.6.0
    injectable: ^2.3.0
    
    # Storage
    flutter_secure_storage: ^9.0.0
    shared_preferences: ^2.2.0
    
    # In-App Purchase
    in_app_purchase: ^3.2.0  # Apple StoreKit 2
    
    # UI
    flutter_animate: ^4.3.0
    google_fonts: ^6.1.0
    lottie: ^3.0.0
    
    # Utilities
    intl: ^0.19.0
    uuid: ^4.2.0
    logger: ^2.0.0

dev_dependencies:
    flutter_test:
        sdk: flutter
    bloc_test: ^9.1.0
    mocktail: ^1.0.0
    injectable_generator: ^2.4.0
    build_runner: ^2.4.0
    flutter_lints: ^3.0.0
```

---

## Localization Structure

### `l10n/app_en.arb`
```json
{
    "appTitle": "Never Have I Ever",
    "iHave": "I Have",
    "iHaveNot": "I Have Not",
    "createLobby": "Create Lobby",
    "joinLobby": "Join Lobby",
    "enterCode": "Enter lobby code",
    "waitingForPlayers": "Waiting for players...",
    "roundOf": "Round {current} of {total}",
    "@roundOf": {
        "placeholders": {
            "current": {"type": "int"},
            "total": {"type": "int"}
        }
    },
    "playersInLobby": "{count} players",
    "startGame": "Start Game",
    "nsfwMode": "Spicy Mode 🌶️",
    "premium": "Go Premium",
    "settings": "Settings",
    "gameOver": "Game Over!",
    "groupProfile": "Your Group Profile",
    "conservative": "Conservative 😇",
    "adventurous": "Adventurous 😏",
    "wild": "Wild 🔥",
    "fearless": "Fearless 💀"
}
```

### `l10n/app_de.arb`
```json
{
    "appTitle": "Ich hab noch nie",
    "iHave": "Hab ich",
    "iHaveNot": "Hab ich nicht",
    "createLobby": "Lobby erstellen",
    "joinLobby": "Lobby beitreten",
    "enterCode": "Lobby-Code eingeben",
    "waitingForPlayers": "Warte auf Spieler...",
    "roundOf": "Runde {current} von {total}",
    "playersInLobby": "{count} Spieler",
    "startGame": "Spiel starten",
    "nsfwMode": "Pikanter Modus 🌶️",
    "premium": "Premium holen",
    "settings": "Einstellungen",
    "gameOver": "Spiel vorbei!",
    "groupProfile": "Euer Gruppenprofil",
    "conservative": "Brav 😇",
    "adventurous": "Abenteuerlich 😏",
    "wild": "Wild 🔥",
    "fearless": "Furchtlos 💀"
}
```

### `l10n/app_es.arb`
```json
{
    "appTitle": "Yo Nunca Nunca",
    "iHave": "Yo Sí",
    "iHaveNot": "Yo No",
    "createLobby": "Crear sala",
    "joinLobby": "Unirse a sala",
    "enterCode": "Ingresa el código",
    "waitingForPlayers": "Esperando jugadores...",
    "roundOf": "Ronda {current} de {total}",
    "playersInLobby": "{count} jugadores",
    "startGame": "Iniciar juego",
    "nsfwMode": "Modo Picante 🌶️",
    "premium": "Obtener Premium",
    "settings": "Ajustes",
    "gameOver": "¡Fin del juego!",
    "groupProfile": "Perfil del grupo",
    "conservative": "Conservador 😇",
    "adventurous": "Aventurero 😏",
    "wild": "Salvaje 🔥",
    "fearless": "Sin miedo 💀"
}
```

---

## Screen Specifications

### 1. Splash Screen
- Animated logo (Lottie)
- Auto-detect system language → set default
- Anonymous auth happens here
- Navigates to Home after auth

### 2. Language Select
- Three large flag buttons (🇩🇪 🇬🇧 🇪🇸)
- Saved to SharedPreferences + user profile
- Accessible from Settings later

### 3. Home Screen
- App title (bold, large)
- Two primary CTAs: "Create Lobby" / "Join Lobby"
- Premium badge (if not purchased)
- Settings icon (top right)
- Minimal, centered layout

### 4. Create Lobby
- Round count slider (10–100, step 5)
- NSFW toggle (with premium gate)
- Language auto-set from profile
- "Create" button → generates code → navigates to waiting room

### 5. Join Lobby
- 6-character code input (auto-uppercase, large font)
- "Join" button
- Error state if lobby not found / full

### 6. Lobby Waiting Room
- Large lobby code (share-able, tap to copy)
- Player list (emoji + name, animated entry)
- Host sees "Start Game" button (min 2 players)
- Real-time player join/leave updates

### 7. Game Round Screen
- Round counter (top)
- Tone indicator (colored dot/bar)
- Question card (large, centered, animated entrance)
- Countdown timer (circular)
- Two massive buttons at bottom: "I Have" / "I Have Not"
- After answering: waiting state showing who answered
- Answer reveal: group results animation

### 8. Results Screen
- Group boldness profile (emoji + label)
- Round-by-round summary (scrollable)
- Fun stats: "Most honest player", "Most secretive"
- Share button (screenshot-friendly)
- "Play Again" / "Back to Home"

### 9. Premium Screen
- Feature comparison (Free vs Premium)
- Lifetime price
- Purchase button (StoreKit 2)
- Restore purchases

### 10. Settings
- Language selector
- NSFW toggle (premium gated)
- Display name edit
- Avatar emoji picker
- About / Privacy Policy / Terms
