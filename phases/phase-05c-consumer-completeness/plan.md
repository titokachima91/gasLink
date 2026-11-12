# Phase 05C — Auth Flow Polish & Consumer Completeness

> **Status:** ✅ Complete — see `implementation.md` for commits and verification.
> **Branch:** `harden-source-of-truth`
> **Rollback baseline:** `cbae13e`
> **Phase 6 (security hardening):** intentionally set aside this round.

---

## A. Landing + Login/Register flow

### Landing page (final form)

Top to bottom:

1. **Hero** — GasLink logo image, name, tagline, one-line subtext.
2. **Small text links row** — `Ingia / Log in` · `Jiandikishe / Register` ·
   `Mgeni / Guest`. No form on this page.
   - Ingia → **LoginScreen**
   - Jiandikishe → **RegisterScreen**
   - Mgeni → guest session → consumer home (read-only)
3. **Value props** — 3 cards (verified vendors · home delivery · market prices).
4. **How it works** — 3 numbered steps.
5. **Districts served** — pills.
6. **Ad slot** (`landing`).
7. **"Tangaza nasi / Advertise with us"** link.

Logout from any role returns to this landing page.

### LoginScreen (redesigned, not boring)

- Logo + app name header.
- Phone field, PIN field (same logic as today).
- **Required checkbox:** "Nakubali Vigezo na Masharti / I agree to the Terms
  & Conditions" — link opens the terms page.
- **Optional checkbox (default on):** "Nakubali kupokea matangazo na ofa /
  I agree to receive ads & promotions."
- Login button (enabled only when terms accepted).
- "Huna akaunti? Jiandikishe" link → RegisterScreen.
- "Rudi nyumbani / Back" → LandingScreen.
- Trust micro-line: "PIN yako ni siri. Data salama na GasLink."
- Consent is persisted per user: `users/{uid}.termsAcceptedAt` and
  `users/{uid}.adsConsent`.

### RegisterScreen (redesigned to match)

- Same branding header + phone, PIN, confirm-PIN fields.
- Same two checkboxes (terms required, ads optional).
- Register button; "Tayari una akaunti? Ingia" → LoginScreen; back → landing.

### Terms & Privacy pages

- Simple scrollable static pages (`TermsScreen`, `PrivacyScreen`) with
  placeholder legal text, reachable from login/register/settings.

---

## B. Consumer completeness

### New: ConsumerSettingsScreen ("Mipangilio / Settings")

Sections:

1. **Akaunti / Account** — avatar + phone (masked) + name, `Badilisha jina`
   edit (writes `users/{uid}.name`), "Jiandikishe kama muuzaji" info row.
2. **Muonekano / Appearance** — System/Light/Dark segmented picker.
3. **Mapendeleo / Preferences** — notification toggle (persisted), language
   row (Swahili/English, visual only), ads consent toggle (writes
   `adsConsent`).
4. **Sera / Legal** — Vigezo na Masharti, Sera ya Faragha, about/version.
5. **Msaada / Support** — call support, support email.
6. **Ondoka / Sign out** — returns to the landing page.

Entry points:

- Consumer home app bar: settings icon (next to theme button).
- Guest banner: "Mipangilio" hidden for guests (login first).

### New: ConsumerProfileScreen ("Wasifu / Profile")

- Editable display name, phone (read-only), account created date.
- Quick links: order history, my cylinders, settings.

### Polished existing surfaces (no logic changes)

- **Order history** — section headers, status pills, empty state.
- **My cylinders (Smart Hub)** — section header + card restyle; FIFO logic
  untouched.
- **Order tracker / Oda Zangu** — keep logic, section header already added.

### Home reorder (C)

Registered consumer home section order becomes:

1. Welcome header
2. Oda Zangu / My Orders (tracker)
3. **Mitungi Yangu / My Cylinders (gauges)** ← moved UP
4. **Kikadirio cha Gesi / Gas Estimator** ← moved DOWN
5. Quick actions (Choose service)
6. Ad slot
7. Item list
8. Nearby vendors

Guests: guest banner instead of sections 2–4, same browsing sections below.

---

## Verification (planned)

- Landing has no form; links navigate to dedicated screens.
- Login/register require terms acceptance; ads consent optional + persisted.
- Logout lands on the landing page from every role.
- Consumer settings/profile render in light/dark; toggles persist.
- Home shows cylinders above the estimator; all logic untouched.
- Analyzer 0 errors / 0 warnings; full test suite green (new tests for
  consent gating and settings widgets).

---

## Rollback

- Baseline: **`cbae13e`**. One commit per slice (auth flow, consumer
  screens, home reorder) so each can be reverted independently.
