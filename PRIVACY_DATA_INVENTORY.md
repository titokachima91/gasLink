# GasLink — Privacy & Data-Collection Inventory

**Version:** 1.0 (pilot build)
**Date:** 17 November 2026
**Prepared for:** GasLink founder / legal counsel
**Scope:** The Android consumer/vendor/admin app (`gaslink_app`), the Firestore project `gaslink-app-4bfbb`, the self-hosted SMS/AI gateway on the operator Mac, and the third-party services those components call.
**Status:** Internal audit. This is an engineering inventory, not legal advice. Every item marked **VERIFY** should be confirmed before the privacy policy is published.

---

## 0. One-page summary

### 0.1 Direct answer: do we know the customer's phone model?

**No — the GasLink customer app does not read the phone's hardware or OS identifiers, and it does not read the customer's phone number from the SIM. It has no access to IMEI, serial number, contacts, SMS inbox, call log, camera, or microphone. The phone number a customer types at registration is stored and used as their account ID — that is user-entered data, not device data.**

The `samsung SM-A075F` / Android 17 / SIM / battery / storage information you saw is reported by **TextBee about the gateway phone** (the Samsung handset holding the GasLink SIMs). It is device telemetry for the SMS gateway, not for the customer.

However, three nuances matter for the privacy policy:

1. **The build declares location permissions it does not use.** `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` are in the release APK even though no screen requests or reads location. A privacy policy must not claim "we collect location" if we don't, but a security reviewer will see the permission and ask why. Remove them (recommended) or disclose them accurately.
2. **Firebase/Google SDKs can see device and app metadata.** The app does not call a device-info API, but Google Play services and Firebase requests can include device model, OS version, app version, language, IP address, and installation identifiers as part of normal service telemetry. Your policy should say service providers may process device and technical data.
3. **Photos are user-selected, not automatic.** A vendor can pick one shop photo from the gallery. The app cannot browse the gallery on its own. If that photo contains EXIF GPS data, it may be uploaded unless the picker re-encodes it (see risk #17 in §11).

### 0.1.1 Evidence: the model in TextBee is the gateway phone, not the sender

This matters because the `SM-A075F` model appears in the TextBee message object and can easily be mistaken for the sender's phone. It is not.

A live received-message object from TextBee has these top-level keys:

```
__v, _id, createdAt, device, direction, encrypted, message, receivedAt,
sender, status, type, updatedAt, user
```

The `device` field is:

```json
{
  "_id": "6af53d075f4bc89110d82065",
  "enabled": true,
  "brand": "samsung",
  "model": "SM-A075F",
  "name": "samsung SM-A075F",
  "buildId": "CP2A.260605.016"
}
```

That is the **receiving gateway handset** — the phone running the TextBee app and holding the GasLink SIMs. It is the same device shown in the TextBee device list. The message's `direction` is `received`, so `device` describes where the message arrived, not where it came from.

The gateway code never reads `msg.device` or any model field. `services/textbee-inbound-poller.js` reads only:

- `msg._id`
- `msg.sender`
- `msg.message`
- `msg.receivedAt`

SMS itself does not carry the sender's phone model, IMEI, OS, or serial number. The SMS PDU carries the sender's number (or an alphanumeric sender ID), the SMSC timestamp, and the message text. A phone model can only be known if the sender's own app or SDK reports it — for example, an app with a device-info API, or RCS/IMS metadata. The GasLink app has no device-info package and no `READ_PHONE_STATE` permission, so it does not report it either.

**What happened with `0742946436`:** that number is `+255742946436`, a **consumer** account (George Mwaseba), not a gateway SIM. It was wrongly added to `GASLINK_SELF_NUMBERS` on **17 Nov 2026 at 08:39 EAT** after a Vodacom bundle SMS was misread as proof that the SIM was inside the gateway handset. The entry was removed on 17 Nov 2026 after the owner confirmed the number belongs to the consumer's own phone. The self-number guard was configured about 20 hours *after* the 16 Nov test, so it cannot have blocked that test. `data/sms-log.json` and TextBee's full message history contain no inbound message from `+255742946436`; the only mention is the Vodacom carrier SMS confirming a bundle on that number, received by the gateway handset. The 16 Nov message therefore never reached TextBee; the cause is still under investigation (possible self-send, wrong destination, or receiving-SIM issue). In no case did the system see or use a phone model. See `PHONE_NUMBERS.md` for the approved-number registry.

A message from a different phone got a response because it came from a **different number** that was not in the self-number list. The model was irrelevant.

### 0.2 The five findings that should block launch

| # | Finding | Why it matters |
|---|---|---|
| 1 | **No Firestore security rules are deployed — CONFIRMED OPEN.** `firestore.rules` does not exist and `firebase.json` has no Firestore section. A live unauthenticated REST read with the app's embedded API key returned HTTP 200 and real `users` documents containing `phone`, `passcodeHash`, `role`, `pinAttempts`, and lockout fields. | Anyone with the project API key (which ships inside every APK) can read the entire database: users, phones, addresses, orders, PIN hashes, vendor KYC links. Write access is very likely open too if the database is in test mode; treat it as fully compromised until rules are deployed. |
| 2 | **Firebase Storage is public-read and anonymously writable.** | Anyone can read every vendor image and any authenticated (including anonymous) user can write to any `vendorId` path. |
| 3 | **Hardcoded admin: phone `+255767304776` (the public support number) + PIN `0000`.** The PIN is also stored in plaintext in SharedPreferences. | A predictable admin credential on a publicly known number. This is a full-console compromise. |
| 4 | **No account deletion, data export, or consent-versioning flow.** | Google Play requires an in-app and web deletion path for apps with accounts. Tanzania's PDPA gives data subjects access/correction/deletion rights. |
| 5 | **SMS/AI logs on the Mac contain phone numbers, names, addresses, and message text with no retention limit or encryption guarantee.** | The gateway is the most PII-dense store in the system and currently the least governed. |

---

## 1. How to read this document

- **Verified** = checked directly in source, the release APK, the merged manifest, or live service output.
- **VERIFY** = plausible but not confirmed; confirm in the Firebase console, the provider dashboard, or with counsel.
- **Capability** = the build *can* do it, even if no current screen uses it. A privacy policy should cover capabilities, not only current UI paths, because a future update can activate them without a new permission prompt.

The inventory is deliberately broader than the current pilot UI. The goal is "no surprises at launch."

---

## 2. Device capabilities and permissions

### 2.1 Permissions actually present in the release APK

Verified with `aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk` and the merged release manifest.

| Permission | Declared by | Used by the app? | What it allows | Policy treatment |
|---|---|---|---|---|
| `android.permission.INTERNET` | App | Yes | Network access to Firebase and the SMS gateway | Disclose network/online operation |
| `android.permission.ACCESS_NETWORK_STATE` | Firebase/Connectivity plugin | Yes (`connectivity_plus` offline banner) | Know whether Wi-Fi/mobile data is available | Technical/network data |
| `android.permission.ACCESS_FINE_LOCATION` | App manifest | **No** | Precise GPS location | **Remove or disclose.** Currently unused. |
| `android.permission.ACCESS_COARSE_LOCATION` | App manifest | **No** | Approximate location | **Remove or disclose.** Currently unused. |
| `android.permission.POST_NOTIFICATIONS` | App | Yes | Show order notifications (Android 13+) | Disclose push notifications |
| `android.permission.VIBRATE` | App | Yes (notification channel) | Vibrate on notification | Minor; mention notifications |
| `android.permission.RECEIVE_BOOT_COMPLETED` | App | Plugin capability | Re-register notifications after reboot | Technical |
| `android.permission.WAKE_LOCK` | Firebase Messaging | Yes | Wake device to deliver push | Technical |
| `com.google.android.c2dm.permission.RECEIVE` | Firebase Messaging | Yes | Receive Firebase Cloud Messaging | Disclose Google/FCM |
| `com.google.android.providers.gsf.permission.READ_GSERVICES` | Google Play services | Yes | Read Google services framework state | Disclose Google Play services |
| `com.example.gaslink_app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX | Yes | Internal broadcast security | Not user-facing |

### 2.2 Permissions and capabilities the build does **not** have

Verified absent from the release APK:

- `READ_CONTACTS` / `WRITE_CONTACTS` — no contact access.
- `READ_SMS` / `RECEIVE_SMS` / `SEND_SMS` — the app cannot read or send SMS. SMS is handled by the gateway phone, not the customer app.
- `READ_CALL_LOG` / `WRITE_CALL_LOG` — no call-log access.
- `READ_PHONE_STATE` — no IMEI, subscriber ID, or call state.
- `READ_PHONE_NUMBERS` — the app does not read the SIM phone number.
- `CAMERA` — no camera access. `image_picker` is configured for `ImageSource.gallery` only.
- `RECORD_AUDIO` — no microphone access.
- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES` / `MANAGE_EXTERNAL_STORAGE` — no broad storage access. The Android photo picker returns only the one image the user selects.
- `ACCESS_BACKGROUND_LOCATION` — no background location.
- `BODY_SENSORS`, `ACTIVITY_RECOGNITION`, Bluetooth, NFC — none.
- No `device_info_plus`, `telephony`, `contacts`, `permission_handler`, `geolocator`, analytics, crash-reporting, or mobile-ad SDK in `pubspec.yaml`.

### 2.3 Device-data matrix (direct answer)

| Data from the phone | Customer app | Gateway phone (TextBee) | Notes |
|---|---|---|---|
| Phone model / manufacturer | **No** | **Yes** (`SM-A075F`) | App never calls a device-info API |
| Android / OS version | **No** | **Yes** | Provider telemetry |
| IMEI / MEID / serial | **No** | **No** | No `READ_PHONE_STATE` |
| SIM carrier / SIM state | **No** | **Yes** | Gateway device telemetry |
| SIM phone number | **No** | **No** (the number is configured, not read) | No `READ_PHONE_NUMBERS` |
| Contacts | **No** | **No** | No contacts permission |
| SMS inbox | **No** | **Yes** (the gateway's own SMS) | App has no SMS permission |
| Call log | **No** | **No** | No call-log permission |
| Camera | **No** | **No** | Gallery picker only |
| Microphone | **No** | **No** | No audio permission |
| Photos | **Only the one vendor selects** | **No** | Shop image upload |
| Precise GPS | **No** | **No** | Permission declared but unused |
| Approximate location | **No** (app) | **Provider may infer from IP** | Disclose provider metadata |
| Network type / online state | **Yes** | **Yes** | `connectivity_plus` |
| Installed apps | **No** | **No** | No package visibility beyond Android defaults |
| Advertising ID | **No** | **No** | No ad SDK |
| FCM token | **Yes** | **Yes** | Push routing identifier |
| App version / language / theme | **Yes** | **Yes** | App metadata |
| Battery / storage / signal | **No** | **Yes** | Gateway device telemetry |

### 2.4 Identifiers the app does handle

| Identifier | Where it comes from | Purpose | Notes |
|---|---|---|---|
| **Phone number** | Typed by the user at registration/login, checkout, vendor profile, referral, GasPlan form | Account identity, contact, delivery | This is the primary user identifier. It is not read from the SIM. |
| **Firestore user document ID** | Generated by Firestore on registration | Account key | Random document ID, not a hardware ID. |
| **FCM registration token** | Firebase Cloud Messaging | Route push notifications to the device | Stored in `users/{uid}.fcmToken`; changes on reinstall/token refresh. This is an app-instance identifier. |
| **Firebase anonymous UID** | Firebase Auth anonymous sign-in | Satisfy Storage rules during vendor image upload | Created only for the upload window, then signed out. It is not linked to the GasLink account. |
| **IP address** | Network layer | Delivered to Firebase/Google, TextBee, and DeepSeek as part of normal HTTP traffic | Not stored by GasLink code, but processed by providers. Disclose. |
| **Approximate location from IP** | Provider-side inference | Google/TextBee/DeepSeek may infer country/city | Not requested by the app. Disclose as provider metadata. |

**Not handled:** IMEI, MEID, Android ID, serial number, MAC address, advertising ID (no ad SDK), SIM serial, subscriber ID, contacts, calendar, photos other than the one selected, microphone audio, camera images, SMS content on the customer device, call history, installed-app list, precise GPS.

### 2.5 Capabilities that exist in code but are not active in the UI

| Capability | Evidence | Status | Recommendation |
|---|---|---|---|
| Precise latitude/longitude on orders | `Order` model has `latitude`/`longitude`; `placeOrder` accepts them | Confirmed no current caller passes coordinates (`consumer_order_dialog.dart` omits them) | Keep fields; disclose if a future screen activates them. |
| Vendor latitude/longitude | `Vendor` model and profile screen have `_latitude`/`_longitude` | No map picker found; values load from existing vendor doc and save back | Disclose "business location" if populated. |
| OTP login via SMS | `lib/services/otp_auth_service.dart`, `otp_verification_screen.dart`, `GatewayConfig.enableOtpLogin` | Disabled (`ENABLE_OTP_LOGIN=false`); screen not routed | If enabled later, OTP codes and phone numbers will transit the gateway and may be logged. |
| Vendor image upload | `image_picker` + Firebase Storage | Active | Disclose photo upload and Storage processing. |
| Ad placements with external links | `lib/widgets/ad_slot.dart`, `ad_placements` collection | Active | Disclose that tapping an ad opens a third-party site. No in-app click tracking found. |
| Referral invite with a third party's phone | `referral_service.dart` writes `refereePhone` | Active | Disclose that the referrer provides the referee's number; add a consent attestation. |

---

## 3. Data collected and stored in Firestore

Project: `gaslink-app-4bfbb` (Spark plan at audit time).
No Firestore rules file exists, and a live probe confirmed **unauthenticated public read access** to `users` documents with the API key embedded in the app. **All statements below describe intended access, not enforced access.** Treat every collection as readable by anyone who extracts the key from the APK.

### 3.1 `users/{uid}` — consumer, vendor mirror, and admin-related accounts

| Field | Example | Purpose | Sensitivity |
|---|---|---|---|
| `phone` (also used as login identifier) | `+2557...` | Login, contact, order coordination | High |
| `name` | `"Test Mteja"` | Delivery greeting, vendor handoff | High |
| `role` | `consumer`, `vendor`, `admin` | Route the app | Medium |
| `passcodeHash` | SHA-256(`pin:phone`) | PIN login | High — 4-digit PIN is brute-forceable |
| `pinAttempts`, `lockedUntil` | `0`, timestamp | Lockout after wrong PIN | Medium |
| `mustChangePin` | `false` | Force PIN change | Low |
| `termsAcceptedAt` | timestamp | Terms acceptance evidence | Medium |
| `adsConsent` | `true/false` | Marketing/ad consent flag | Medium |
| `notification_channel` | `both`, `push_only`, `sms_only`, `none` | User's notification preference | Low |
| `ai_assistant_enabled` | `false` | Subscriber gate for SMS AI | Medium |
| `fcmToken` | long token | Push delivery | Medium (app-instance identifier) |
| `referralCode` | `GL-XXXX` | Referral programme | Low |
| `profileCompleted` | `true` | Onboarding state | Low |
| `area`, `street`, `address` | `"Sinza"`, `"Mori"`, `"karibu na soko"` | Delivery | High |
| `preferredBrand`, `preferredSize` | `"Oryx"`, `"6kg"` | Defaults and AI context | Medium |
| `createdAt`, `updatedAt` | timestamps | Audit | Low |

### 3.2 `users/{uid}/cylinders/{cylinderId}` — household cylinder register

| Field | Purpose | Sensitivity |
|---|---|---|
| `brand`, `size`/`weight` | Identify the cylinder | Medium |
| `quantity` | How many units | Medium |
| `refillCycle` | `"30 days"` | Medium — can infer household routine |
| `lastRefillDate`, `purchase_date` | Refill reminder and AI context | Medium |
| `units[]` (after delivery) | Serialised cylinder units with `source_order_id`, registration timestamps | Medium |
| `createdAt` | Audit | Low |

### 3.3 `orders/{orderId}` — transaction record

| Field | Purpose | Sensitivity |
|---|---|---|
| `consumer_uid` / `consumerUid` | Link to buyer | High |
| `vendor_id` / `vendorId`, `vendor_name` | Link to seller | Medium |
| `productId`, `brand`, `size`, `type`, `orderIntent`, `quantity` | What was ordered | Medium |
| `unitPrice`, `total`, `commissionRate`, `commissionDue`, `commissionModel`, `billed` | Commercial record | High (financial) |
| `status`, `status_history[]` | Lifecycle audit (`placed → seen → confirmed → on_the_way → delivered_pending → delivered`, plus `disputed`/`cancelled`) | High |
| `deliveryAddress` | Where to deliver | High |
| `contactPhone`, `receiverPhone` | Who to call on arrival | High |
| `specialRequests` | Free text; may contain household details | High |
| `paymentMethod` | `cash` or `mobile_money` (no mobile-money number stored in the order model) | High |
| `latitude`, `longitude` | Precise delivery coordinates if supplied | High — confirmed no current caller passes coordinates (`consumer_order_dialog.dart` omits them) |
| `etaMinutes`, `driverPhone`, `vendorPhone` | Coordination after confirmation/dispatch | High |
| `deliveredAt`, `cancelledAt`, `cancellationReason` | Audit | Medium |
| `cylinder_registered`, `cylinder_registered_at` | Idempotent cylinder ledger | Low |
| `status_history[].actor`, `.note`, `.at` | Who changed what | Medium |

### 3.4 `vendors/{vendorId}` — business profile and KYC

| Field | Purpose | Sensitivity |
|---|---|---|
| `businessName`, `phone`, `secondaryPhone`, `email` | Contact and identity | High |
| `region`, `district`, `ward`, `street`, `areaText` | Service area | High |
| `latitude`, `longitude` | Business location | High (if populated) |
| `deliveryRadiusKm`, `deliveryFeeModel`, `openingHours` | Commercial terms | Medium |
| `acceptsCash`, `acceptsMobileMoney`, `lipaNumber` | Payment methods; Lipa number is a payment identifier | High |
| `imageUrl` | Shop photo in Firebase Storage | Medium |
| `stockedBrandNames`, `offeredServices`, `hasOperationalScale`, `agreedToConsumerProtection` | Operating profile | Medium |
| `businessLicenseUrl`, `wmaStickerUrl`, `superDealerProofUrl` | KYC evidence links | **High** — may be licences, tax documents, or dealer invoices |
| `commissionModel`, `subscriptionFee`, `commissionRate`, `currentTier`, `completedOrders`, `avgDeliveryTimeMinutes` | Commercial/performance | High |
| `verified`, `verifiedAt`, `verifiedBy`, `status`, `statusReason`, `kycReviewedAt`, `kycReviewedBy` | Trust and moderation | Medium |
| `createdAt`, `updatedAt` | Audit | Low |

**Note:** KYC fields are URLs, not uploaded files in the app. If vendors paste Google Drive/Dropbox links, those documents may be publicly accessible outside GasLink's control. This is a data-protection risk and a fraud risk. **VERIFY** how vendors are told to supply them.

### 3.5 `reviews/{reviewId}` — post-delivery feedback

| Field | Purpose | Sensitivity |
|---|---|---|
| `order_id`, `vendor_id`, `vendor_name`, `brand_name` | Link review to transaction | Medium |
| `rating`, `tags` | Service quality | Medium |
| `custom_comment` | Free text; may contain names, addresses, or complaints | High |
| `enable_reminder`, `reminder_interval` | Refill reminder preference | Medium |
| `created_at` | Audit | Low |

### 3.6 `referrals/{referralId}` — consumer-to-vendor referrals

| Field | Purpose | Sensitivity |
|---|---|---|
| `referrerUid`, `referrerRole` | Who invited | Medium |
| `refereeRole`, `refereeShopName` | Who was invited | Medium |
| `refereePhone` | Third party's phone number | **High** — collected from the referrer, not the referee |
| `status`, `createdAt` | Programme state | Low |

**Risk:** the referee has not consented. The policy should state that the referrer confirms they have permission to share the number, and the referee should be able to opt out.

### 3.7 `ajira_interest/{docId}` — GasPlan employer-interest form

| Field | Purpose | Sensitivity |
|---|---|---|
| `name` | Applicant | High |
| `phone` | Contact | High |
| `employer` | Current employer | **High** — employment relationship |

This is a job/benefits lead, not a gas order. It needs its own purpose statement and retention rule.

### 3.8 `ad_requests/{docId}` and `ad_placements/{docId}`

`ad_requests`: `placement`, `message`, `budget`, `status`, `createdAt` — vendor advertising enquiries. May contain free text with contact details.

`ad_placements`: `title`, `subtitle`, `imageUrl`, `linkUrl`, `ctaText`, `active`, `audience`, `updatedAt` — first-party ad content. No impression, click, or conversion tracking was found in the app.

### 3.9 `disputes/{orderId}` — delivery disputes

| Field | Purpose | Sensitivity |
|---|---|---|
| `orderId`, `consumerUid`, `vendorId` | Link to the transaction | High |
| `reason` | `consumer_did_not_receive` or free text | High |
| `status` | `open` (current) | Medium |
| `createdAt`, `updatedAt` | Audit | Low |

### 3.10 `notifications/{docId}` and `notification_outbox/{docId}`

`notifications`: `userId`, `fcmToken`, `title`, `body`, `data`, `createdAt`, `read`, `status`, `sentAt`, `source`, `outboxId`.
`notification_outbox`: `userId`, `phone`, `title`, `body`, `smsMessage`, `data`, `status`, `attempts`, `createdAt`, `nextAttemptAt`.

**Sensitivity:** notification bodies and SMS fallbacks can contain brand, size, order code, customer name, address, vendor phone, driver phone, and ETA. They may appear on a lock screen or be forwarded. Disclose that order details are sent by push/SMS.

### 3.11 `admin_audit_logs/{docId}` — admin action trail

| Field | Purpose |
|---|---|
| `actorUid`, `actorRole` | Who acted |
| `action`, `entityType`, `entityId` | What changed |
| `before`, `after` | Snapshot of changed values — may include vendor PII |
| `reason` | Admin justification |
| `createdAt` | Timestamp |

### 3.12 `app_settings/admin` and `safety_guidelines`

`app_settings/admin`: `commissionRate`, `defaultCommissionModel`, `defaultSubscriptionFee`, `supportPhone`, `supportEmail`, `updatedAt`, `updatedBy`. No consumer PII.

`safety_guidelines`: safety content shown in the safety hub. No consumer PII.

### 3.13 Collections found in code but not deeply modelled here

`products`, `cylinders` (vendor stock/catalogue), `app_settings`, `safety_guidelines`, `ad_requests`, `ad_placements`.

`products` contains vendor catalogue data (brand, size, price, stock). It is business data, not consumer personal data, but it reveals vendor commercial terms.

### 3.14 Inferences the system can make

Even without GPS or device scanning, the stored data supports inferences that a privacy policy should acknowledge:

- **Household refill cadence** — from `lastRefillDate`, `refillCycle`, and repeat orders. This can reveal occupancy or absence patterns.
- **Household size / consumption** — from cylinder size, quantity, and order frequency.
- **Home area** — from `area`, `street`, `address`, and delivery history. This is location data even without coordinates.
- **Payment preference** — from `paymentMethod` and vendor `lipaNumber`.
- **Vendor reliability** — from `completedOrders`, `avgDeliveryTimeMinutes`, reviews, and disputes.
- **Customer service history** — from disputes, reviews, and AI/SMS conversations.
- **Marketing responsiveness** — if `adsConsent` is used with first-party placements (no click tracking was found, so this is currently limited).

Do not describe these as "anonymous" or "non-personal" in the policy; they are derived personal data.

---

## 4. Local storage on the phone

### 4.1 SharedPreferences (unencrypted)

| Key | Contents | Risk |
|---|---|---|
| `admin_pin` | The admin PIN as a plain string | **High** — readable on a rooted/backed-up device; `clearPin()` exists but is never called, so it survives logout |
| `session_role` | `consumer`, `vendor`, `admin` | Medium |
| `session_phone` | The signed-in phone number | High |
| `session_user_id` | Firestore user document ID | Medium |
| legacy `gaslink_session_*` keys | Migrated session values | Medium |
| Theme key | `light`/`dark`/`system` | Low |
| Locale key | `sw`/`en` | Low |

**`android:allowBackup` is not set in the manifest**, so it defaults to `true`. Android may include SharedPreferences in Google cloud backup, which means the session and the plaintext admin PIN could leave the device. Recommended fix: `android:allowBackup="false"` or a backup exclusion file.

### 4.2 What is not stored locally

- No local database of orders or customers.
- No cached SMS inbox.
- No photo library cache beyond the temporary file returned by the picker.
- No analytics or crash logs.

### 4.3 Session persistence

The app keeps the user signed in across restarts by storing role/phone/user ID in SharedPreferences. `signOut()` calls `clearSession()` (role/phone/user ID) and removes the FCM token from Firestore. It does **not** call `AdminPinService.clearPin()`, and no other code calls that method either — so the plaintext admin PIN remains in SharedPreferences after logout and after switching accounts.

---

## 5. What leaves the phone, and to whom

### 5.1 Firebase / Google (processor)

| Data | Service | Purpose |
|---|---|---|
| Account fields, orders, cylinders, vendor profile, reviews, referrals, disputes, ads, audit logs | Cloud Firestore | Application database |
| Vendor shop photo | Firebase Storage | Shop image |
| FCM token, notification payloads | Firebase Cloud Messaging | Push delivery |
| Anonymous Firebase UID | Firebase Auth | Storage write authentication |
| Device/app metadata in SDK requests (model, OS, app version, language, IP) | Google Play services / Firebase SDKs | Transport, diagnostics, security | **VERIFY** exact Firebase data collection settings in the console |

Firestore/Storage region: **VERIFY** in the Firebase console. If the project uses a multi-region or non-Tanzania location, the policy must disclose cross-border storage.

Google's own privacy policy and Firebase terms govern Google's processing. A data processing addendum (DPA) should be in place.

### 5.2 TextBee (processor / SMS gateway)

TextBee is the SMS provider behind the Android gateway phone. It receives:

- Destination phone number and full SMS text for every outbound message.
- Sender phone number and full SMS text for every inbound message the poller reads.
- Device telemetry for the gateway handset: model (`SM-A075F`), Android version, SIM carriers, signal, battery, network, storage, app state, heartbeat.

It does **not** receive the customer's phone model. It receives the **gateway phone's** model.

TextBee's retention, security, and subprocessors: **VERIFY** against their privacy policy/DPA. The 50-messages/day cap is shared by inbound and outbound.

### 5.3 DeepSeek (AI processor)

On every AI-handled SMS, the gateway sends DeepSeek:

- The inbound message text and the sender's phone number.
- Live catalogue: vendor names, brands, sizes, prices, stock, delivery terms, payment methods, opening hours, scale availability, service area.
- Customer profile: name, area, address, registered cylinders (brand, size, last refill date).
- Up to two recent orders: order code, status, brand, size, total, vendor name, vendor phone, driver phone, ETA.
- Safety guidelines text.
- The system prompt/persona.

DeepSeek is a China-based provider. This is a **cross-border transfer of personal data** (name, phone, address, order history). The policy must disclose AI processing and cross-border transfer, and counsel should confirm the lawful transfer mechanism. DeepSeek's retention/abuse-monitoring policy: **VERIFY**.

If the AI call fails or the live catalogue is unavailable, the gateway is designed not to quote prices or terms. That is a product safeguard, not a privacy control.

### 5.4 External links

`url_launcher` opens external URLs from:

- Vendor contact actions (phone, WhatsApp, maps, email).
- Admin vendor detail (call/WhatsApp).
- Ad placements (`linkUrl`).
- About/safety/support links.

Tapping a link discloses the user's IP address and any URL parameters to the destination site. The app does not add tracking parameters.

### 5.5 Network metadata

Every request to Firebase, TextBee, DeepSeek, or an external link necessarily exposes the user's IP address and TLS metadata to that provider. The app uses HTTPS for Firebase and public endpoints. The pilot gateway uses cleartext HTTP on the LAN (see §11).

---

## 6. Gateway-side data on the operator Mac

Path: `/Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox`

### 6.1 Files that contain personal data

| File | Contents | Retention today | Risk |
|---|---|---|---|
| `data/sms-log.json` | Up to 2,000 inbound/outbound SMS entries: phone, message text, status, channel, error, timestamp. Includes AI replies and order notices. | Capped at 2,000 entries; no time limit | **High** — full message content and phone numbers |
| `data/sms-order-state.json` | In-progress SMS order conversation state per phone (name, address, brand, size, stage). | Cleared on completion/cancel; may survive restarts | **High** |
| `data/ai-sessions.json` | AI session state (currently empty, 2 bytes) | Unknown | Medium |
| `data/operator-inbox.jsonl` | Operator-relayed messages (append-only) | No rotation found | **High** |
| `data/self-number-inbox.jsonl` | Replies suppressed for gateway SIMs, with phone/inbound/reply | No rotation found | **High** |
| `gateway.log` | Startup logs, poller lines, phone numbers, AI handled/replied status; may include message previews | Append-only | Medium–High |
| `data/kachi-sandbox.db` (+ WAL/SHM) | Fintech sandbox ledger and state; may include names, phones, transactions | Indefinite | **High** |
| `data/ai-config.json`, `data/ai-eval-latest.*` | AI persona/config and evaluation output; may include sample PII | Indefinite | Medium |
| `data/textbee-inbound-cursor.json` | Last processed timestamp | Low | Low |
| `data/eod-reports/` | End-of-day reports (VERIFY contents) | Unknown | VERIFY |

### 6.2 Access and protection

- The gateway runs as the `apple` user on the Mac.
- Files are ordinary user-readable files. Protection depends on macOS FileVault and account security: **VERIFY** FileVault is on.
- No application-level encryption, no field-level encryption, no log redaction.
- The dashboard at `/dashboard` is served by the same Express app. The HTML is public; the SMS/AI data endpoints require `x-api-key` (`sandboxAuthenticate`) and the dashboard keeps that key in browser `localStorage`. Anyone with the key or a shared browser session can read SMS/AI logs.
- `gateway.log` and `data/` are outside the GasLink git repo and are **not** covered by repo access controls.

### 6.3 Gateway endpoints that accept data

| Endpoint | Auth | Risk |
|---|---|---|
| `POST /v1/inbound-sms` | `x-api-key` **or** `TEXTBEE_INBOUND_SECRET`; **`TEXTBEE_INBOUND_SECRET` is not set** | Confirmed: the route accepts unauthenticated POSTs in sandbox mode, so anyone who can reach port 8080 can inject messages and trigger AI/SMS spend |
| `POST /v1/send-sms` | `x-api-key` | Tenant SMS sending |
| `/v1/bridge/*` | `x-api-key` | Subscriber lookup, orders, catalogue, safety |
| `/api/sandbox/*` | `sandboxAuthenticate` (VERIFY) | Sandbox state |
| `/dashboard` | Static HTML is public; its data endpoints (`/api/sandbox/sms/log`, `/api/sandbox/ai/*`) require `x-api-key` | The key is kept in the browser's `localStorage`; anyone using a shared machine or an extracted key can read SMS/AI logs |

---

## 7. AI processing — exact data flow

```
Customer SMS
  → TextBee (gateway phone)
  → textbee-inbound-poller.js
  → /v1/inbound-sms
  → subscriber gate (authorized AI user?)
  → sms-order-service.js (order intent / state machine)
  → app-context.js (live Firestore snapshot)
  → DeepSeek API
  → reply trimmed to 160 chars
  → sms-gateway.js → TextBee → customer
```

Data sent to DeepSeek per message is listed in §5.3. The gateway does **not** send the customer's device model, contacts, or location coordinates. It does send the delivery address and order history that the customer or vendor provided.

**Conversation memory:** the product requirement is 90 days, bounded. The current gateway stores per-phone order state in `sms-order-state.json` only while an order conversation is active, and AI sessions in `ai-sessions.json`. A 90-day conversational memory store is **not** clearly implemented in the audited files. **VERIFY** before claiming 90-day memory in the policy.

**Rate limiting:** no hard rate limit during testing. This is an abuse/cost risk, not only a privacy risk.

---

## 8. SMS ordering — privacy-relevant behavior

- Any phone can text the gateway number; no app or smartphone is required.
- Unknown numbers are logged and not engaged during the current testing phase: the opt-in SMS is paused (`optInUnauthorized: false`) as of 17 Nov 2026. The code path remains intact for a future dedicated GasLink number.
- The subscriber gate blocks AI calls for unregistered senders; only numbers registered in the app are engaged, and only when they initiate the message.
- For registered senders, the gateway can create a Firestore order from SMS with name, address, brand, size, quantity, and payment method.
- The vendor receives the customer's name, address, and order details by SMS. Any further vendor-to-customer contact is the vendor's choice and outside the SMS gateway.
- The customer receives the vendor's phone after confirmation, and the driver's phone after dispatch; the customer chooses how to engage. This is app-flow, not an SMS-gateway function.
- Messages to gateway SIMs are suppressed to prevent a self-reply loop; the suppressed reply is logged to `self-number-inbox.jsonl` and relayed to the operator phone (`GASLINK_SELF_NUMBER_RELAY=true`).
- Carrier/bank alert SMS (M-PESA, Vodacom, TING, etc.) are filtered out and not treated as orders.
- SMS content is visible to the mobile carrier and to TextBee. It is not end-to-end encrypted.

**Policy implication:** the privacy policy must cover SMS as a service channel, including that messages are processed by an SMS gateway provider and may be logged for support, fraud prevention, and quality.

---

## 9. Retention — current behavior vs recommended

| Data | Current retention | Recommended policy/implementation |
|---|---|---|
| Firestore user/order/vendor records | Indefinite | Define a schedule: active account + statutory/commercial period; delete or anonymise after N years |
| Firestore `notifications` | Indefinite | 30–90 days, then delete |
| Firestore `notification_outbox` | Indefinite (status pending/sent) | 30 days after sent/failed |
| Firestore `disputes` | Indefinite | Retain until resolved + 1–2 years |
| Firestore `admin_audit_logs` | Indefinite | 2–7 years depending on commercial/legal need |
| `sms-log.json` | Last 2,000 entries | 30–90 days, with redaction of message bodies where possible |
| `sms-order-state.json` | Until conversation ends | 24 hours after completion/cancel |
| `operator-inbox.jsonl` | Append-only | 30–90 days, rotate |
| `self-number-inbox.jsonl` | Append-only | 30–90 days, rotate |
| `gateway.log` | Append-only | 14–30 days, rotate, redact phone numbers |
| `kachi-sandbox.db` | Indefinite | Sandbox only; exclude real PII or reset regularly |
| SharedPreferences session | Until logout/uninstall | Clear on logout; exclude from backup |
| SharedPreferences `admin_pin` | Until cleared | Remove entirely; do not persist admin PIN |
| TextBee messages/device telemetry | Provider-defined | **VERIFY** and document |
| DeepSeek prompts | Provider-defined | **VERIFY** and document; prefer zero-retention/enterprise terms |
| Firebase backups | Provider-defined | **VERIFY**; include in deletion SLA |

**Account deletion:** there is no delete-account flow in the app. A deletion request currently requires manual Firestore work. This is a launch blocker for Google Play and a PDPA rights gap.

---

## 10. Privacy-policy disclosure checklist

The policy should have a clear, plain-language section for each item below. This is a drafting input, not legal text.

### 10.1 Identity and contact

- Legal entity name and address.
- Data protection contact / email / phone.
- Whether a DPO is appointed (likely not required at pilot scale, but name a responsible person).

### 10.2 What we collect

- **Account:** phone number, name, PIN (stored as a hash), role, language, notification preference, consent flags.
- **Delivery:** area, street, address, contact/receiver phone, special requests, order history, cylinder register, refill dates.
- **Vendor:** business name, contact details, business address/service area, KYC document links, payment details (Lipa number), shop photo, performance metrics.
- **Transactions:** brand, size, quantity, price, commission, status history, dispute reason.
- **Feedback:** rating, tags, comment, reminder preferences.
- **Referrals:** referrer ID, referee shop name and phone.
- **GasPlan:** name, phone, employer.
- **Notifications:** FCM token, notification content, delivery status.
- **Technical:** IP address, device/app metadata processed by Firebase/Google, SMS metadata processed by TextBee.
- **AI/SMS:** message text, phone number, and the context listed in §5.3.

### 10.3 What we do **not** collect (if the unused permissions are removed)

- Precise or approximate GPS location.
- Contacts, SMS inbox, call log.
- IMEI, serial number, SIM number, phone number from the device.
- Camera, microphone, photos other than a vendor-selected shop image.
- Advertising ID or cross-app tracking.

If location permissions stay in the build, this section must change.

### 10.4 Why we collect it (purposes)

- Create and secure accounts.
- Place, confirm, dispatch, and deliver orders.
- Share the minimum contact details needed between customer, vendor, and driver.
- Send order notifications by push and SMS.
- Provide AI-assisted SMS ordering and support.
- Operate the referral and GasPlan programmes.
- Prevent fraud, resolve disputes, and audit admin actions.
- Comply with legal and tax obligations.
- Marketing/advertising **only** with `adsConsent` (and provide an opt-out).

### 10.5 Who we share with

- **Vendors and drivers:** customer name, phone, address, order details — only as needed for fulfilment.
- **Customers:** vendor phone after confirmation; driver phone after dispatch.
- **Firebase/Google:** database, storage, push, auth.
- **TextBee:** SMS delivery and receipt.
- **DeepSeek:** AI processing of SMS and order context.
- **Professional advisers / authorities:** where legally required.
- **No sale of personal data.** State this explicitly if true.

### 10.6 Cross-border transfers

- Google/Firebase region: **VERIFY**.
- DeepSeek (China): yes, for AI processing.
- TextBee: **VERIFY** hosting region.
- Describe safeguards (contracts, standard clauses, consent) after legal review.

### 10.7 Retention

- Summarise the schedule in §9.
- State that deletion requests are honoured within a stated period (e.g., 30 days), subject to legal retention.

### 10.8 Security

- PIN hashing (SHA-256), account lockout, TLS to Firebase, access controls.
- Be honest: no system is perfectly secure. Do not claim "bank-grade" or "end-to-end encrypted."
- Do not claim SMS is encrypted.

### 10.9 User rights

- Access, correction, deletion, objection, withdrawal of consent, complaint.
- How to exercise them (support phone/email).
- Response timeline.
- Right to complain to the Tanzanian Personal Data Protection Commission (confirm the correct authority and process with counsel).

### 10.10 Children

- State whether the service is intended for users 18+ or with guardian consent. LPG delivery is a household service; a minimum age is prudent.

### 10.11 Cookies / tracking

- The Android app uses no cookies and no ad/analytics SDK.
- If a web version or dashboard is public, address cookies and server logs separately.

### 10.12 Changes

- Version the policy, show the effective date, and notify users of material changes.
- Store the accepted policy version with `termsAcceptedAt` (currently only a timestamp, no version).

---

## 11. Risk register

Severity is launch impact, not likelihood alone.

| # | Risk | Severity | Evidence | Recommended action |
|---|---|---|---|---|
| 1 | Firestore has no security rules | **Critical** | `firestore.rules` missing; `firebase.json` has no `firestore` section | Write and deploy rules; test with the Firebase emulator; restrict reads/writes by role and ownership |
| 2 | Storage public read + anonymous write to any vendor path | **Critical** | `storage.rules` | Require real auth or signed uploads; per-vendor path ownership; restrict reads if images are not public |
| 3 | Hardcoded admin phone + PIN `0000` | **Critical** | `auth_service.dart`, `admin_pin_service.dart` | Remove hardcoded admin; use a real admin account with a strong secret; never store the PIN in SharedPreferences |
| 4 | No account deletion/export | **High** | No flow found | Build in-app deletion + web request path; cascade Firestore/Storage cleanup |
| 5 | Gateway logs contain full SMS/PII with no retention | **High** | `data/sms-log.json`, `operator-inbox.jsonl`, `self-number-inbox.jsonl`, `gateway.log` | Rotate, redact, encrypt disk, restrict access, define retention |
| 6 | DeepSeek receives name/address/order history | **High** | `services/app-context.js` | Disclose; review DeepSeek terms; minimise fields; consider a redaction layer |
| 7 | `android:allowBackup` defaults to true | **High** | Merged manifest | Set `allowBackup="false"` or exclude SharedPreferences |
| 8 | Unused location permissions | **Medium–High** | Manifest / APK | Remove permissions and unused `flutter_map`/`latlong2` deps |
| 9 | Release APK is debug-signed | **High** | `android/app/build.gradle` | Create a release keystore; rotate; do not distribute debug builds publicly |
| 10 | Cleartext HTTP to stale LAN IPs | **Medium** | `network_security_config.xml` | Use HTTPS/tunnel; remove stale IPs; update to current `.14` only for local testing |
| 11 | Gateway API key supplied at build time (`env.local.json` → `--dart-define`) | **Medium** | `gateway_config.dart`, `env.local.json` | Treat any key shipped to a client as public; rotate; do not rely on it as a secret; OTP disabled limits impact |
| 12 | `/v1/inbound-sms` is unauthenticated — CONFIRMED (`TEXTBEE_INBOUND_SECRET` not set) | **High** | `routes/inbound-sms.js`, `.env` | Set a strong `TEXTBEE_INBOUND_SECRET`; rate-limit; restrict port 8080 to the LAN/tunnel |
| 13 | Dashboard HTML is public; SMS/AI data endpoints use a key stored in browser `localStorage` | **Medium–High** | `server.js`, `public/dashboard.html` | Put the dashboard behind real auth; avoid long-lived keys in localStorage; bind to localhost |
| 14 | Referral collects a third party's phone | **Medium** | `referral_service.dart` | Add consent attestation + opt-out; disclose |
| 15 | GasPlan collects employer | **Medium** | `gas_plan_screen.dart` | Separate purpose/retention; disclose |
| 16 | Vendor KYC URLs may point to public cloud drives | **High** | `vendor_profile_screen.dart` | Require uploads to private Storage; verify access controls |
| 17 | Vendor shop photo may retain EXIF GPS | **Medium** | `image_picker` with resize/quality | Explicitly strip EXIF before upload; test |
| 18 | 4-digit PIN + client-side lockout | **High** | `auth_service.dart` | Server-side rate limiting; stronger PIN or OTP; monitor |
| 19 | No privacy policy version stored | **Medium** | `termsAcceptedAt` only | Add `termsVersion` / `privacyVersion` |
| 20 | No age gate | **Low–Medium** | None found | Add 18+ attestation or guardian consent |
| 21 | AI/SMS has no hard rate limit in testing | **Medium** | Config | Add per-number and global limits before public launch |
| 22 | TextBee 50/day shared quota | **Operational** | TextBee | Monitor; upgrade or self-host in future |
| 23 | FCM payloads may show order details on lock screen | **Medium** | Notification bodies | Offer a "hide sensitive previews" setting; disclose |
| 24 | No DPA with processors | **High** | None found | Execute DPAs with Google, TextBee, DeepSeek |
| 25 | Tanzania PDPA registration/notification | **VERIFY** | — | Confirm with counsel whether GasLink must register as a data controller |
| 26 | Cross-border transfer mechanism | **VERIFY** | — | Confirm lawful basis/consent for China/US transfers |
| 27 | `admin_audit_logs` `before`/`after` may store vendor PII | **Medium** | `AdminAuditLog.toMap()` | Minimise snapshots; restrict access |
| 28 | Mac disk encryption / account security | **VERIFY** | — | Enable FileVault; separate gateway user; restrict SSH |
| 29 | Sandbox SQLite may contain real PII | **Medium** | `data/kachi-sandbox.db` | Keep sandbox data separate; reset; do not use real numbers |
| 30 | OTP codes may be logged if OTP is enabled | **Medium** | `sms_store.js` logs all sends | Redact OTP bodies or exclude from logs before enabling |

---

## 12. Data subject rights readiness

| Right | Current capability | Gap |
|---|---|---|
| Access / copy of data | Manual Firestore export | No self-service; no documented SLA |
| Correction | Profile screen for some fields; admin console for vendors | No unified correction path |
| Deletion | Manual | No cascade, no Storage cleanup, no verification |
| Withdraw consent | `adsConsent` toggle in Settings | No effect on already-processed data; no consent ledger |
| Object to processing | None | No process |
| Portability | None | No export format |
| Complaint | Support phone only | No published complaint route/authority |
| Breach notification | None | No incident response plan |

**Minimum pilot readiness:** a documented support email/phone, a 30-day response target, a manual runbook for export/deletion, and a named responsible person.

---

## 13. Open questions for the founder / counsel

1. **Legal entity and jurisdiction.** Which company contracts with users and vendors? Tanzania? Where is it registered?
2. **Firestore region.** Which location was selected for `gaslink-app-4bfbb`? This determines the cross-border statement.
3. **TextBee entity and hosting.** Where is the provider based, and what are its retention/subprocessor terms?
4. **DeepSeek terms.** Can we get zero-retention or enterprise terms? If not, disclose retention and consider minimisation.
5. **PDPA registration.** Does GasLink need to register/notify the PDPC as a data controller?
6. **Age policy.** 18+ only, or guardian consent?
7. **KYC documents.** Are vendors expected to upload licences into the app, or paste links? The current design suggests links, which is a security gap.
8. **Marketing.** Is `adsConsent` used for third-party ads, or only first-party GasLink promotions? The policy wording differs.
9. **Retention periods.** Commercial/tax needs for orders and commissions; dispute period; audit period.
10. **Data location for backups.** Firebase backups may be in a different region.
11. **Whether to keep location permissions.** If no feature uses them, remove them before launch to reduce disclosure scope.
12. **Whether the customer app should ever read the phone number automatically.** Current design does not; keep it that way unless OTP login requires it.

---

## 14. Recommended remediation order

### Before any public link or Play Store submission

1. Deploy Firestore rules (deny by default, role/ownership based).
2. Fix Storage rules (no public write; per-vendor ownership; consider signed URLs).
3. Remove hardcoded admin credentials and plaintext admin PIN storage.
4. Set `android:allowBackup="false"`.
5. Remove unused location permissions and `flutter_map`/`latlong2`.
6. Create a release keystore and sign the APK properly.
7. Put the dashboard and `/v1/inbound-sms` behind authentication; set `TEXTBEE_INBOUND_SECRET`.
8. Add account deletion + data export runbook.
9. Write and publish the privacy policy + terms with version tracking.
10. Execute DPAs with Google, TextBee, and DeepSeek.

### Before scaling beyond the pilot

11. Add log rotation/redaction and disk encryption verification.
12. Add rate limits and abuse monitoring for AI/SMS.
13. Minimise DeepSeek payloads (e.g., send area instead of full address where possible).
14. Add EXIF stripping for vendor photos.
15. Add a consent ledger and marketing opt-out that is honoured end-to-end.
16. Add breach response and data subject request procedures.
17. Review PDPA registration and cross-border transfer mechanisms with counsel.

---

## 15. Appendix — evidence map

| Topic | File / command |
|---|---|
| Release permissions | `aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk` |
| Merged manifest | `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml` |
| Source manifest | `android/app/src/main/AndroidManifest.xml` |
| Network security | `android/app/src/main/res/xml/network_security_config.xml` |
| Signing config | `android/app/build.gradle` |
| Storage rules | `storage.rules` |
| Firebase config | `firebase.json`, `.firebaserc` |
| Auth / PIN / consent | `lib/services/auth_service.dart` |
| Admin PIN / session | `lib/services/admin_pin_service.dart` |
| FCM token / notifications | `lib/services/notification_service.dart` |
| Order fields / lifecycle / outbox | `lib/models/order.dart`, `lib/services/order_service.dart`, `lib/services/order_lifecycle.dart` |
| Vendor fields | `lib/models/vendor.dart`, `lib/screens/vendor/vendor_profile_screen.dart` |
| Consumer profile | `lib/screens/consumer/consumer_profile_setup_screen.dart` |
| Reviews | `lib/screens/consumer/consumer_order_screen.dart` |
| Referrals | `lib/services/referral_service.dart` |
| GasPlan | `lib/screens/consumer/gas_plan_screen.dart` |
| Ads | `lib/services/ad_service.dart`, `lib/widgets/ad_slot.dart`, `lib/models/ad_models.dart` |
| Admin audit | `lib/models/admin_models.dart`, `lib/services/admin_service.dart` |
| Image upload | `lib/services/vendor_image_service.dart` |
| Gateway config | `lib/core/gateway_config.dart` |
| AI context sent to DeepSeek | `services/app-context.js` |
| AI pipeline | `services/ai-service.js`, `routes/inbound-sms.js` |
| SMS gateway / self-number guard | `services/sms-gateway.js` |
| Inbound poller | `services/textbee-inbound-poller.js` |
| SMS order state | `services/sms-order-service.js` |
| Outbox worker | `services/notification-outbox-worker.js` |
| Gateway server / dashboard | `server.js`, `public/dashboard.html` |
| Gateway data files | `data/sms-log.json`, `data/sms-order-state.json`, `data/operator-inbox.jsonl`, `data/self-number-inbox.jsonl`, `gateway.log` |

---

## 16. Change log

| Date | Version | Change |
|---|---|---|
| 17 Nov 2026 | 1.0 | Initial inventory from release APK, source audit, Firestore collection review, and gateway review |
