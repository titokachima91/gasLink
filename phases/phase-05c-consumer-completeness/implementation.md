# Phase 5C — Auth Flow Polish & Consumer Completeness

> **Status:** ✅ Complete
> **Baseline:** `cbae13e`
> **Branch:** `harden-source-of-truth`
> **Rule:** no business logic removed or changed — UI and navigation only.

---

## Slices shipped

| Slice | Commit | Summary |
|-------|--------|---------|
| 1. Auth flow | `0e1f469` | Landing page form removed; dedicated branded Login/Register with Terms + ads consent; Terms/Privacy pages; consent persisted on `users/{uid}` |
| 2. Consumer screens | `4123e28` | New ConsumerSettingsScreen and ConsumerProfileScreen; home app bar links; cylinder screen accepts an empty initial list |
| 3. Home reorder | `5e5a374` | Mitungi Yangu overview above Gas Estimator; section order matches the plan |
| 4. History & settings | `64def5b` | Polished order history (header, status pills, empty state); persisted ads consent; language row; support email |
| 5. Smart Hub restyle | `f536788` | Shared section headers and empty state in the cylinder Smart Hub |

---

## What changed

### Auth flow

- `LandingScreen` keeps only three small entry links: **Ingia**, **Jiandikishe**,
  **Mgeni**. The inline login form was removed.
- `LoginScreen` and `RegisterScreen` share an `AuthHeader` (logo + tagline) and
  `AuthConsents` block:
  - **Required:** “Nakubali Vigezo na Masharti” — login/register stays disabled
    until checked; “Soma” opens the terms page.
  - **Optional (default on):** “Nakubali kupokea matangazo na ofa.”
- Consent is written to `users/{uid}.termsAcceptedAt` and
  `users/{uid}.adsConsent` (admin identity excluded).
- `TermsScreen` and `PrivacyScreen` provide scrollable static legal copy for the
  pilot.
- Guest entry still starts a read-only browsing session; logout from every role
  returns to the landing page.

### Consumer completeness

- **ConsumerSettingsScreen** — account card with masked phone and editable name,
  theme picker, notification toggle (SharedPreferences), ads-consent toggle
  (Firestore), language row (visual), legal pages, version, call/email support,
  and sign out.
- **ConsumerProfileScreen** — identity card, member-since date, quick links to
  cylinders, settings, and terms.
- **Home order** — welcome → Oda Zangu → Mitungi Yangu → Kikadirio cha Gesi →
  quick actions → ad → item list → nearby vendors.
- **Mitungi Yangu overview** — cylinder count, brand/weight summary, and a
  “Simamia” link to the Smart Hub (or the setup sheet when empty).
- **Order history** — section header with count, status pills, formatted
  date/money, shared empty state, and the same tap-through to live tracking.
- **Smart Hub** — shared section headers and a friendly empty state; FIFO and
  CRUD logic untouched.

---

## Verification

| Check | Result |
|-------|--------|
| `flutter analyze` | 0 errors, 0 warnings (51 info lints) |
| `flutter test` | 79/79 passing |
| New tests | `test/auth_consent_test.dart` — terms gating, terms page, ads default, dark mode |
| Landing test | Updated to assert no form and the three entry links |
| Business logic | FIFO, order flows, auth checks, and admin console untouched |

---

## Rollback

Revert slices in reverse order:

```bash
git revert f536788 64def5b 5e5a374 4123e28 0e1f469
```

Or reset to the pre-5C baseline `cbae13e` if the entire phase is being undone.
