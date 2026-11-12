# Phase 05E — UX Refinements & Selectable Language

> **Status:** 🚧 Proposed — **plan only, no code written.**
> **Branch:** `harden-source-of-truth`
> **Baseline:** `a9ee48f` (Phase 5D verified, Phase 6 parked)
> **Rule:** no business logic removed or changed — layout, navigation,
> consent placement, and presentation only.

---

## Scope

Five issues reported after the 5D APK review:

| # | Issue | Workstream |
|---|-------|------------|
| 1 | Referral card sits between the quick actions and the stock list; it should be **before “Unataka kufanya nini?”** so the service grid and stock list stay adjacent | A |
| 2 | The stock list can grow without bound and push **“Wauza Gesi Walio Karibu Nawe”** out of reach; contain it | A |
| 3 | Guest taps **Profile** or **Settings** and lands on a dead-end page; route guests to **login/register** | B |
| 4 | **Terms** and **ads consent** are shown to already-registered customers; they belong only to registration | C |
| 5 | The UI is bilingual (`“Swahili / English”`); replace with **one selectable language** (Swahili, English, more later) | D |

---

## A. Consumer home hierarchy & contained stock list

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
3. **Referral card** (before the service chooser)
4. **“Unataka kufanya nini?”** + 2×2 category grid
5. **Stock list — contained**
6. Ad slot (moved below the stock list)
7. Nearby vendors

### Stock list containment

Recommended pattern — **“first 4 + View all”**:

- Show the first 4 items for the selected intent.
- Add a count + **“Ona zote / View all”** button.
- The button opens a full-height modal bottom sheet with the complete list.
- Selecting an item closes the sheet and keeps the current flow.

Why: no nested scrolling, the home page stays short, nearby vendors remain
reachable, and the pattern scales if the catalogue grows to dozens of brands.

Fallback pattern if a sheet is not wanted: a `ConstrainedBox(maxHeight: 360)`
with an inner `ListView` and a subtle scroll affordance. Nested scrolling must
be tested on small screens.

### Vendor dashboard consistency

`lib/screens/vendor/vendor_dashboard_screen.dart` currently renders:

Today KPIs → Quick Actions → Ad slot → Referral card → Incoming Orders.

Move the referral card **above Quick Actions** (which include **Stoki**) and
move the ad slot below the incoming-orders section. This mirrors the consumer
hierarchy and keeps the referral out of the action flow.

### Acceptance

- Referral card appears before the service chooser on consumer home.
- The service grid is immediately followed by the stock list.
- With 30+ simulated stock items, “Wauza Gesi Walio Karibu Nawe” is still
  reachable without an endless scroll.
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

- Tapping **Profile** or **Settings** as a guest opens the existing
  `SessionGate.requireConsumer` bottom sheet:
  - **Ingia / Log in** → `LandingScreen`
  - **Unda Akaunti / Create account** → `RegisterScreen`
- The profile/settings guard remains as a defensive fallback, but gets
  `actionLabel` + `onAction` (and a secondary register action) so it is never a
  dead end.
- For guests, replace the logout icon with an **“Ingia”** action. Registered
  users keep logout.
- Guests can still change **theme** and **language** from the guest banner or a
  small preferences sheet, so those choices are not locked behind login.

### Acceptance

- Guest → Profile → login/register sheet appears; both buttons navigate.
- Guest → Settings → same.
- No guest path opens a page that cannot be exited or actioned.
- Registered consumer behaviour is unchanged.

---

## C. Registration-only Terms & ads consent

### Current behaviour

- `RegisterScreen` shows `AuthConsents` (required Terms checkbox + optional ads
  consent). `AuthService.register` already stores `termsAcceptedAt` and
  `adsConsent`.
- `ConsumerSettingsScreen` also shows an **Ads** switch and a **Terms** row,
  plus reads/writes `adsConsent` from Firestore.

### Target behaviour

- **Keep** Terms acceptance and ads consent at registration only.
- **Remove from consumer settings:**
  - the “Matangazo / Ads” switch,
  - the “Vigezo na Masharti” row,
  - the now-unused `_adsConsent` state, Firestore read, and
    `_setAdsConsent` write.
- **Keep** “Sera ya Faragha / Privacy” in settings as a read-only reference.
- Keep Terms/Privacy links on the landing page, login screen, and registration
  screen.
- Store `termsAcceptedAt` and `adsConsent` exactly as today; no schema change.

### Recommendation for approval

- Change ads consent at registration to **explicit opt-in, default off**
  (currently default on). This is safer for consent compliance and matches
  “only for registering customer”.
- If a registered user later wants to withdraw ads consent, expose that through
  the Privacy screen or support, not a settings toggle.

### Acceptance

- Registered consumer settings has no Ads switch and no Terms row.
- Registration still blocks without Terms acceptance and still saves the ads
  choice.
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

1. **A** home hierarchy + contained stock list (small, visual)
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
- Manual checks: guest profile/settings, referral position, long stock list,
  language switch + restart, registration consents, registered settings.
- No changes to FIFO, order transitions, auth/session logic, or Firestore
  schema.

---

## Rollback

- A–C are independent commits; revert individually.
- D1–D4 are separate commits; reverting D4 leaves a working app in the previous
  batch’s locale coverage.
- No data migration, so rollback is code-only.
- Rollback baseline: `a9ee48f`.

---

## Decisions needed before coding

1. **Default language:** system locale with Swahili fallback (recommended), or
   always Swahili on first launch?
2. **Ads consent default:** explicit opt-in / default off (recommended), or
   keep default on?
3. **Terms in settings:** remove entirely (recommended; Terms stays on
   registration/landing), or keep a read-only link under “About”?
4. **Stock list pattern:** first 4 + “View all” sheet (recommended), or a
   bounded inner scroll area?
5. **Vendor dashboard:** align the referral card above Quick Actions as well
   (recommended), or leave the vendor dashboard as is?
