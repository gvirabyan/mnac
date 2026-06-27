
# PROJECT_PLAN.md — «Դեպի Տուն» (Depi Tun / Toward Home)

> Offline-first Armenian military service countdown app.
> Premium, emotional, motivating. UI 100% in Armenian. Code 100% in English.
> **This document is the single source of truth. Build strictly in order. Check off every task before moving on. Never skip ahead.**

---

## 0. Product Identity

- **App name (UI / Armenian):** «Դեպի Տուն» (Depi Tun — "Toward Home")
- **Package / project id:** `depitun`
- **Concept:** A soldier enters service start date + duration once. The app then becomes a beautiful, emotional companion that counts down to discharge ("զորացրում"), tracks progress, celebrates milestones, and motivates with Armenian quotes.
- **Tone:** Premium, warm, dignified, hopeful — not a cold utility, not a green-camo cliché.
- **Platforms:** Android (primary, incl. home-screen widgets), iOS (supported, no widgets in v1).
- **Constraints:** Offline only. No backend, no Firebase, no auth, no login, no cloud. All data on-device.

---

## 1. Architecture — Clean Architecture + Riverpod

Three layers, dependencies point inward (`presentation` → `domain` ← `data`).

```
presentation  (UI: screens, widgets, controllers/Notifiers)
      │  depends on
domain        (entities, repository interfaces, use cases) — pure Dart, no Flutter
      ▲  implemented by
data          (models/DTOs, local data sources, repository impls)
```

- **domain** has zero dependencies on Flutter or any package. Pure business logic.
- **data** depends on `domain` (implements its interfaces) and on storage packages.
- **presentation** depends on `domain`. Talks to `data` only through Riverpod providers wired at the composition root.
- **core** holds cross-cutting concerns (theme, constants, utils, localization strings, DI) usable by all layers.

### State management — Riverpod
- `flutter_riverpod` with `Notifier` / `AsyncNotifier` classes (no code-gen, to keep the build robust).
- Providers are the dependency-injection mechanism (repositories, services, data sources all exposed as providers).
- A `ProviderScope` at root. Settings/profile use `Notifier`; the live countdown uses a `StreamProvider`/ticker so only the counter rebuilds.
- Rule: keep widgets small; `select`/granular providers to avoid wide rebuilds. Target 60 FPS.

### Storage decision
- **`shared_preferences`** only (no Hive). Rationale: a single `SoldierProfile` object + a `Settings` object + a set of unlocked-milestone flags. Serialize each as JSON under stable keys. Zero code-gen, zero adapters, fully offline, trivial backup/restore (export the JSON).
- Profile photo & background image: copied into app documents dir via `path_provider`; only the file path is stored in prefs.

---

## 2. Folder Structure

```
lib/
├── main.dart                       # bootstrap: init prefs, ProviderScope, run app
├── app/
│   ├── app.dart                    # MaterialApp.router, theme, localization wiring
│   └── router/
│       └── app_router.dart         # route table + onboarding/home gate
├── core/
│   ├── constants/
│   │   ├── app_durations.dart      # animation durations
│   │   ├── app_sizes.dart          # spacing, radii, elevations
│   │   └── service_constants.dart  # default service lengths, milestone thresholds
│   ├── l10n/
│   │   └── app_strings.dart        # ALL Armenian UI strings (single source)
│   ├── theme/
│   │   ├── app_colors.dart         # palette (beige/white/charcoal/flag accents)
│   │   ├── app_gradients.dart
│   │   ├── app_typography.dart     # Noto Sans Armenian text theme
│   │   ├── app_theme.dart          # light + dark ThemeData
│   │   └── accent_palette.dart     # selectable accent colors
│   ├── utils/
│   │   ├── date_utils.dart         # Armenian date formatting, ranges
│   │   ├── duration_breakdown.dart # split duration into Y/M/W/D/H/Min/Sec
│   │   └── result.dart             # lightweight Result/Either type
│   └── di/
│       └── providers.dart          # composition root: prefs, datasource, repo providers
├── domain/
│   ├── entities/
│   │   ├── soldier_profile.dart
│   │   ├── service_progress.dart   # computed countdown + percentages
│   │   ├── milestone.dart
│   │   └── app_settings.dart
│   ├── repositories/
│   │   ├── profile_repository.dart
│   │   └── settings_repository.dart
│   └── usecases/
│       ├── compute_service_progress.dart
│       ├── compute_milestones.dart
│       ├── save_profile.dart
│       ├── load_profile.dart
│       ├── backup_data.dart
│       └── restore_data.dart
├── data/
│   ├── datasources/
│   │   └── local_prefs_data_source.dart
│   ├── models/
│   │   ├── soldier_profile_model.dart
│   │   └── app_settings_model.dart
│   └── repositories/
│       ├── profile_repository_impl.dart
│       └── settings_repository_impl.dart
├── presentation/
│   ├── onboarding/
│   │   ├── onboarding_screen.dart
│   │   ├── onboarding_controller.dart
│   │   └── widgets/ (step_start_date, step_duration, step_unit, step_photo, step_review)
│   ├── home/
│   │   ├── home_screen.dart
│   │   ├── home_controller.dart    # ticker StreamProvider -> ServiceProgress
│   │   └── widgets/ (countdown_card, circular_countdown, unit_breakdown_row,
│   │                 progress_percent, discharge_date_chip, quote_banner, home_background)
│   ├── statistics/
│   │   ├── statistics_screen.dart
│   │   └── widgets/ (stat_tile, progress_bar_section, served_remaining_chart)
│   ├── milestones/
│   │   ├── milestones_screen.dart
│   │   ├── milestone_celebration.dart  # confetti/lottie overlay
│   │   └── widgets/ (milestone_card)
│   ├── calendar/
│   │   ├── calendar_screen.dart
│   │   └── widgets/ (service_calendar, calendar_legend)
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   ├── personalization_screen.dart
│   │   ├── about_screen.dart
│   │   └── widgets/ (settings_tile, accent_picker, theme_switch, font_size_picker)
│   ├── shell/
│   │   └── main_shell.dart         # bottom nav scaffold (Home/Stats/Calendar/Settings)
│   └── shared/
│       ├── widgets/ (glass_card, gradient_scaffold, animated_counter, primary_button,
│       │             section_header, app_loading, empty_state)
│       └── animations/ (fade_slide_in.dart, page_transitions.dart)
└── services/
    ├── notification_service.dart   # flutter_local_notifications + timezone
    └── home_widget_service.dart    # Android home-screen widget bridge
```

`assets/` → `quotes/quotes_hy.json`, `lottie/*.json`, `images/textures/*`, fonts (via google_fonts at runtime, no bundling needed).

---

## 3. Theme System

- **Palette (`app_colors.dart`)**
  - Base: `beige #F4ECE1`, `surface/white #FBF8F3`, `charcoal #1E1B16`, `muted #8A8276`.
  - Armenian flag accents: `apricot/gold #F2A900` (primary accent), `flagRed #D90012`, `flagBlue #0033A0`.
  - Default accent = apricot/gold; selectable in personalization.
- **Dark theme:** charcoal surfaces `#1A1714` / `#221E1A`, warm off-white text, same accents.
- **Gradients:** soft beige→white, charcoal→deep-charcoal, accent glows for cards.
- **Typography:** `google_fonts` Noto Sans Armenian (body) + Noto Serif Armenian (display/headlines) for an elegant editorial feel. Scales with user font-size setting (S/M/L).
- **Shape:** rounded cards (radius 20–28), soft shadows, glassmorphism (`BackdropFilter`) on overlay cards.
- **Density:** generous whitespace, large countdown as the hero element.
- ThemeMode controlled by settings (system / light / dark).

---

## 4. Navigation Flow

- Single `MaterialApp.router` (declarative, no extra package — use `Navigator` + a small route table, or `go_router` only if justified; **decision: lightweight custom `RouteTable` over Navigator 1.0 with a startup gate** to avoid extra dependency risk).
- **No onboarding:** `main` always opens MainShell. The home screen shows an empty-state "add soldier" CTA when the soldiers list is empty.
- **Multi-soldier (revised):** the app supports **many soldiers**. Storage holds a soldiers list (`soldiers_v1`) + an active id (`active_soldier_v1`); a legacy single `profile_v1` is auto-migrated. `SoldiersController` manages the list and active selection; `activeSoldierProvider` feeds all screens. Switch/add/edit/delete via the **soldier switcher** bottom sheet (home greeting tap, or Settings → Զինվորներ).
- **MainShell:** bottom navigation with 4 tabs: Home / Statistics / Calendar / Settings. Milestones reachable from Home & Statistics; Personalization/About nested under Settings.
- Hero animation: profile photo → home; shared-axis page transitions between tabs and pushed screens.

---

## 5. Data / Storage Design

### Entities (domain)
- **SoldierProfile**: `id`, `name?`, `unit?`, `serviceStart (DateTime)`, `serviceDurationDays (int)`, `photoPath?`, `createdAt`.
- **AppSettings**: `themeMode`, `accentColorId`, `backgroundImagePath?`, `fontScaleId`, `animationLevel`, `notificationsEnabled`, `dailyReminderTime?`, `unlockedMilestones (Set<int>)`.
- **ServiceProgress** (computed, not stored): `start`, `end`, `now`, `totalDays`, `daysServed`, `daysRemaining`, `percent (0..1)`, breakdown `years/months/weeks/days/hours/minutes/seconds remaining`, served weeks/months.
- **Milestone**: `thresholdPercent (25/50/75/90/95/99/100)`, `title`, `message`, `unlocked`, `unlockDateEstimate`.

### Persistence keys (shared_preferences)
- `soldiers_v1` → JSON array of SoldierProfileModel (multi-soldier)
- `active_soldier_v1` → id of the active soldier
- `profile_v1` → legacy single profile, auto-migrated into `soldiers_v1` on first load
- `settings_v1` → JSON of AppSettingsModel
- Backup = export soldiers + activeId + settings to a `.json` file; Restore = read & validate, then live-reload controllers.

### Computation rules
- `end = start + Duration(days: durationDays)`.
- `percent = clamp(now - start, 0, total) / total`.
- Breakdown computed from `remaining = end - now`; live ticker updates every second.
- Milestone unlocked when `percent >= threshold/100`; persisted so celebration shows once.

---

## 6. Screens & Components (acceptance summary)

1. **Onboarding** — multi-step: start date (Armenian date picker), duration (presets 24mo/12mo + custom), unit (optional text), photo (optional, image_picker), review→save. Validates dates. Premium stepper with progress.
2. **Home** — gradient/glass background, large circular animated countdown (CustomPainter), unit breakdown (Y/M/W/D/H/Min/Sec animated counters), progress %, estimated discharge date chip, rotating Armenian motivational quote, quick link to milestones.
3. **Statistics** — days served / remaining, weeks served, months served, progress bar, served-vs-remaining visualization, mini calendar peek, milestone summary.
4. **Milestones** — list of 25/50/75/90/95/99/100% cards (locked/unlocked styling); unlocking triggers confetti + Lottie + haptics celebration overlay.
5. **Calendar** — month grid highlighting start day, today, discharge day, milestone dates; legend; swipe between months.
6. **Settings** — Personalization (theme, accent, background image, profile photo, font size, animation level), Notifications (toggle + daily time + milestone toggles), Backup/Restore/Reset, Privacy, About, Feedback.
7. **Widgets (Android)** — small/medium home-screen countdown widget, live-ish updates via WorkManager/AlarmManager through `home_widget`.

Shared components: `GlassCard`, `GradientScaffold`, `AnimatedCounter`, `PrimaryButton`, `SectionHeader`, `CircularCountdown`, `QuoteBanner`, `AppLoading`, `EmptyState`.

---

## 7. Dependencies (pubspec)

Core: `flutter_riverpod`, `shared_preferences`, `google_fonts`, `intl`, `flutter_localizations` (sdk).
UI/anim: `flutter_animate`, `lottie`, `confetti`.
Media/io: `image_picker`, `path_provider`, `share_plus`, `url_launcher`.
Notifications: `flutter_local_notifications`, `timezone`.
Widgets: `home_widget`.
Info: `package_info_plus`.
Dev: keep `flutter_lints`.

Add per phase (not all at once) to keep the build green.

---

## 8. Development Phases & Task Checklist

> Mark `[x]` only after the task is implemented AND `flutter analyze` is clean for the touched code.

### Phase 0 — Foundation & Setup
- [x] 0.1 Write PROJECT_PLAN.md (this file)
- [x] 0.2 Configure `pubspec.yaml` Phase-1 deps (riverpod, shared_preferences, google_fonts, intl, flutter_localizations) + assets/fonts wiring
- [x] 0.3 Create folder skeleton (all dirs from §2)
- [x] 0.4 `core/constants` (sizes, durations, service constants, milestone thresholds)
- [x] 0.5 `core/l10n/app_strings.dart` — central Armenian strings
- [x] 0.6 Theme system: colors, gradients, typography, accent palette, app_theme (light+dark)
- [x] 0.7 `core/utils` (date_utils, duration_breakdown, result)
- [x] 0.8 `flutter analyze` baseline clean

### Phase 1 — Domain Layer
- [x] 1.1 Entities: soldier_profile, app_settings, service_progress, milestone
- [x] 1.2 Repository interfaces: profile_repository, settings_repository
- [x] 1.3 Use cases: compute_service_progress, compute_milestones
- [x] 1.4 Use cases: save/load profile, backup/restore
- [x] 1.5 Unit tests for compute_service_progress & compute_milestones

### Phase 2 — Data Layer
- [x] 2.1 Models (DTOs) + JSON (de)serialization: soldier_profile_model, app_settings_model
- [x] 2.2 local_prefs_data_source (read/write/clear keys)
- [x] 2.3 Repository impls (profile, settings)
- [x] 2.4 `core/di/providers.dart` composition root (prefs/datasource/repo providers)
- [x] 2.5 Round-trip tests (save→load equality)

### Phase 3 — App Shell, Theme Wiring, Navigation
- [x] 3.1 main.dart bootstrap (prefs init, ProviderScope)
- [x] 3.2 app.dart MaterialApp.router + Armenian localization + theme from settings
- [x] 3.3 app_router + startup gate (onboarding vs shell)
- [x] 3.4 main_shell with bottom navigation (4 tabs, placeholder bodies)
- [x] 3.5 Shared widgets: GradientScaffold, GlassCard, PrimaryButton, SectionHeader, AppLoading

### Phase 4 — Soldier Entry (no onboarding)
> Revised per user request: no separate onboarding flow. The app opens straight
> on the home screen; when no profile exists, the home empty-state invites the
> user to add a soldier via a single-screen `SoldierFormScreen` (create/edit).
- [x] 4.1 SoldierFormScreen (single-screen create + edit, replaces stepper)
- [x] 4.2 Form fields (photo, start date, duration selector, name, unit) + validation
- [x] 4.3 Save profile → reactive home update; edit reachable from Settings
- [x] 4.4 Hero photo transition + home empty-state entry point

### Phase 5 — Home Screen
- [x] 5.1 home_controller: 1s ticker StreamProvider → ServiceProgress
- [x] 5.2 CircularCountdown CustomPainter + animation
- [x] 5.3 AnimatedCounter + unit breakdown row
- [x] 5.4 Progress %, discharge date chip
- [x] 5.5 QuoteBanner (load quotes_hy.json, rotate)
- [x] 5.6 Home hero background — painted Mount Ararat scene by default, or the user's custom image full-bleed with a readability scrim (DMB-style backdrop)

### Phase 6 — Statistics
- [x] 6.1 Stat tiles (served/remaining/weeks/months)
- [x] 6.2 Progress bar + served-vs-remaining visualization
- [x] 6.3 Milestone summary peek

### Phase 7 — Milestones
- [x] 7.1 Milestone cards (locked/unlocked)
- [x] 7.2 Unlock detection + persistence
- [x] 7.3 Celebration overlay (confetti + flutter_animate + haptics)

### Phase 8 — Calendar
- [x] 8.1 Month grid painter/widget
- [x] 8.2 Highlight start/today/discharge/milestones + legend
- [x] 8.3 Month navigation

### Phase 9 — Settings & Personalization
- [x] 9.1 Settings screen scaffold + tiles
- [x] 9.2 Personalization (theme, accent, background, photo, font size, animation level) wired to settings repo
- [x] 9.3 Backup / Restore / Reset
- [x] 9.4 Privacy + About (package_info) + Feedback (share/url_launcher)

### Phase 10 — Notifications
- [x] 10.1 notification_service init (timezone, channel) + runtime permissions; Android desugaring + manifest receivers
- [x] 10.2 Daily **inactivity** reminder at chosen time (default 19:00): batch of 30 one-shots re-synced on app open/resume so today's fires only if app not opened; live days-left + rotating quote
- [x] 10.3 Milestone notifications pre-scheduled at upcoming dates (active soldier) + Armenian messages; Settings notifications UI (`_NotificationsGroup`)

### Phase 11 — Android Home-Screen Widgets
### Phase 11 — Android home-screen widget (iOS deferred — needs macOS/Xcode + SwiftUI)
- [x] 11.1 `home_widget` integration + native widget (resizable RemoteViews: title, days remaining, discharge date + %)
- [x] 11.2 Update wiring: `HomeWidgetService.sync` writes data on app start/resume/active-soldier change; native `updatePeriodMillis` 30 min
- [x] 11.3 Tap-to-open via `HomeWidgetLaunchIntent` → MainActivity
- [ ] 11.4 iOS widget (SwiftUI/WidgetKit + App Group) — deferred, requires a Mac

### Phase 12 — Polish & Release Readiness
- [x] 12.1 Shared-axis page transitions (`appPageRoute`); decorative entrance (`FadeSlideIn`) gated to the "full" animation level; `none` disables all motion; counters/rings/bars/quote honor the flag
- [x] 12.2 Performance pass: only the ticking countdown/breakdown watch the 1s provider (each in a `RepaintBoundary`); Calendar & Statistics no longer rebuild every second (compute via `read` / `select` on day granularity)
- [x] 12.3 Empty states (home/stats/calendar) + edge cases: service-complete card, future start date prevented in form
- [~] 12.4 Final naming → **app renamed to «Մնաց»** everywhere (Android label, iOS CFBundleDisplayName, in-app `AppStrings.appName` + about, notif channel desc, home-widget title). **Launcher icon DONE** via `flutter_launcher_icons`: legacy/iOS from `assets/icon/icon.png` (white bg) + Android 8+ **adaptive icon** (transparent `assets/icon/icon_foreground.png`, white background `#FFFFFF`, `adaptive_icon_foreground_inset: 18` for safe zone). Run `dart run flutter_launcher_icons` to regenerate. Native splash image still deferred.
- [x] 12.5 `flutter analyze` clean + 16 tests green + debug APK builds

---

## 9. Working Rules
- UI text: Armenian only, sourced from `app_strings.dart`. Code/identifiers/comments: English only.
- One task at a time, in order. Update this file's checkbox to `[x]` immediately after completing each task.
- Run `flutter analyze` after each phase; keep it clean.
- No placeholder architecture meant to be rewritten — build production-quality from the start.
- Reusable widgets, strong typing, meaningful names, documented public APIs.
```
