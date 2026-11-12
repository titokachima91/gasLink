# Building GasLink on this Mac

> **Read this before running a release build.** The project is pinned to an
> older Android toolchain because the development Mac runs macOS Monterey.
> Upgrading any part of the chain breaks the build or the machine.

---

## Fixed toolchain — do not upgrade

| Component | Version | Notes |
|-----------|---------|-------|
| macOS | Monterey (Intel MacBook Air) | Hardware limit; newer Flutter/Xcode needs a newer macOS |
| Flutter | **3.24.5** | Do not upgrade |
| Android Gradle Plugin | **8.3.2** | Do not upgrade |
| Gradle | **8.10.2** | Wrapper-pinned |
| Kotlin | **1.9.22** | Do not upgrade |
| JDK | **17** (`/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home`) | JDK 21 causes daemon/toolchain issues |
| compileSdk | 35 | |
| minSdk | 23 | |

The machine has two JDKs installed. Always point `JAVA_HOME` at **JDK 17**.

---

## The release build command

```bash
cd /Users/apple/gaslink_app

JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home \
JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true" \
flutter build apk --release
```

Output:

```
build/app/outputs/flutter-apk/app-release.apk
```

**Expected duration on this Mac:** roughly **60–80 minutes** for a cold release
build. Most of that is R8 register allocation. A warm build is faster, but do
not assume the build is hung just because it is quiet. See “Is it stuck?” below.

---

## Dependency pins — do not bump

| Package / setting | Pinned value | Why |
|---|---|---|
| `share_plus` | `10.1.4` | v12 reads `flutter.compileSdkVersion`, which is null under Flutter 3.24.5 / AGP 8.3 |
| `firebase_core` | `3.11.0` | Feb 2025 FlutterFire set |
| `firebase_auth` | `5.4.2` | Uses Firebase BoM 33.8.0 / native auth 23.1.0 (Kotlin 1.9 metadata) and does **not** call `setLinkDomain` |
| `cloud_firestore` | `5.6.3` | Same set |
| `firebase_messaging` | `15.2.2` | Same set |
| `firebase_storage` | `12.4.2` | Same set |
| Firebase Android BoM | `33.8.0` (transitive) | Last BoM whose `firebase-auth` uses Kotlin 1.9 metadata |

Newer FlutterFire releases pull Firebase BoM 33.9+ and `firebase-auth` 23.2.x,
which is compiled with Kotlin 2.1 metadata. Kotlin 1.9.22 cannot read it.

---

## Troubleshooting matrix

### 1. `Module was compiled with an incompatible version of Kotlin`

```
The binary version of its metadata is 2.1.0, expected version is 1.9.0.
```

**Cause:** a newer FlutterFire/native Firebase dependency pulled
`firebase-auth` 23.2.x (Kotlin 2.1 metadata).

**Fix:** restore the Feb 2025 pins in `pubspec.yaml` (see table above), run
`flutter pub get`, and rebuild. Do **not** upgrade Kotlin to 2.x — that breaks
the fixed toolchain.

### 2. `cannot find symbol: method setLinkDomain(String)`

```
firebase_auth-5.7.0/android/.../PigeonParser.java:262: error: cannot find symbol
builder.setLinkDomain(...)
```

**Cause:** `firebase_auth 5.7.0` calls an API that does not exist in native
`firebase-auth` 23.1.0 (BoM 33.8.0).

**Fix:** keep `firebase_auth: 5.4.2`. Do not mix a newer Dart plugin with the
older native BoM.

### 3. Gradle hangs for minutes at startup / `InetAddress.getLocalHost()`

Thread dump shows:

```
java.net.InetAddress.getLocalHost()
  at org.jetbrains.kotlin.gradle.report.BuildReportsService.<clinit>
```

or:

```
at java.net.Inet6AddressImpl.lookupAllHostAddr(Native Method)
```

**Cause:** macOS cannot resolve the machine’s own name
(`apples-MacBook-Air.local`), and Java’s `getLocalHost()` waits on mDNS.

**Fix:** always build with:

```bash
JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true"
```

This makes `getLocalHost()` return the LAN IPv4 address immediately while
keeping external DNS (Google Maven, etc.) working.

### 4. `Unable to resolve host dl.google.com in hosts file ...`

**Cause:** using `-Djdk.net.hosts.file=...` as a workaround. That option
replaces the system hosts file entirely, so **external DNS stops working**.

**Fix:** do not use `jdk.net.hosts.file`. Use
`-Djava.net.preferIPv4Stack=true` instead.

### 5. `Could not connect to Kotlin compile daemon`

```
e: Daemon compilation failed: Could not connect to Kotlin compile daemon
```

**Cause:** a stale/killed Kotlin daemon, usually after an interrupted build or
a machine restart. The Kotlin Gradle plugin falls back to in-process
compilation, so the build can still succeed — it is just slower.

**Fix:** stop stale daemons and rebuild:

```bash
pkill -f GradleDaemon
pkill -f KotlinCompileDaemon
```

### 6. Gradle daemon picks JDK 21

**Cause:** `JAVA_HOME` was not set for the build shell, or an old daemon is
still running.

**Fix:**

```bash
pkill -f GradleDaemon
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
```

Confirm with `java -version` before building.

### 7. `share_plus` v12 fails on `compileSdk`

**Cause:** v12 resolves `flutter.compileSdkVersion`, which is null on Flutter
3.24.5.

**Fix:** keep `share_plus: 10.1.4`. Its API is
`Share.share(text, subject:, sharePositionOrigin:)` — not
`SharePlus.instance.share(ShareParams(...))`.

### 8. “Is it stuck?” — check before killing

A release build can sit in R8 register allocation for 20–30 minutes. Check:

```bash
ps aux | grep -E "GradleDaemon|KotlinCompileDaemon" | grep -v grep
```

If the Gradle daemon is using CPU (roughly 20–70%), it is working. A thread
dump confirms the phase:

```bash
/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home/bin/jstack <pid> \
  | grep -E "com.android.tools.r8|KotlinCompile|getLocalHost"
```

`com.android.tools.r8.ir.regalloc` = normal, keep waiting.
`getLocalHost` = the DNS stall in item 3; stop and rerun with the flag.

---

## Pre-flight checklist (30 seconds)

```bash
cd /Users/apple/gaslink_app
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
export JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true"

# Only if a previous build was interrupted:
# pkill -f GradleDaemon; pkill -f KotlinCompileDaemon

flutter --version          # expect 3.24.5
java -version              # expect 17
flutter pub get
flutter analyze            # 0 errors / 0 warnings
flutter test               # 85/85 passing
```

Then run the release build command above.

---

## Post-build verification

```bash
cd /Users/apple/gaslink_app
ls -l build/app/outputs/flutter-apk/app-release.apk
shasum -a 256 build/app/outputs/flutter-apk/app-release.apk
unzip -t build/app/outputs/flutter-apk/app-release.apk | tail -1
"$HOME/Library/Android/sdk/build-tools/36.0.0/apksigner" verify \
  --print-certs build/app/outputs/flutter-apk/app-release.apk
```

Record the SHA-256 in the phase `implementation.md`.

**Signing caveat:** `android/app/build.gradle` uses `signingConfigs.debug` for
release. The APK installs and runs, but it is **not Play-Store-ready**. A
production keystore and a release signing config are still required before
distribution.

---

## Serve the APK over Wi-Fi

From the APK folder:

```bash
cd /Users/apple/gaslink_app/build/app/outputs/flutter-apk
python3 -m http.server 8080 --bind 0.0.0.0
```

Find the Mac’s LAN IP:

```bash
ipconfig getifaddr en0    # Wi-Fi; use en1 if en0 is empty
```

Open on a phone connected to the same Wi-Fi:

```
http://<LAN-IP>:8080/gaslink-latest.apk
```

`gaslink-latest.apk` is a symlink to `app-release.apk`. macOS may ask for
firewall permission the first time; allow incoming connections for Python.
Stop the server with `Ctrl+C`.

---

## What not to do

- Do **not** upgrade Flutter, AGP, Gradle, or Kotlin.
- Do **not** bump `share_plus` or the FlutterFire packages.
- Do **not** use `jdk.net.hosts.file` (breaks external DNS).
- Do **not** kill a build during R8 unless the daemon is idle or stuck in
  `getLocalHost`.
- Do **not** change the signing config without a real keystore.
- Do **not** run `flutter pub upgrade --major-versions`; the exact pins are
  intentional.

---

## Change log

- **2026-11-12** — Documented after the Phase 5D release build. Cold build took
  ~75 minutes; final APK 56,769,554 bytes, SHA-256
  `244d39e909ee581df5c4c415d14f178fccccecb3a79f748138e7fee778d83a9b`.
