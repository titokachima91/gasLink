# GasLink Phone Number Registry

**Status:** Testing / pilot. Every number is provisional until the owner approves a rule.
**Last updated:** 17 Nov 2026
**Owner:** GasLink. No number is used, flagged, or contacted without the owner's explicit approval.

> **Internal ops document — contains phone numbers and PII. Do not share publicly.**

---

## The rule

1. Every phone number the system may send to, receive from, call, or flag as a gateway SIM must be listed here.
2. A number may be added to `.env` (`GASLINK_SELF_NUMBERS`, `GASLINK_OPERATOR_PHONE`, etc.), a test script, or any send path only after the owner approves it in this file.
3. No cold marketing. Transactional messages only, and only to the number that owns the transaction.
4. The TextBee plan has **50 messages/day shared by inbound and outbound**. Every send counts.
5. If a new number is needed, propose it here first; do not silently use it.

## How to use this file

- **Proposed rule** is my recommendation.
- **Your rule** is blank. Fill it in or tell me in chat; I will update this file.
- `YES` = allowed without asking each time; `NO` = never; `ASK` = ask the owner before each use; `TXN` = only transactional messages for that person's own order/account.

---

## A. Gateway and infrastructure

| # | Number | Who / what | Source | Proposed rule | Your rule |
|---|---|---|---|---|---|
| A1 | `+255767304776` / `0767304776` | Gateway public line (YAS SIM in Samsung SM-A075F); admin phone; public support number shown in the app | `.env` `GASLINK_SMS_NUMBER`, `FACADE_SMS_SENDER_PHONE`; `lib/services/auth_service.dart` `adminPhone`; `lib/core/constants.dart` `supportPhone`; support text in several screens | Gateway SIM. Self-number. Never a consumer. Inbound support replies allowed; outbound only transactional/OTP/replies. Customers may call/text for support. | |
| A2 | Vodacom SIM in the gateway handset | Second SIM in the Samsung SM-A075F; number **not verified** | TextBee `simInfo` shows a Vodacom SIM, but no number | Verify on the handset (**Settings → About phone → Status → SIM status**) before adding. Do not assume it is `0742946436` or any customer number. | |

**Important:** A1 and A2 are the only gateway SIMs. `0742946436` is **not** a gateway number; it is George's consumer number (see E1).

---

## B. Operator / internal

| # | Number | Who / what | Source | Proposed rule | Your rule |
|---|---|---|---|---|---|
| B1 | `+255714604777` / `0714604777` | Operator phone; receives operator relay and progress messages | `.env` `GASLINK_OPERATOR_PHONE`; `scripts/send-operator-sms.js`; `routes/inbound-sms.js`; `services/textbee-inbound-poller.js` | Internal ops. TXN/testing only. No marketing. Confirm whether the self-number relay should stay enabled. | |

---

## C. Vendor

| # | Number | Who / what | Source | Proposed rule | Your rule |
|---|---|---|---|---|---|
| C1 | `+255777000777` | Sao Gas Supply pilot vendor phone; vendor app login and order SMS | Firestore `vendors` (Sao Gas Supply) and `users`; RUNBOOK §8 | TXN order notifications only. Vendor must opt in. App acceptance preferred. No marketing. | |
| C2 | `+255777000776` | Sao Gas Supply secondary/WhatsApp number | Firestore `vendors.secondaryPhone` | Not used for automated SMS. Manual WhatsApp only, if the vendor agrees. | |

---

## D. Test fixtures and seeded accounts

| # | Number | Who / what | Source | Proposed rule | Your rule |
|---|---|---|---|---|---|
| D1 | `+255700000123` | "Test Mteja" mock consumer | Firestore `users`; mock order tests; `sms-log.json` | Fixture only. Never call. SMS only in mock tests. | |
| D2 | `+255716546732` | Simulated test consumer | Firestore `users`; one test order; `sms-log.json` | Fixture only. No real SMS without approval. | |
| D3 | `+255767304776` | A duplicate "Test Mteja" user doc using the gateway number | Firestore `users` | This is the gateway (A1), not a customer. Clean up the duplicate/seed account when safe. | |
| D4 | `+255777000778` | Seeded consumer test account and duplicate Firestore user | `lib/main.dart` `seedUser`; Firestore `users` | Fixture only. No real SMS. | |
| D5 | `+255777000779` | Test consumer account | Firestore `users` | Fixture only. No real SMS. | |
| D6 | `+255700000001` | Simulated blocked/unauthorized test number | `sms-log.json` simulate entries | Fixture only. Never contact. | |

---

## E. Real testers and consumers (consent required)

| # | Number | Who / what | Source | Proposed rule | Your rule |
|---|---|---|---|---|---|
| E1 | `+255742946436` / `0742946436` | **George Mwaseba**, consumer; registered 16 Nov 2026; AI assistant enabled; uses his own phone | Firestore `users` doc `5sCsY1XFT71zxcSgjcS4` | Real consumer. **Not a gateway SIM.** No proactive SMS. Reply only to his own inbound. May be used for testing only if he agrees. The self-number flag was removed on 17 Nov. | |
| E2 | `+255745123046` | Real tester who texted gas questions on 14 Nov; consumer account with AI enabled | Firestore `users`; `sms-log.json` | Real person. TXN replies only. No proactive SMS or marketing. Confirm consent. | |
| E3 | `+255685882036` | Real inbound on 16 Nov; unregistered AI user; received one opt-in SMS | `sms-log.json` | Real person. Do not send again unless they opt in. Confirm whether the opt-in SMS was acceptable. | |

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

These are not fixed contacts; they come from orders.

| Type | Source | Rule |
|---|---|---|
| Order contact / receiver phone | `orders.contact_phone`, `orders.receiver_phone` | Use only for that order's lifecycle. No marketing. No calls/SMS outside the order. Test/mock numbers (e.g. `0777…`, `0788…`) are historical fixtures; never contact them. |
| Driver / rider phone | `orders.driverPhone`, `orders.riderPhone` | Release only after dispatch, per the order lifecycle. Never before. No marketing. The customer receives the number only at the approved step. |
| Vendor phone | `orders.vendorPhone` / vendor profile | Release to the customer only after vendor confirmation, per the business rules. No marketing. |

---

## H. Pending decisions for the owner

Please fill in or tell me:

- [ ] **A2:** What is the gateway Vodacom SIM's own number? (Read it on the handset; do not guess.)
- [ ] **B1:** Should the self-number relay (`GASLINK_SELF_NUMBER_RELAY=true`) stay on? It sends suppressed replies to the operator phone, which costs quota.
- [ ] **E1:** Can George be used for further testing? If yes, is it SMS, app, or both?
- [ ] **E2/E3:** May we reply to these real testers? Do they consent to future test messages?
- [ ] **Unknown inbound:** The gateway currently sends a keyword-filtered opt-in SMS to unknown numbers. During testing, should it (a) keep doing that, (b) only log unknown numbers, or (c) reply only to an allowlist?
- [ ] **C2:** May we use the vendor's WhatsApp number manually?
- [ ] **D1–D6:** Confirm these are fixtures only and never real people.
- [ ] **A1:** May customers call/text `0767304776` for support during testing? Any hours/limits?

---

## I. Incident log

- **17 Nov 2026 — consumer number wrongly flagged as a gateway SIM.** `+255742946436` (George Mwaseba) was added to `GASLINK_SELF_NUMBERS` at 08:39 EAT because a Vodacom bundle SMS was misread as proof that the SIM was in the gateway handset. The number belongs to George's own phone. It was removed the same day. No SMS was sent to him by the guard; the flag only suppressed replies. Docs corrected; this registry created.
- **16 Nov 2026 — carrier senders treated as customers.** `Vodacom`, `M-PESA`, `TING`, etc. were parsed as phone numbers and received failed AI replies. Fixed by ignoring non-phone senders.
- **16 Nov 2026 — unknown number opt-in SMS.** `+255685882036` received an opt-in SMS. Rule pending (see H).

---

## J. Change procedure

1. Propose the number and the rule in this file.
2. Get the owner's explicit approval.
3. Only then add it to `.env`, code, a test script, or a send path.
4. Record the date and the approved rule.
5. Never add, flag, or contact a number silently.
