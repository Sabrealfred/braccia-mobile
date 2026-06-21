# Build-out contract — Braccia Mobile (Flutter)

You are one of a team building the Braccia Capital native mobile CRM in Flutter.
The shared foundation is DONE and committed. Build your assigned feature
screen(s) to a polished, production-grade bar (Slack / Notion / Asana /
Salesforce quality) using ONLY the shared kit below.

## Hard rules (do not break the build for others)
1. ONLY create/edit the file(s) explicitly assigned to you. Do NOT touch:
   `lib/core/*`, `lib/ui/widgets/app_widgets.dart`, `lib/router.dart`,
   `lib/main.dart`, `pubspec.yaml`, `lib/providers/providers.dart`,
   `lib/models/models.dart`, `lib/data/repository.dart`, or another agent's screen.
2. Do NOT add pub dependencies. Use only what's already in pubspec:
   `flutter`, `flutter_riverpod`, `supabase_flutter`, `go_router`,
   `google_fonts`, `intl`, material.
3. Keep the EXACT class name + constructor signature the router already imports
   (given in your task). The file path is fixed.
4. If you need extra state/data logic, put it INSIDE your own screen file (or a
   new file with a unique name you own, e.g. `lib/ui/screens/<feature>_models.dart`).
   You MAY add your own Riverpod providers inside your file.
5. Dart 3.12 / Flutter 3.44. Use `color.withValues(alpha: x)` (NOT `withOpacity`).
   Avoid `withOpacity`, avoid `print`. Code must pass `flutter analyze` with zero
   issues for your file.
6. Use `package:` imports OR correct relative imports. Your screens live in
   `lib/ui/screens/`, so the kit is `../widgets/app_widgets.dart`, theme is
   `../../core/theme.dart`, etc.

## Read these first (source of truth)
- `lib/core/theme.dart` — AppColors, AppText, AppRadii, AppSpacing, gradients.
- `lib/ui/widgets/app_widgets.dart` — the shared widget kit (list below).
- `lib/providers/providers.dart` — Riverpod providers.
- `lib/data/repository.dart` — Supabase data access (`repository` singleton).
- `lib/models/models.dart` — UserProfile, Client, Deal, Task, GenericRow.
- `lib/core/formatters.dart` — formatCompactCurrency, formatDate, timeAgo, initialsOf, greeting.
- `lib/ui/screens/home_screen.dart` and `lib/ui/screens/module_screen.dart` —
  REFERENCE implementations. Match their structure, density, and polish.

## Shared widget kit (lib/ui/widgets/app_widgets.dart)
- `AppCard(child, padding, onTap, radius, noPadding)` — white card.
- `DarkCard(child, padding, radius, onTap, gradient)` — dark gradient card.
- `Pressable(child, onTap)` — scale-on-press wrapper.
- `StatusPill(label, color, bg)` + `StatusPill.forStatus(String?)`.
- `GoldButton(label, onTap, icon, loading)` — full-width gold CTA.
- `GlyphTile(icon, color, bg, size, radius)` — tinted square icon.
- `MonogramTile(initials, size)` — dark tile w/ gold initials.
- `AvatarDot(initials, color, size)` — small round avatar.
- `GoldFab(onTap, icon)` — floating + button.
- `BarSparkline(values 0..1, highlightCount, height)`.
- `SectionHead(title, trailing, serif, color)`.
- `DarkHeader(title, leading, actions, bottom, accent)` — dark screen header
  (auto safe-area top inset). Use a back chevron as `leading` on pushed screens.
- `DarkSearchField(hint, controller, onChanged)`.
- `LoadingState()`, `ErrorStateView(error, onRetry)`, `EmptyStateView(message, icon)`.

## Theme tokens (AppColors)
onyx900/800/700/600/650, ink, ivory, surface, gold300/gold500/goldInk/goldText/
goldTextSoft/goldOnDark, green/greenOnDark, red/redOnDark, blue/blueOnDark,
purple/purpleOnDark, hairline/hairlineSoft, muted/mutedOnDark/mutedLight.
Gradients: `AppColors.goldGradient`, `goldGradientVertical`, `darkCardGradient`,
`heroHeaderGradient`, `aiBackdrop`. Text: `AppText.serif(...)`, `AppText.sans(...)`,
`AppText.eyebrow(color)`.

## Data / backend
- `final repository = ...` singleton in `lib/data/repository.dart`. Methods:
  fetchDeals/fetchDeal/advanceDealStage, fetchClients/fetchClient,
  fetchTasks/setTaskDone/insertTask, fetchProfile, dealsStats, countClients,
  countLeadsOpen, and `fetchTable(table, {limit, orderBy})` (best-effort generic
  fetch; returns [] on error — never throws).
- Supabase client: `import '../../core/supabase_client.dart';` → `supabase`.
  Tables (same as web portal): clients, deals, tasks, user_profiles,
  consultant_notes, and (may or may not exist) messages, channels, projects,
  documents, approvals, etc.
- BACKEND-FIRST, RESILIENT: try the real Supabase table first; if it returns
  empty or errors (table/RLS missing), fall back to rich, realistic seeded demo
  data so the screen is ALWAYS beautiful and populated. Writes (send message,
  add task, save note) should attempt to persist to Supabase and degrade
  gracefully (optimistic local update) if the table/permission is absent.
- Riverpod: wrap screens in `ConsumerWidget`/`ConsumerStatefulWidget`. You may
  declare your own `FutureProvider`/`StateNotifierProvider` inside your file.

## Navigation (go_router)
`context.go('/path')` for tab roots, `context.push('/path')` for stacked detail,
`context.pop()` to go back. Routes already wired: `/home /pipeline /ai /clients
/more /deal/:id /client/:id /messages /messages/:channel /tasks /notes /notes/:id
/projects /projects/:id /leads /approvals /credit-stack /settings /module/:id`.

## Visual bar
Match the prototype: 20px horizontal screen padding, ~120px bottom clearance for
the tab bar, DM Serif Display for figures/titles, DM Sans for UI, gold gradient
for primary/active, dark headers fading to ivory bodies, 18–24px card radii,
soft shadows, scale-on-press. Add subtle entrance/hero polish where it elevates
the feel. Make it feel like a flagship fintech app.
