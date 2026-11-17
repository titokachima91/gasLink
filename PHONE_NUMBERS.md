# GasLink Phone Number Registry

**Status:** Testing / pilot. Every number is provisional until the owner approves a rule.
**Last updated:** 17 Nov 2026
**Owner:** GasLink. No number is used, flagged, or contacted without the owner's explicit approval.

> **Internal ops document — contains phone numbers and PII. Do not share publicly.**

---

## Owner rules — recorded 17 Nov 2026

1. **The owner runs all tests from now on.** The agent must not send test SMS or initiate calls. If a send is absolutely necessary, ask the owner first.
2. **Keep the self-number relay ON.** The relay is AI-assistance output to the operator, not a test send.
3. **The gateway number `0767304776` may change at any time.** The owner will announce the new number. Do not assume it is permanent.
4. **Numbers registered in the app are engaged when they initiate an inbound message.** The AI takes the wheel while the gateway is running (self-hosted). No proactive SMS.
5. **Unknown/new numbers not in the app are paused.** No opt-in SMS; log only. Revisit when GasLink has a dedicated number. Keep the foundation and logic intact.
6. **The app's designed transactional order flow continues unchanged.** Hands off. No manual marketing or test sends.
7. **Any number added, flagged, or contacted must be approved in this file first.** Do not silently add a number to `GASLINK_SELF_NUMBERS`, a test script, or a send path.
8. **Customer/vendor engagement after the app releases a number is app-flow, not SMS-gateway territory.** The vendor publishes the number; the app gives it to the user during ordering; the user chooses how to engage. The gateway does not mediate, monitor, or send those messages.

## Current config state

| Setting | Value |
|---|---|
| `GASLINK_SELF_NUMBERS` | `+255767304776` only (pending gateway-number confirmation) |
| `GASLINK_SELF_NUMBER_RELAY` | `true` |
| `optInUnauthorized` | `false` — unknown-number opt-in paused 17 Nov 2026 |
| Gateway number | **Pending confirmation: build uses `0767304776`; owner wrote `0776304776` on 17 Nov** |
| Gateway self-number list | Only `+255767304776`; George's number removed |
| Test sends by agent | Prohibited without owner approval |

Pausing the opt-in did **not** remove code. It is the dashboard/config toggle. Re-enable only with the owner's approval when a dedicated GasLink number exists.

## How to use this file

- **Proposed rule** is my recommendation.
- **Your rule** records the owner's decision.
- `YES` = allowed without asking each time; `NO` = never; `ASK` = ask the owner before each use; `TXN` = only transactional messages for that person's own order/account.

---

## A. Gateway and infrastructure

| # | Number | Who / what | Source | Proposed rule | Your rule |
|---|---|---|---|---|---|
| A1 | `+255767304776` / `0767304776` | Gateway public line (YAS SIM in Samsung SM-A075F); admin phone; public support number shown in the app | `.env` `GASLINK_SMS_NUMBER`, `FACADE_SMS_SENDER_PHONE`; `lib/services/auth_service.dart` `adminPhone`; `lib/core/constants.dart` `supportPhone`; support text in several screens | Gateway SIM. Self-number. Never a consumer. Inbound support replies allowed; outbound only transactional/OTP/replies. | **Current gateway line; may change anytime — owner will announce. Self-number. AI-assistance replies allowed. No time limits; availability is subject to app rules, AI/SMS gateway configuration, and self-hosted server/quota. Agent must not send test SMS; ask first.** |
| A2 | Vodacom SIM in the gateway handset | Second SIM in the Samsung SM-A075F; number **not verified** | TextBee `simInfo` shows a Vodacom SIM, but no number | Verify on the handset (**Settings → About phone → Status → SIM status**) before adding. Do not assume it is `0742946436` or any customer number. | **Pending: read the SIM's own number on the handset. Do not guess or use a consumer number. If `0776304776` is the second/Vodacom SIM, confirm it before adding.** |

**Gateway number pending confirmation (17 Nov 2026):** the owner's latest message wrote
`0776304776`, while the build, `.env`, app support text, and logs use
`0767304776`. These differ by one digit. **No change has been made.** Confirm
which is the public gateway line, and whether the other is the second SIM or a
typo.

**Important:** A1 and A2 are the only gateway SIMs. `0742946436` is **not** a gateway number; it is George's consumer number (see E1).

---

## B. Operator / internal

| # | Number | Who / what | Source | Proposed rule | Your rule |
|---|---|---|---|---|---|
| B1 | `+255714604777` / `0714604777` | Operator phone; receives operator relay and progress messages | `.env` `GASLINK_OPERATOR_PHONE`; `scripts/send-operator-sms.js`; `routes/inbound-sms.js`; `services/textbee-inbound-poller.js` | Internal ops. TXN/testing only. No marketing. Confirm whether the self-number relay should stay enabled. | **Keep relay ON. Operator/internal. AI-assistance relay only; no manual test SMS. Agent asks before any send.** |

---

## C. Vendor

| # | Number | Who / what | Source | Proposed rule | Your rule |
|---|---|---|---|---|---|
| C1 | `+255777000777` | Sao Gas Supply pilot vendor phone; vendor app login and order SMS | Firestore `vendors` (Sao Gas Supply) and `users`; RUNBOOK §8 | TXN order notifications only. Vendor must opt in. App acceptance preferred. No marketing. | **App's transactional order SMS only; hands off. The vendor number is published/released through the app flow after confirmation; the customer chooses how to engage. Not SMS-gateway territory. No marketing or manual SMS.** |
| C2 | `+255777000776` | Sao Gas Supply secondary/WhatsApp number | Firestore `vendors.secondaryPhone` | Not used for automated SMS. Manual WhatsApp only, if the vendor agrees. | **Vendor-published secondary/WhatsApp number; app-flow only. The user chooses how to engage. Not an SMS-gateway number; no gateway sends. Resolved — not gateway territory.** |

---

## D. Test fixtures and seeded accounts

Some are fixtures and some are real. The status column records the evidence; confirm the uncertain ones.

| # | Number | Who / what | Source | Status | Proposed rule | Your rule |
|---|---|---|---|---|---|---|
| D1 | `+255700000123` | "Test Mteja" mock consumer | Firestore `users`; mock order tests; `sms-log.json` | **Fixture** (mock order) | Fixture only. Never call. SMS only in mock tests. | **Fixture. Never contact.** |
| D2 | `+255767304776` | A duplicate "Test Mteja" user doc using the gateway number | Firestore `users` | **Not a customer** (gateway number) | Clean up the duplicate/seed account when safe. | **Gateway number, not a customer. Clean up duplicate seed when safe.** |
| D3 | `+255777000778` | Seeded consumer test account and duplicate Firestore user | `lib/main.dart` `seedUser`; Firestore `users` | **Fixture** (seeded in code) | Fixture only. No real SMS. | **Fixture. Never contact.** |
| D4 | `+255777000779` | Test consumer account | Firestore `users` | **Likely fixture** | Fixture only. No real SMS. | **Likely fixture. Confirm if real; no contact until confirmed.** |
| D5 | `+255700000001` | Simulated blocked/unauthorized test number | `sms-log.json` simulate entries | **Fixture** (simulated) | Fixture only. Never contact. | **Fixture. Never contact.** |

---

## E. Real testers and consumers (inbound-initiated only)

| # | Number | Who / what | Source | Proposed rule | Your rule |
|---|---|---|---|---|---|
| E1 | `+255742946436` / `0742946436` | **George Mwaseba**, consumer; registered 16 Nov 2026; AI assistant enabled; uses his own phone | Firestore `users` doc `5sCsY1XFT71zxcSgjcS4` | Real consumer. **Not a gateway SIM.** No proactive SMS. Reply only to his own inbound. | **If he initiates AI assistance, AI responds while servers are on. No proactive SMS. Owner runs tests; agent asks before any send.** |
| E2 | `+255745123046` | Real tester who texted gas questions on 14 Nov; consumer account with AI enabled | Firestore `users`; `sms-log.json` | Real person. TXN replies only. No proactive SMS or marketing. | **Inbound-initiated AI only. No proactive SMS. Owner runs tests.** |
| E3 | `+255685882036` | Real inbound on 16 Nov; unregistered AI user; received one opt-in SMS | `sms-log.json` | Real person. Do not send again unless they opt in. | **Real but not in the app. New/unknown → paused. Log only; no SMS. If he registers in the app, engage on inbound.** |
| E4 | `+255716546732` / `0716546732` | **Real user**, confirmed by the owner on 17 Nov 2026; consumer account with AI enabled; one order | Firestore `users`; one order; `sms-log.json` | Real user. Inbound-initiated AI only. No proactive SMS. | **Real user — treat as such. If they initiate AI assistance, AI responds while servers are on; no proactive SMS; owner runs tests.** |

---

## F. Carrier and alphanumeric senders — never reply

| Sender | What it is | Rule |
|---|---|---|
| `M-PESA` | Mobile-money notifications | Never send. Log only. |
| `Vodacom` | Carrier notifications | Never send. Log only. |
| `VodaTaarifa` | Carrier notifications | Never send. Log only. |
| `TING` | Vodacom marketing | Never send. Log only. |
| `SONGESHA` | Loan/airtime notifications | Never send. Log only. |
| `LUKU` | Electricity tokens | Never send. Log only. |

The poller must ignore non-phone senders. This was fixed on 16 Nov 2026; do not regress it.

---

## G. Dynamic order numbers

These are not fixed contacts; they come from orders. The app's designed lifecycle is hands-off.

| Type | Source | Rule |
|---|---|---|
| Order contact / receiver phone | `orders.contact_phone`, `orders.receiver_phone` | Use only for that order's lifecycle. No marketing. No calls/SMS outside the order. Test/mock numbers (e.g. `0777…`, `0788…`) are historical fixtures; never contact them. |
| Driver / rider phone | `orders.driverPhone`, `orders.riderPhone` | Release only after dispatch, per the order lifecycle. Never before. No marketing. The customer receives the number only at the approved step. |
| Vendor phone | `orders.vendorPhone` / vendor profile | The app releases the vendor number to the customer after vendor confirmation; the customer chooses how to engage. Not SMS-gateway territory. No marketing or gateway mediation. |

---

## H. Pending decisions for the owner

Answered:

- [x] **A1:** Gateway line is `0767304776`; may change anytime; owner will announce.
- [x] **B1:** Keep the self-number relay ON; AI-assistance only; no manual test SMS.
- [x] **E1:** If George initiates AI assistance, AI responds while servers are on; no proactive SMS.
- [x] **E2/E3:** Inbound-initiated AI only; unknown/not-in-app numbers paused.
- [x] **Unknown inbound:** Opt-in SMS paused; log only; keep foundation and logic intact.
- [x] **Test sends:** Owner runs all tests; agent asks before any send.
- [x] **C2:** App-flow only; the vendor publishes the number and the customer chooses how to engage. Not SMS-gateway territory.
- [x] **A1 support hours:** No time limits; availability is subject to app rules, AI/SMS gateway configuration, and self-hosted server/quota.
- [x] **D2 (old `+255716546732`):** Real user, confirmed by the owner; treat as real and inbound-initiated only.

Still open:

- [ ] **Gateway number:** Confirm whether the public gateway line is `0767304776` (current build) or `0776304776` (owner's 17 Nov message), and what the other number is.
- [ ] **A2:** What is the gateway Vodacom SIM's own number? Read it on the handset; do not guess.
- [ ] **D4:** Is `+255777000779` a fixture or a real person? Confirm so the registry is exact.
- [ ] **Dedicated GasLink number:** Revisit unknown-number engagement when the owner gets a separate GasLink number.

---

## I. Incident log

- **17 Nov 2026 — consumer number wrongly flagged as a gateway SIM.** `+255742946436` (George Mwaseba) was added to `GASLINK_SELF_NUMBERS` at 08:39 EAT because a Vodacom bundle SMS was misread as proof that the SIM was in the gateway handset. The number belongs to George's own phone. It was removed the same day. No SMS was sent to him by the guard; the flag only suppressed replies. Docs corrected; this registry created.
- **17 Nov 2026 — unknown-number opt-in paused.** `optInUnauthorized` set to `false` via the dashboard config. No code removed; re-enable only with owner approval when GasLink has a dedicated number.
- **16 Nov 2026 — carrier senders treated as customers.** `Vodacom`, `M-PESA`, `TING`, etc. were parsed as phone numbers and received failed AI replies. Fixed by ignoring non-phone senders.
- **17 Nov 2026 — gateway-number clarification pending.** Owner wrote `0776304776`; the build, `.env`, app support text, and logs use `0767304776`. The numbers differ by one digit. No change made; the public line and the second SIM must be confirmed.
- **17 Nov 2026 — `+255716546732` confirmed real user.** Reclassified from fixture to E4; inbound-initiated AI only, no proactive SMS.
- **17 Nov 2026 — support line has no time limits.** Availability follows app rules, AI/SMS gateway configuration, and self-hosted server/quota.
- **17 Nov 2026 — customer/vendor engagement boundary clarified.** Vendor numbers are published by the vendor and released by the app during ordering; the customer chooses how to engage. The SMS gateway does not mediate calls/WhatsApp or send manual follow-ups.
- **16 Nov 2026 — unknown number opt-in SMS.** `+255685882036` received an opt-in SMS. Now paused (see above).

---

## J. Change procedure

1. Propose the number and the rule in this file.
2. Get the owner's explicit approval.
3. Only then add it to `.env`, code, a test script, or a send path.
4. Record the date and the approved rule.
5. Never add, flag, or contact a number silently.
