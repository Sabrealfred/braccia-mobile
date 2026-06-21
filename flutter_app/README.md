# Braccia Capital — Mobile CRM (Flutter)

Native mobile app (Android/iOS) for Braccia Capital's internal staff, built in
**Flutter** over the **same Supabase backend** as the web staff portal
(`crm.bracciacapital.com`). "Onyx & Gold" design system, on the path to full
feature parity with the ~50-module web portal.

> This is the native app referenced by the design handoff. It lives in
> `flutter_app/` inside the `braccia-mobile` repo (alongside the original
> React PWA, which remains untouched).

## Stack

- Flutter 3.44 · Dart 3.12 · Riverpod (state) · go_router (deep-linkable nav) ·
  supabase_flutter (auth + data) · google_fonts (DM Serif Display + DM Sans) · intl.
- **Backend:** the shared Supabase project `ieqizooravdkcyujgiot` (same
  tables/RLS/auth as the web portal). Override via `--dart-define`.
- **Navigation:** bottom tab bar — Home · Pipeline · ✦ Braccia AI · Clients ·
  More — plus stacked routes for every detail/module screen.

## Screens

- **Login** — Supabase email/password (same accounts as web).
- **Home** — pipeline pulse, KPIs, focus-today, AI insight.
- **Pipeline** + **Deal detail** — stage groups, stepper, advance-stage, tabs.
- **Clients** + **Client detail** — book, AUM, KYC, related deals.
- **Braccia AI** — chat assistant grounded on your live Supabase data.
- **Messages** (Slack-grade), **Tasks** (Asana-grade), **Notes** (Notion-grade),
  **Projects** (kanban), **Leads** (Salesforce-grade), **Approvals**,
  **Credit Stack** (premium), **Settings**.
- **All Apps hub** + **adaptive module screen** (KPI / chat / list templates)
  covering the remaining modules.

## Build the APK

GitHub Actions builds a real, downloadable `.apk` on every push (runners ship
the Android SDK). See `.github/workflows/build-apk.yml`:

- Push to the branch, or run the **Build Android APK** workflow manually
  (`workflow_dispatch`), then download the `braccia-mobile-apk` artifact.

### Locally

Requires the Flutter SDK + Android SDK (`dl.google.com` / `maven.google.com`
must be reachable — they are blocked in the Claude Code sandbox, which is why
CI does the build):

```bash
cd flutter_app
flutter pub get
flutter build apk --release          # → build/app/outputs/flutter-apk/app-release.apk
# or a quick install build:
flutter build apk --debug
```

Override the backend at build time:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

## Develop

```bash
cd flutter_app
flutter pub get
flutter run            # on a connected device/emulator
flutter analyze        # static analysis (kept clean)
flutter test           # widget/smoke tests
```

## Project layout

```
lib/
  core/        theme tokens, supabase client, env, formatters, module catalog
  models/      Supabase row models (clients, deals, tasks, profiles…)
  data/        repository (Supabase data access, resilient)
  providers/   Riverpod providers (auth, dashboard, deals, clients, tasks…)
  ui/
    widgets/   shared "Onyx & Gold" widget kit
    screens/   all feature screens
  router.dart  go_router routes
  main.dart    app entry (initializes Supabase)
```
