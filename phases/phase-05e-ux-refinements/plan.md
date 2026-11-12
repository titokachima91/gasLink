# Phase 05E — UX Refinements & Selectable Language

> **Status:** 🚧 Approved for implementation — docs refined 12 Nov 2026.
> **Default-language decision pending before D1.** No code written yet.
> **Branch:** `harden-source-of-truth`
> **Baseline:** `a9ee48f` (Phase 5D verified, Phase 6 parked)
> **Rule:** no business logic removed or changed — layout, navigation,
> consent placement, and presentation only.

---

## Scope

Six issues reported after the 5D APK review:

| # | Issue | Workstream |
|---|-------|------------|
| 1 | Referral card sits between the quick actions and the stock list; it should be **before “Unataka kufanya nini?”** so the service grid and stock list stay adjacent | A |
| 2 | The stock list can grow without bound and push **“Wauza Gesi Walio Karibu Nawe”** out of reach; add progressive **“View more” (+10)** | A |
| 3 | Guest taps **Profile** or **Settings** and lands on a dead-end page; remove it and route guests to **login/register** | B |
| 4 | **Terms** and **marketing consent** are shown to already-registered customers; they belong only to registration | C |
| 5 | Back on login (and some root screens) exits the app instead of navigating back | B |
| 6 | The UI is bilingual (`“Swahili / English”`); replace with **one selectable language** (Swahili, English, more later) | D |

---

## A. Consumer home hierarchy & progressive stock list

### Current order (`lib/screens/consumer/consumer_home_screen.dart`)

1. Greeting
2. Guest banner **or** My Orders → My Cylinders → Gas Estimator
3. **“Unataka kufanya nini? / Choose Service”** + 2×2 category grid
4. Ad slot
5. **Referral card**
6. Stock list (brand / accessory / service)
7. Nearby vendors

The referral card and ad slot split the category grid from the stock list, and
the stock list is rendered directly into the page `ListView` with no bound.

### Target order

1. Greeting
2. Guest banner **or** My Orders → My Cylinders → Gas Estimator
3. **Referral card** (signed-in consumers only, as today; before the service
   chooser)
4. **“Unataka kufanya nini?”** + 2×2 category grid
5. **Stock list — progressive (10 items + View more)**
6. Ad slot (moved below the stock list)
7. Nearby vendors

Guests keep the current behaviour: no referral card; the chooser follows the
guest banner directly.

### Stock list containment — progressive “View more”

Use **progressive disclosure**, not a sheet:

- Show the first **10** items for the selected intent.
- Add a count + **“Ona zaidi / View more”** button below the list.
- Each tap appends the next **10** items.
- Hide the button when all items are visible.
- Keep the list inline in the page; no nested scroll area.

Why: the page only grows when the user asks for more, so “Wauza Gesi Walio
Karibu Nawe” stays reachable even if the catalogue grows to dozens of brands.
No nested-scrolling conflicts.

### Vendor dashboard consistency

`lib/screens/vendor/vendor_dashboard_screen.dart` currently renders:

Today KPIs → Quick Actions → Ad slot → Referral card → Incoming Orders.

Move the referral card **below Incoming Orders**, then the ad slot last:

Today KPIs → Quick Actions → Incoming Orders → **Referral card** → Ad slot.

### Acceptance

- Referral card appears before the service chooser on consumer home.
- The service grid is immediately followed by the stock list.
- The stock list shows 10 items; each “View more” tap adds 10; the button
  disappears when exhausted.
- With 30+ simulated stock items, “Wauza Gesi Walio Karibu Nawe” is still
  reachable without an endless scroll.
- Vendor dashboard referral sits below Incoming Orders.
- Light and dark mode both checked.

---

## B. Guest Profile / Settings routing

### Current behaviour

- `consumer_home_screen.dart` always pushes `ConsumerProfileScreen` and
  `ConsumerSettingsScreen` from the app bar.
- Both screens have a `SessionGate` guard, but the guard returns a plain
  `AppEmptyState` with **no action button** — a dead end.
- The logout icon is also shown to guests.

### Target behaviour

- **Remove the dead-end guard page.** Tapping **Profile** or **Settings** as a
  guest does not push the page at all; it opens the existing
  `SessionGate.requireConsumer` bottom sheet:
  - **Ingia / Log in** → `LandingScreen`
  - **Unda Akaunti / Create account** → `RegisterScreen`
- The profile/settings screens keep a defensive redirect, not an empty page:
  if the session is not a registered consumer, replace the route with the
  login/register flow. There is no screen left to get stuck on.
- For guests, replace the logout icon with an **“Ingia”** action. Registered
  users keep logout.
- Guests can still change **theme** and **language** from the guest banner or a
  small preferences sheet, so those choices are not locked behind login.

### Back navigation audit (all roles)

Current problems:

- `login_screen.dart` has `PopScope(canPop: false)` and calls
  `SystemNavigator.pop()` on back — pressing back on the login screen exits the
  app instead of returning to the landing page.
- Guest consumer home shows the “exit app?” dialog; back should return to the
  landing page instead.
- Vendor dashboard and admin shell are root routes with no back handling, so
  back can drop the user out of the app without a prompt.

Target rules:

| Screen | Back behaviour |
|--------|----------------|
| Landing | Exit confirmation (or system default) |
| Login / Register | Return to landing |
| Guest consumer home | Return to landing (leave guest mode) |
| Registered consumer home | Exit confirmation at root; pop when a nested route is open |
| Vendor dashboard | Exit confirmation at root; pop nested screens |
| Admin shell | Exit confirmation at root; pop nested screens |
| Any pushed detail/sheet | Pop exactly one route |

Implementation notes:

- Remove the `SystemNavigator.pop()` path from login.
- Add a small shared root-back helper/widget for the three home shells so the
  behaviour is consistent.
- Audit `pushAndRemoveUntil` and `pushReplacement`: only login, logout, and
  role switches should clear the stack. Normal navigation uses `push`.
- Add widget tests for login back, guest home back, and the three root shells.

### Acceptance

- Guest → Profile → login/register sheet appears; both buttons navigate.
- Guest → Settings → same.
- No guest path opens a page that cannot be exited or actioned.
- Back on login returns to landing; back on guest home returns to landing.
- Back on vendor/admin root shows an exit confirmation, not an abrupt exit.
- Back on every pushed screen pops exactly one route.
- Registered consumer behaviour is unchanged.

---

## C. Registration-only Terms & marketing consent

### What “marketing consent” means here (stored as `adsConsent`)

The consent is for **push marketing messages** — notifications, messages, tips,
and offers sent to the user. It is **not** about the in-app `AdSlot` placements
shown inside some screens; those remain part of the normal app experience and
are unaffected.

### Current behaviour

- `RegisterScreen` shows `AuthConsents` (required Terms checkbox + optional
  marketing consent). `AuthService.register` already stores `termsAcceptedAt`
  and `adsConsent`.
- `ConsumerSettingsScreen` also shows an **Ads** switch and a **Terms** row,
  plus reads/writes `adsConsent` from Firestore.

### Target behaviour

- **Keep** Terms acceptance and marketing consent at registration only.
- Update the registration copy so it is explicit: “Nakubali kupokea taarifa,
  ujumbe, vidokezo na ofa kupitia push / I agree to receive notifications,
  messages, tips and offers by push.” The stored field remains `adsConsent` for
  compatibility; no schema change.
- **Remove from consumer settings:**
  - the “Matangazo / Ads” switch,
  - the “Vigezo na Masharti” row from the main legal section,
  - the now-unused `_adsConsent` state, Firestore read, and
    `_setAdsConsent` write.
- **Add an “About GasLink” screen** in settings containing:
  - app version,
  - **Terms & Conditions** (full copy, readable any time),
  - **Privacy Policy**,
  - support contact.
  This keeps Terms available for users who did not read them at registration.
- Keep Terms/Privacy links on the landing page, login screen, and registration
  screen.
- Store `termsAcceptedAt` and `adsConsent` exactly as today; no schema change.

### Decision

- Change marketing consent at registration to **explicit opt-in, default off**
  (currently default on). This is safer for consent compliance and matches
  “only for registering customer”.
- If a registered user later wants to withdraw marketing consent, expose that
  through the Privacy section of About or support, not a settings toggle.

### Acceptance

- Registered consumer settings has no Ads switch and no Terms row in the main
  legal section.
- About contains readable Terms and Privacy copies.
- Registration still blocks without Terms acceptance and still saves the
  marketing choice.
- In-app ad slots are unchanged.
- No Firestore field is renamed or removed.

---

## D. Selectable language (replace bilingual UI)

### Current state

- No `flutter_localizations`, no ARB files, no locale controller.
- **337** strings use the `“Kiswahili / English”` pattern, plus many
  Swahili-only strings with no English counterpart.
- The language rows in consumer settings and the vendor drawer are cosmetic;
  they do not change the app locale.
- `MaterialApp` has no `locale` or `supportedLocales`.

### Target state

One language at a time, selectable and persisted:

- **Kiswahili** (primary)
- **English**
- Architecture ready for more locales later (e.g. French, Hindi) by adding an
  ARB file and one `supportedLocales` entry.

### Architecture

1. Add SDK `flutter_localizations` and `intl: 0.19.0` (the version compatible
   with Flutter 3.24.5). Do **not** upgrade Flutter or the Firebase pins.
2. Add `l10n.yaml`:
   - `arb-dir: lib/l10n`
   - `template-arb-file: app_sw.arb`
   - `output-localization-file: app_localizations.dart`
3. Add `lib/l10n/app_sw.arb` (template) and `lib/l10n/app_en.arb`.
4. Add a `LocaleController` (Riverpod, matching the existing theme controller):
   - values: `system`, `sw`, `en`
   - persisted in `SharedPreferences` under `app_locale`
   - default: system locale if `sw`/`en`, otherwise **Swahili**.
5. Wire `MaterialApp`:
   - `locale: localeController.locale`
   - `supportedLocales: const [Locale('sw'), Locale('en')]`
   - `localizationsDelegates: AppLocalizations.localizationsDelegates`
6. Shared selector UI (`LanguagePickerTile` + `LanguageSheet`) used in:
   - landing/login (small globe action, so guests can switch too),
   - consumer settings,
   - vendor drawer/settings,
   - admin settings.
   Remove the cosmetic language rows and the unused legacy
   `lib/screens/settings_screen.dart` after confirming it has no imports.

### String policy

- **Never** concatenate two languages in one string. Every visible string comes
  from `AppLocalizations`.
- **Canonical data values stay untranslated**: Firestore roles, order statuses,
  service intents (`Refill`, `Full Set`, `Accessories`, `Services`), brand
  names, field keys, and collection names.
- Add display maps for canonical values, e.g.
  `orderStatusLabel(context, 'pending')`.
- **Service-layer errors** become typed codes (`AppError` with `code` +
  optional args); screens map codes to localized text. Auth/register errors are
  in the first batch because they are the most visible.
- Numbers, currency, and dates use `intl` (`NumberFormat.currency` with `TZS`,
  `DateFormat` with the active locale) instead of hand-built strings.

### Migration batches

| Batch | Files | Approx. strings | Contents |
|-------|-------|-----------------|----------|
| **D1** | auth, landing, legal, session gate, shared `app_ui.dart` | ~80 | Infrastructure, locale controller, selector, login/register/guest/consents, error codes |
| **D2** | consumer home, profile, settings, orders, cylinders, estimator, history, GasPlan, referrals | ~150 | Consumer flows |
| **D3** | vendor dashboard, inventory, orders, profile, settings, drawer, badge | ~120 | Vendor flows |
| **D4** | admin shell/screens, ads, notifications, browse/search, misc widgets | ~100 | Admin and remaining surfaces |

Each batch is a separate commit. The app must stay green after every batch.

### Enforcement & tests

- `test/l10n_parity_test.dart` — every key exists in both ARB files; no unused
  template keys.
- `test/no_bilingual_strings_test.dart` — scans `lib/**/*.dart` for the
  `'… / …'` UI pattern and fails with file/line. Allowlist URLs, dates, and
  genuine slash paths.
- Widget tests: switch locale, verify a known label changes and survives a
  restart (SharedPreferences mock).
- Manual matrix: key screens in **sw/en** and **light/dark**.

### Acceptance

- No `“Swahili / English”` labels remain on any screen.
- Selecting English changes the whole UI; selecting Kiswahili changes it back.
- The choice persists across app restarts.
- Guests can change language before signing in.
- Firestore values and business logic are unchanged.

---

## Sequencing

1. **A** home hierarchy + progressive stock list (small, visual)
2. **B** guest routing (small, navigation)
3. **C** registration-only consents (small, settings cleanup)
4. **D1** localization infrastructure + auth/landing/legal
5. **D2** consumer surfaces
6. **D3** vendor surfaces
7. **D4** admin and remaining surfaces

A–C can ship as one polish commit or three small commits. D ships in four
batches. Do not mix D with A–C in the same commit.

---

## Verification

- `flutter analyze` — 0 errors, 0 warnings.
- `flutter test` — all existing tests plus the new l10n tests.
- Release APK built with the fixed toolchain (see `BUILD.md`) and served over
  Wi-Fi for a device pass.
- Manual checks: guest profile/settings, referral position, “View more” with
  30+ items, back navigation on login/guest home/vendor/admin and nested
  screens, language switch + restart, registration consents, registered
  settings, About → Terms/Privacy.
- No changes to FIFO, order transitions, auth/session logic, or Firestore
  schema.

---

## Rollback

- A–C are independent commits; revert individually.
- D1–D4 are separate commits; reverting D4 leaves a working app in the previous
  batch’s locale coverage.
- No data migration, so rollback is code-only.
- Rollback baseline: the docs commit that precedes the first 5E implementation
  commit.

---

## Decisions

Resolved 12 Nov 2026:

1. **Stock list:** progressive **“View more” +10**, not a “View all” sheet.
2. **Vendor dashboard:** referral card **below Incoming Orders**, ad slot last.
3. **Terms:** keep a readable copy under **About**, not in the main settings
   legal section.
4. **Marketing consent:** registration-only, explicit opt-in, default off; it
   covers push notifications/messages/tips/offers, not in-app ad slots.
5. **Guest dead-end page:** remove it; route guests straight to login/register.

Still open:

6. **Default language:** system locale with Swahili fallback (recommended), or
   always Swahili on first launch?
