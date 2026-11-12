# Phase 05D — Vendor Polish & Growth Hooks (Referral + GasPlan Teaser)

> **Status:** ✅ Complete — see `implementation.md` for commits and verification.
> **Branch:** `harden-source-of-truth`
> **Rollback baseline:** `cbae13e` + Phase 5C (`f536788`)
> **Phase 6 (security hardening):** set aside.

---

## D. Vendor-side polish (restyle only, logic untouched)

1. **Vendor drawer** — logo avatar (uses the same asset), verified chip next
   to the tier badge, icon tiles instead of emoji, cleaner dividers.
2. **Inventory screen** — cards restyled with the design kit: icon tile,
   brand/size title, `AppStatusPill` price and stock pills, switch + delete
   kept. Merged-catalogue logic untouched.
3. **Order manager** — status pills already exist; polish card paddings,
   section headers per tab, and the action buttons row.
4. **Vendor profile** — replace plain "Section A…" labels with
   `AppSectionHeader`s; same form fields, validations, and photo upload.
5. **Badge screen** — add a **"Umethibitishwa / Verified"** chip when
   `verified == true` (mirrors what consumers see).
6. **Vendor dashboard extras** —
   - **Verification status card:** if verified → proud chip; if not →
     "Pata Badge ya Uhakiki" CTA → badge/profile screen.
   - **Referral card** (see E2).

## E1. GasPlan kwa Waajiriwa — teaser (coming soon, foundation only)

**Concept:** employees (government/private sector) subscribe to a guaranteed
monthly gas plan (e.g. 2 cylinders/month); payment is settled end-of-month via
payslip deduction arranged with their employer's HR. Zero cash friction.

**Placement decision (professional, discreet):**

- **Lives inside Consumer Settings only** — a "Vipengele / Features" section
  with a **"GasPlan kwa Waajiriwa — Inakuja hivi karibuni"** row.
- **Not advertised on the landing page, consumer home, or anywhere public**
  until the service materializes. This keeps the promise credible and avoids
  promising a product that does not exist yet.

**What we build now — no billing logic:**

- **GasPlanScreen** ("GasPlan kwa Waajiriwa / Coming Soon"):
  - Pitch hero: "Gesi ya uhakika kila mwezi. Malipo kupitia payslip."
  - 3 steps: (1) Mwajiri anasaini makubaliano → (2) Mfanyakazi anachagua
    mpango → (3) Gesi inawasili kila mwezi.
  - Benefit chips: guaranteed supply · payslip deduction · no cash.
  - **CTA: "Ongea nasi / Register interest"** → mini form (name, phone,
    employer) → writes to `ajira_interest` collection (no auth required).
  - **"Share with your HR"** button (share_plus) — the discreet viral hook,
    inside the screen only.
- Entry point (single): Consumer Settings → Features → GasPlan row.

## E2. Referral foundation (consumer + vendor, rewards coming soon)

**Data foundation (no payout logic):**

- `users/{uid}.referralCode` and `vendors/{id}.referralCode` — short code
  generated from the uid (6 chars, readable, no ambiguous letters).
- `referrals/{id}` — `{referrerUid, referrerRole, refereeRole,
  refereePhone?, status: invited|joined, createdAt}`.

**Surfaces:**

1. **Consumer home** — "Alika & Pata Zawadi / Invite & Earn (coming soon)"
   card: own code, copy button, share button (share_plus).
2. **Consumer → Vendor referral (intuitive per your note)** — card on
   consumer home/settings: **"Unamjua muuzaji wa gesi? Mlete kwenye GasLink"**
   → share link + optional mini-form (shop name/phone) → writes a
   `referrals` doc with `refereeRole: vendor`.
3. **Vendor dashboard** — "Alika wauzaji wenzako" card: own code + invited
   count (stream of `referrals` where referrer = me).
4. **Vendor settings** — Referral section: code, share, invited count.
5. Rewards text everywhere says **"Zawadi zinakuja hivi karibuni"** — no
   amounts, no balances; this is a foundation to invite talks and spread.

**Dependency:** `share_plus` (planned) for share sheets.

---

## Verification (planned)

- All new screens render in light/dark; guest gating respected.
- Referral code generation is pure and tested; interest/referral writes are
  valid Firestore docs.
- No existing logic touched (order flows, FIFO/gauges, auth).
- Analyzer 0 errors / 0 warnings; full test suite green.

---

## Rollback

- Baseline: `cbae13e`. One commit per slice (vendor polish, GasPlan teaser,
  referral) for independent reverts.
