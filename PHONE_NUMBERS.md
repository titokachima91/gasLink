# GasLink Phone Number Rules

**Status:** Testing / pilot. Rules apply to every number; individual user numbers do not need per-number approval.
**Last updated:** 18 Nov 2026
**Owner:** GasLink. No fixed-role number is changed without the owner's approval.

> **Internal ops document — contains phone numbers and PII. Do not share publicly.**

---

## Rules of engagement

1. **The owner runs all tests.** The agent must not send test SMS or initiate calls. If a send is necessary, ask the owner first.
2. **One number, multiple roles.** `0767304776` is the TextBee phone, the gateway, the admin line and the support line. It is the same number everywhere. Do not split it into different numbers or infer a different number from a role name.
3. **The self-number rule is physical.** If a number is in the phone that has TextBee installed, that number is the gateway number and is a self-number. No number is blocked by bias, and there is no intentional consumer block list.
4. **App-registered numbers:** if they initiate an inbound message, the AI and SMS order flow may respond while the gateway is running. No proactive SMS.
5. **Unknown/new numbers not in the app:** paused. No AI reply, no SMS order reply, no opt-in SMS; log only. Revisit when GasLink has a dedicated number.
6. **Customer/vendor engagement after the app releases a number:** app-flow. The vendor publishes the number; the app gives it to the customer during ordering; the customer chooses how to engage. The SMS gateway does not mediate, monitor, or send those messages.
7. **App transactional order flow:** unchanged; hands off. The gateway sends only its designed order notifications.
8. **Carrier/alphanumeric senders:** never reply; log only.
9. **No silent number changes.** A fixed-role number added to `GASLINK_SELF_NUMBERS` or a send path must be approved by the owner. App-registered user numbers are governed by the rules above.
10. **No manual SMS** except AI-assistance replies/relay. Keep the operator relay ON.

---

## Fixed roles

| Role | Number | Rule |
|---|---|---|
| TextBee phone / gateway / admin / support | `0767304776` (`+255767304776`) | One number, all four roles. Self-number because it is the number in the TextBee phone. AI replies; admin/support; no manual test SMS. |
| Operator / second SIM | `0714604777` (`+255714604777`) | Relay/internal; keep relay ON; no manual test SMS; owner runs tests. |
| Vendor (Sao Gas) | `+255777000777`; published secondary `+255777000776` | App transactional order SMS only; vendor/customer engagement app-flow; no marketing or manual SMS. |
| App-registered users | dynamic | Inbound-initiated AI and SMS order flow only; no proactive SMS; rules above. |
| Unknown/new numbers | dynamic | Paused; no AI, no SMS order reply, no opt-in SMS; log only. |
| Carrier senders | `M-PESA`, `Vodacom`, `VodaTaarifa`, `TING`, `SONGESHA`, `LUKU` | Never reply; log only. |

---

## Current config

| Setting | Value |
|---|---|
| `GASLINK_SMS_NUMBER` | `+255767304776` |
| `FACADE_SMS_SENDER_PHONE` | `+255767304776` |
| `GASLINK_SELF_NUMBERS` | `+255767304776` |
| `GASLINK_OPERATOR_PHONE` | `+255714604777` |
| `GASLINK_SELF_NUMBER_RELAY` | `true` |
| `optInUnauthorized` | `false` — unknown-number opt-in paused |

The unknown-number pause is a config toggle. It does not remove code. Re-enable only with owner approval when a dedicated GasLink number exists.

---

## Incident log

- **18 Nov 2026 — one-digit gateway-number typo removed.** The real TextBee/gateway/admin/support number is `0767304776`. One number, multiple roles; no bias and no intentional consumer block list.
- **17 Nov 2026 — subscriber gate moved before the SMS order flow.** Unregistered numbers no longer receive an AI reply or an SMS order reply. Registered vendors with AI chat disabled can still accept/decline orders by SMS.
- **17 Nov 2026 — `+255742946436` (George Mwaseba) removed from `GASLINK_SELF_NUMBERS`.** Consumer account, not the TextBee phone.
- **17 Nov 2026 — unknown-number opt-in paused.** `optInUnauthorized: false`; code intact.
- **16 Nov 2026 — carrier senders filtered.** `Vodacom`, `M-PESA`, `TING`, etc. no longer receive AI replies.

---

## Change procedure

1. Fixed-role numbers (the TextBee/gateway/admin/support number and the operator number) need owner approval before changing.
2. App-registered users are governed by the rules above; no individual approval is needed.
3. Never add, flag, or contact a number silently.
4. Record fixed-role changes here with the date.
