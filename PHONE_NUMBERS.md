# GasLink Phone Number Rules

**Status:** Testing / pilot. Rules apply to every number; individual user numbers do not need per-number approval.
**Last updated:** 17 Nov 2026
**Owner:** GasLink. No fixed-role number is changed without the owner's approval.

> **Internal ops document — contains phone numbers and PII. Do not share publicly.**

---

## Rules of engagement

1. **The owner runs all tests.** The agent must not send test SMS or initiate calls. If a send is necessary, ask the owner first.
2. **App-registered numbers:** if they initiate an inbound message, the AI takes the wheel while the gateway is running. No proactive SMS.
3. **Unknown/new numbers not in the app:** paused. No opt-in SMS; log only. Revisit when GasLink has a dedicated number. The foundation and logic stay intact.
4. **Customer/vendor engagement after the app releases a number:** app-flow. The vendor publishes the number; the app gives it to the customer during ordering; the customer chooses how to engage. The SMS gateway does not mediate, monitor, or send those messages.
5. **App transactional order flow:** unchanged; hands off. The gateway sends only its designed order notifications.
6. **Carrier/alphanumeric senders:** never reply; log only.
7. **The gateway number may change.** The owner will announce it. Do not assume permanence.
8. **No silent number changes.** A number added to `GASLINK_SELF_NUMBERS`, a send path, or a fixed role must be approved by the owner. App-registered user numbers are governed by the rules above and do not need individual approval.
9. **No manual SMS** except AI-assistance replies/relay. Keep the operator relay ON.

---

## Fixed roles

| Role | Number | Rule |
|---|---|---|
| Gateway SMS line | `0776304776` (`+255776304776`) | SMS/AI gateway; self-number; AI replies; owner-announced changes; no manual test SMS. |
| Admin/support line | `0767304776` (`+255767304776`) | App support/calls and admin login; not a gateway SIM; no proactive SMS; app rules apply. |
| Operator / second SIM | `0714604777` (`+255714604777`) | Relay/internal; keep relay ON; no manual test SMS; owner runs tests. |
| Vendor (Sao Gas) | `+255777000777`; published secondary `+255777000776` | App transactional order SMS only; vendor/customer engagement app-flow; no marketing or manual SMS. |
| App-registered users | dynamic | Inbound-initiated AI only; no proactive SMS; rules above. |
| Unknown/new numbers | dynamic | Paused; log only; no opt-in SMS. |
| Carrier senders | `M-PESA`, `Vodacom`, `VodaTaarifa`, `TING`, `SONGESHA`, `LUKU` | Never reply; log only. |

---

## Current config

| Setting | Value |
|---|---|
| `GASLINK_SMS_NUMBER` / `FACADE_SMS_SENDER_PHONE` | `+255776304776` |
| `GASLINK_SELF_NUMBERS` | `+255776304776` |
| `GASLINK_OPERATOR_PHONE` | `+255714604777` |
| `GASLINK_SELF_NUMBER_RELAY` | `true` |
| `optInUnauthorized` | `false` — unknown-number opt-in paused 17 Nov 2026 |
| Admin/support line | `+255767304776` — app support/calls, not the SMS gateway |

The unknown-number opt-in pause is a config toggle. It does not remove code. Re-enable only with owner approval when a dedicated GasLink number exists.

---

## Incident log

- **17 Nov 2026 — fixed roles separated.** Gateway SMS line `0776304776`; admin/support line `0767304776`; operator/second SIM `0714604777`. The gateway config now uses the gateway line; the app’s support/call text remains the admin/support line.
- **17 Nov 2026 — `+255742946436` (George Mwaseba) removed from `GASLINK_SELF_NUMBERS`.** Consumer account, not a gateway SIM.
- **17 Nov 2026 — unknown-number opt-in paused.** `optInUnauthorized: false`; code intact.
- **16 Nov 2026 — carrier senders filtered.** `Vodacom`, `M-PESA`, `TING`, etc. no longer receive AI replies.
- **16 Nov 2026 — unknown-number opt-in SMS to `+255685882036`.** Now paused.

---

## Change procedure

1. Fixed-role numbers (gateway, operator, vendor, support) need owner approval before changing.
2. App-registered users are governed by the rules above; no individual approval is needed.
3. Never add, flag, or contact a number silently.
4. Record fixed-role changes here with the date.
