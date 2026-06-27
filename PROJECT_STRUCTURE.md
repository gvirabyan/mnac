# PROJECT_STRUCTURE.md — navigation map for «Դեպի Տուն» (depitun)

> Read this first every task to locate files fast. Keep it updated when files are added/moved.
> Conventions: **UI text Armenian (only via `core/l10n/app_strings.dart`)**, **code/comments English**.
> Stack: Flutter 3.38 / Dart 3.10 · Clean Architecture · Riverpod 3.x (`.value`, NOT `.valueOrNull`) · storage = shared_preferences only.

---

## Quick "where do I change X?"

| Task | File(s) |
|------|---------|
| Add/edit any UI text | `lib/core/l10n/app_strings.dart` (single source) |
| Colors / palette / accents | `lib/core/theme/app_colors.dart`, `accent_palette.dart` |
| Fonts / text sizes | `lib/core/theme/app_typography.dart` |
| Light/dark ThemeData | `lib/core/theme/app_theme.dart` |
| Spacing / radius / durations | `lib/core/constants/app_sizes.dart`, `app_durations.dart` |
| Service length / milestone thresholds | `lib/core/constants/service_constants.dart` |
| Countdown / progress math | `lib/domain/usecases/compute_service_progress.dart`, `compute_milestones.dart` |
| Storage keys / persistence | `lib/data/datasources/local_prefs_data_source.dart` |
| Wire a new repo/usecase/service (DI) | `lib/core/di/providers.dart` |
| Add a dependency provider override at startup | `lib/main.dart` |
| Home countdown UI / hero background | `lib/presentation/home/` |
| Multi-soldier list/switch/add/edit/delete | `lib/presentation/soldiers/soldier_switcher_sheet.dart`, `soldier_form/` |
| Notifications logic | `lib/services/notification_service.dart` (synced from `shell/main_shell.dart`) |
| Settings screen sections | `lib/presentation/settings/settings_screen.dart` |
| Share-as-image card (design / flow) | `lib/presentation/share/` (`share_card.dart` visuals, `share_card_screen.dart` preview+share), capture util `lib/services/widget_to_image.dart` |
| Bottom-nav / app-wide listeners (celebration, notif sync) | `lib/presentation/shell/main_shell.dart` |

---

## Key providers (Riverpod)

- **DI / composition root** — `core/di/providers.dart`
  - `sharedPreferencesProvider` (overridden in main), `localPrefsDataSourceProvider`
  - `soldiersRepositoryProvider`, `settingsRepositoryProvider`, `backupRepositoryProvider`
  - `initialSoldiersProvider`, `initialActiveIdProvider`, `initialSettingsProvider` (overridden in main)
  - `computeServiceProgressProvider`, `computeMilestonesProvider`, `backupDataProvider`, `restoreDataProvider`
- **State** — `presentation/shared/state/`
  - `soldiersControllerProvider` (`SoldiersController`, list + activeId) + **`activeSoldierProvider`** ← screens read this for the current soldier
  - `settingsControllerProvider` (`SettingsController`)
  - `immersiveProvider` (bool) — home long-press hides UI + navbar (MainShell watches it)
  - theme: `lightThemeProvider`, `darkThemeProvider`, `themeModeProvider`, `accentColorProvider`, `fontScaleProvider`
- **Home** — `presentation/home/home_controller.dart`
  - `clockProvider` (1s ticker), **`serviceProgressProvider`** (live ServiceProgress for active soldier), `quotesProvider` (FutureProvider<List<String>>)
- **Milestones** — `presentation/milestones/milestones_controller.dart`
  - `milestonesProvider` (list), `pendingCelebrationProvider` (int? threshold to celebrate)
- **Services** — `notificationServiceProvider` (overridden in main with initialized instance), `imageStorageServiceProvider`

---

## File tree (with purpose)

```
lib/
├── main.dart                     # bootstrap: prefs, load soldiers/settings, init NotificationService, ProviderScope overrides
├── app/
│   ├── app.dart                  # MaterialApp, Armenian locale, theme wiring, home: RootGate
│   └── router/app_router.dart    # RootGate (always MainShell — no onboarding) + appPageRoute() transition
├── core/
│   ├── constants/                # app_sizes, app_durations, service_constants
│   ├── l10n/app_strings.dart     # ALL Armenian UI strings + helpers (daysLeftBody, milestoneTitle/Message)
│   ├── theme/                    # app_colors, accent_palette, app_gradients, app_typography (FontScale), app_theme
│   ├── utils/                    # date_utils (AppDateUtils, Armenian months), duration_breakdown, result
│   └── di/providers.dart         # composition root (see providers above)
├── domain/                       # pure Dart, no Flutter
│   ├── entities/                 # soldier_profile, app_settings (AppThemeMode/AnimationLevel enums), service_progress, milestone
│   ├── repositories/             # soldiers_repository, settings_repository, backup_repository (interfaces)
│   └── usecases/                 # compute_service_progress, compute_milestones, backup_data, restore_data
├── data/
│   ├── datasources/local_prefs_data_source.dart  # keys: soldiers_v1, active_soldier_v1, settings_v1, profile_v1(legacy)
│   ├── models/                   # soldier_profile_model, app_settings_model (JSON <-> entity)
│   └── repositories/             # soldiers_repository_impl (migrates legacy profile), settings_repository_impl, backup_repository_impl
├── presentation/
│   ├── shell/
│   │   ├── main_shell.dart        # 4 tabs (extendBody) + app-wide listeners: milestone celebration + notif/widget sync (lifecycle); hides nav in immersive
│   │   └── glass_nav_bar.dart     # custom glassmorphic floating bottom nav (blur + gradient, selected = accent pill w/ label)
│   ├── home/
│   │   ├── home_screen.dart      # empty-state OR countdown; greeting->switcher; bg = ACTIVE SOLDIER's photo (same source as avatar); wallpaper btn sets that photo; long-press => immersive (hide UI+navbar)
│   │   ├── home_controller.dart  # clock/serviceProgress/quotes providers
│   │   └── widgets/              # circular_countdown (CustomPainter), unit_breakdown_row, discharge_date_chip, quote_banner, home_background (painted Ararat / custom image)
│   ├── share/                  # share_card (fixed-size shareable card visuals) + share_card_screen (preview + system share); reached from home top-row share button
│   ├── soldiers/soldier_switcher_sheet.dart  # bottom sheet: list/switch/edit/delete + add; showSoldierSwitcher()
│   ├── soldier_form/
│   │   ├── soldier_form_screen.dart          # create/edit: photo + start date + end date (auto-fills +18mo on start pick); no name/unit/presets
│   │   └── widgets/photo_picker_tile.dart
│   ├── statistics/               # statistics_screen + widgets/ (stat_tile, served_remaining_bar)
│   ├── milestones/               # milestones_screen, milestones_controller, milestone_celebration (confetti+haptics), widgets/milestone_card
│   ├── calendar/                 # calendar_screen + widgets/ (service_calendar grid, calendar_legend)
│   ├── settings/
│   │   ├── settings_screen.dart  # APP-LEVEL only: personalization, _NotificationsGroup, backup/restore/reset, about/feedback (no per-soldier items — soldiers managed from home switcher)
│   │   ├── personalization_screen.dart  # app-level: theme/accent/font/animation only (photo+background are per-soldier, set in soldier form / home)
│   │   ├── about_screen.dart     # about + privacy + version
│   │   └── widgets/              # settings_tile, accent_picker, option_segments
│   └── shared/
│       ├── state/                # soldiers_controller, settings_controller, theme_providers
│       └── widgets/              # gradient_scaffold, glass_card, primary_button, section_header, app_loading, empty_state, animated_counter
└── services/
    ├── notification_service.dart # flutter_local_notifications 22 + timezone; daily inactivity reminder (19:00) + milestones; sync() best-effort
    ├── home_widget_service.dart  # writes countdown to Android home-screen widget via home_widget; sync() from MainShell._syncBackground
    ├── image_storage_service.dart # copy picked images into app docs dir
    └── widget_to_image.dart      # captureBoundaryToPng(): RepaintBoundary -> PNG in temp dir (for share card)

android/app/src/main/kotlin/com/example/depitun/DepitunWidgetProvider.kt  # native widget (RemoteViews) + tap-to-open
android/app/src/main/res/{layout/depitun_widget.xml, xml/depitun_widget_info.xml, drawable/widget_background.xml}

test/
├── app_smoke_test.dart           # boots into home empty-state (no soldier)
├── domain/                       # compute_service_progress, compute_milestones
├── data/serialization_test.dart  # JSON round-trips
└── presentation/                 # home_screen, milestones (pendingCelebration), soldiers_controller
```

Tests override: `sharedPreferencesProvider`, `initialSoldiersProvider`, `initialActiveIdProvider`, `initialSettingsProvider` (and `GoogleFonts.config.allowRuntimeFetching = false` for widget tests).

---

## Native config
- `android/app/build.gradle.kts` — core library desugaring enabled (`desugar_jdk_libs:2.1.4`) for notifications.
- `android/app/src/main/AndroidManifest.xml` — POST_NOTIFICATIONS / RECEIVE_BOOT_COMPLETED / VIBRATE perms + flutter_local_notifications boot receivers.

## Status / roadmap
See `PROJECT_PLAN.md` for the phase checklist. Done: Phases 0–10 + 12, plus onboarding-removal, multi-soldier, Armenian app name. **Skipped: Phase 11** (Android home-screen widgets — user choice). Phase 12.4 partial: app name set; launcher-icon art + native splash need real image assets.

`shared/animations/fade_slide_in.dart` = entrance polish (FadeSlideIn, gated to AnimationLevel.full). Home isolates the 1s rebuild to `_CountdownHero`/`_BreakdownCard` (RepaintBoundary); Calendar/Stats avoid per-second rebuilds.
```
