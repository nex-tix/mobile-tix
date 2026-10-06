# Mobile Validator App — Implementation Plan

## Goal
Build a Flutter Android app for gate staff to validate visitor tickets via QR code scanning, connecting to a CodeIgniter 4 REST API backend.

## Current Context / Assumptions
- **Project structure**: Feature-based architecture already scaffolded under `lib/` (core, features/auth/checkpoint/scanner/dashboard/history, shared, routes).
- **Dependencies needed**: `dio`, `provider`, `mobile_scanner`, `flutter_secure_storage`, `get_it`, `connectivity_plus`, `audioplayers`, `vibration`, `go_router` (or `auto_route`).
- **Backend API**: CI4 REST endpoints at `/api/*` with JWT-like opaque tokens (12h TTL).
- **Target**: Android 8.0+ (API 26), camera permission required.
- **Color palette**:
  - Primary: `#CF4647` (deep red)
  - Secondary: `#F5D061` (gold), `#F8F6F6` (off-white)
  - Accent/Neutral: `#2A363B` (dark teal)

## Architecture / Proposed Approach
Feature-based clean architecture per module: `data` (API + models + repo impl) → `domain` (entities + abstract repo + use cases) → `presentation` (Provider + screens + widgets). Core services (Dio client, secure storage, connectivity) in `core/`. Dependency injection via `get_it` in `injection.dart`. Navigation via `go_router` with route guards for auth.

## Step-by-Step Tasks

### 0. Project Setup & Dependencies
| # | Task | File / Command | Verification |
|---|------|----------------|--------------|
| 0.1 | Add dependencies to `pubspec.yaml` | `flutter pub add dio provider mobile_scanner flutter_secure_storage get_it connectivity_plus audioplayers vibration go_router` | `flutter pub get` succeeds |
| 0.2 | Android permissions in `android/app/src/main/AndroidManifest.xml` | Add `CAMERA`, `VIBRATE`, `INTERNET`, `ACCESS_NETWORK_STATE` | `flutter build apk --debug` compiles |
| 0.3 | Create `core/api/dio_client.dart` with base URL, timeout, auth interceptor | `lib/core/api/dio_client.dart` | Unit test: interceptor adds `Authorization: Bearer <token>` header |
| 0.4 | Create `core/storage/secure_storage.dart` wrapper | `lib/core/storage/secure_storage.dart` | Test: write/read/delete token |
| 0.5 | Create `core/connectivity/connectivity_service.dart` | `lib/core/connectivity/connectivity_service.dart` | Test: stream emits `ConnectivityResult.none`/`wifi`/`mobile` |
| 0.6 | Wire DI in `lib/injection.dart` | Register all core services + repos + usecases + providers | `setupInjection()` runs without error |

### 1. Authentication Feature
| # | Task | File / Command | Verification |
|---|------|----------------|--------------|
| 1.1 | Domain: `User`, `Token` entities | `lib/features/auth/domain/entities/user.dart`, `token.dart` | — |
| 1.2 | Domain: `AuthRepository` abstract class | `lib/features/auth/domain/repositories/auth_repository.dart` | — |
| 1.3 | Domain use cases: `LoginUseCase`, `LogoutUseCase`, `GetMeUseCase`, `CheckSessionUseCase` | `lib/features/auth/domain/usecases/*.dart` | Unit test each use case with mock repo |
| 1.4 | Data: request/response models (`LoginRequest`, `LoginResponse`, `UserModel`) | `lib/features/auth/data/models/*.dart` | JSON serialization test |
| 1.5 | Data: `AuthRemoteDataSource` (Dio calls to `/api/login`, `/api/logout`, `/api/me`) | `lib/features/auth/data/datasources/auth_remote_ds.dart` | Mock Dio, verify endpoint + payload |
| 1.6 | Data: `AuthRepositoryImpl` | `lib/features/auth/data/repositories/auth_repository_impl.dart` | Integration test with mock DS |
| 1.7 | Presentation: `AuthProvider` (ChangeNotifier) exposing `login()`, `logout()`, `user`, `isAuthenticated` | `lib/features/auth/presentation/providers/auth_provider.dart` | Widget test: login flow updates state |
| 1.8 | UI: `LoginScreen` (username/password form, error handling, loading) | `lib/features/auth/presentation/screens/login_screen.dart` | Golden test or manual run |
| 1.9 | Route guard: redirect to `/login` if no valid token | `lib/routes/app_router.dart` | Integration test: unauthenticated → `/login` |

### 2. Checkpoint Selection Feature
| # | Task | File / Command | Verification |
|---|------|----------------|--------------|
| 2.1 | Domain: `Checkpoint` entity + `CheckpointRepository` | `lib/features/checkpoint/domain/entities/checkpoint.dart`, `repositories/checkpoint_repository.dart` | — |
| 2.2 | Use case: `GetCheckpointsUseCase`, `SelectCheckpointUseCase` | `lib/features/checkpoint/domain/usecases/*.dart` | Unit tests |
| 2.3 | Data: model, remote DS (`GET /api/checkpoints`), repo impl | `lib/features/checkpoint/data/...` | Mock test |
| 2.4 | Presentation: `CheckpointProvider` (list + selected) | `lib/features/checkpoint/presentation/providers/checkpoint_provider.dart` | Widget test |
| 2.5 | UI: `CheckpointSelectionScreen` (grid/list of gates) | `lib/features/checkpoint/presentation/screens/checkpoint_selection_screen.dart` | Manual verify |

### 3. Scanner Feature (Core)
| # | Task | File / Command | Verification |
|---|------|----------------|--------------|
| 3.1 | Domain: `ScanMode` enum (checkIn, check), `ScanResult` entity (status enum, ticket details, error) | `lib/features/scanner/domain/entities/*.dart` | — |
| 3.2 | Use cases: `ScanTicketUseCase` (POST `/api/ticket/validate-and-checkin`), `CheckTicketUseCase` (POST `/api/ticket/check`), `ManualInputUseCase` | `lib/features/scanner/domain/usecases/*.dart` | Unit tests with mock repo |
| 3.3 | Data: request/response models for both endpoints | `lib/features/scanner/data/models/*.dart` | JSON test |
| 3.4 | Data: `TicketRemoteDataSource` + `ScannerRepositoryImpl` | `lib/features/scanner/data/...` | Mock test |
| 3.5 | Presentation: `ScannerProvider` (mode toggle, debounce timer, sound/vibration triggers) | `lib/features/scanner/presentation/providers/scanner_provider.dart` | Unit test debounce logic |
| 3.6 | UI: `ScannerScreen` with `MobileScanner` widget, overlay toggle (Check-in / Cek), manual input button | `lib/features/scanner/presentation/screens/scanner_screen.dart` | Run on device/emulator |
| 3.7 | UI: `ScanResultBottomSheet` — colored per status (VALID=green, ALREADY_USED/EXPIRED/CANCELLED=red, NOT_FOUND=grey) using palette | `lib/features/scanner/presentation/widgets/scan_result_bottom_sheet.dart` | Visual verify each status |
| 3.8 | Sound: `assets/sounds/success.mp3`, `error.mp3`; play via `audioplayers` | `lib/shared/utils/sound_service.dart` | Hear beep on scan |
| 3.9 | Vibration: short pulse on scan via `vibration` package | `lib/shared/utils/vibration_service.dart` | Feel vibration |
| 3.10 | Auto-dismiss result after 2s → resume camera | Timer in provider | Observe loop |

### 4. Dashboard Feature
| # | Task | File / Command | Verification |
|---|------|----------------|--------------|
| 4.1 | Domain: `DashboardSummary` entity, `DashboardRepository`, `GetDashboardUseCase(period)` | `lib/features/dashboard/domain/...` | Unit test |
| 4.2 | Data: model + remote DS (`GET /api/dashboard/summary?period=today|month`) | `lib/features/dashboard/data/...` | Mock test |
| 4.3 | Presentation: `DashboardProvider` (today/month tabs) | `lib/features/dashboard/presentation/providers/dashboard_provider.dart` | Widget test |
| 4.4 | UI: `DashboardScreen` with segmented control (Hari Ini / Bulan Ini), 3 metric cards (Masuk, Valid, Ditolak) | `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | Visual verify colors |

### 5. History Feature
| # | Task | File / Command | Verification |
|---|------|----------------|--------------|
| 5.1 | Domain: `ScanHistoryItem` entity, `HistoryRepository`, `GetHistoryUseCase` | `lib/features/history/domain/...` | Unit test |
| 5.2 | Data: model + remote DS (`GET /api/ticket/history`) | `lib/features/history/data/...` | Mock test |
| 5.3 | Presentation: `HistoryProvider` (pagination, pull-to-refresh) | `lib/features/history/presentation/providers/history_provider.dart` | Widget test |
| 5.4 | UI: `HistoryScreen` (ListView with status badge, ticket code, time, checkpoint, count) | `lib/features/history/presentation/screens/history_screen.dart` | Visual verify |

### 6. Shared UI & Theming
| # | Task | File / Command | Verification |
|---|------|----------------|--------------|
| 6.1 | `lib/shared/theme/app_theme.dart` — define `ColorScheme` using palette (primary CF4647, secondary F5D061, surface F8F6F6, onSurface 2A363B) | ThemeData with `useMaterial3: true` | `flutter run` shows themed app |
| 6.2 | Reusable widgets: `PrimaryButton`, `StatusBadge`, `LoadingOverlay`, `ErrorSnackBar` | `lib/shared/widgets/*.dart` | Used in screens |

### 7. Navigation & App Shell
| # | Task | File / Command | Verification |
|---|------|----------------|--------------|
| 7.1 | `lib/routes/app_router.dart` with `GoRouter`: `/login`, `/checkpoint`, `/home` (stateful shell with bottom nav: scanner, dashboard, history, profile) | | Deep-link test |
| 7.2 | `HomeScreen` with `StatefulNavigationShell` + bottom nav bar | `lib/features/home/presentation/screens/home_screen.dart` (new feature folder) | Tab switching works |
| 7.3 | Profile/Logout in drawer or bottom nav 4th tab | | Logout clears token + redirects |

### 8. Error Handling & Offline Banner
| # | Task | File / Command | Verification |
|---|------|----------------|--------------|
| 8.1 | Global `ConnectivityListener` widget wrapping `MaterialApp` showing offline banner | `lib/core/connectivity/connectivity_banner.dart` | Disconnect WiFi → banner appears |
| 8.2 | Disable scan button + show snackbar when offline | In `ScannerProvider` | Scan blocked offline |
| 8.3 | Token expiry / revoked → auto logout + redirect | In `AuthProvider` + Dio interceptor | 401 → logout |

### 9. Testing & Polish
| # | Task | Command | Verification |
|---|------|---------|--------------|
| 9.1 | Unit tests for all use cases (≥80% coverage) | `flutter test --coverage` | `lcov.info` shows coverage |
| 9.2 | Widget tests for providers + key screens | `flutter test` | All green |
| 9.3 | Integration test on emulator: login → checkpoint → scan valid/used/expired/not_found/cancelled → dashboard → history | `flutter test integration_test/` | Manual or `integration_test` |
| 9.4 | Build release APK | `flutter build apk --release` | APK installs on Android 8+ |

## Tests / Validation
- Follow TDD per task: write failing test → implement minimal code → run test → commit.
- Use `mocktail`/`mockito` for mocking repositories and Dio.
- Golden tests for critical UI (scan result colors).

## Risks, Tradeoffs, Open Questions
- **Backend readiness**: API endpoints must exist and return documented JSON; otherwise mock server needed.
- **Camera permission flow**: Android 10+ scoped storage may need runtime rationale.
- **Debounce timing**: 1s debounce may feel slow; consider configurable.
- **Sound assets**: Need to add `assets/sounds/` and declare in `pubspec.yaml`.
- **Token refresh**: Spec says 12h TTL, no refresh endpoint; implement forced re-login on 401.
- **Offline queue**: PRD says *no* offline queue — confirm with stakeholder.
- **Navigation package**: `go_router` vs `auto_route` — pick one early.

## Deliverables
- Working Flutter Android app meeting all PRD features.
- Clean feature-based codebase ready for CI/CD.