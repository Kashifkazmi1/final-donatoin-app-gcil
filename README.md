# Donation App — Flutter + Stripe Terminal

Kiosk-style donation app.

- **Phase 1 (now):** Tap to Pay — the phone itself accepts contactless cards.
- **Phase 2 (later):** Stripe M2 reader over Bluetooth (button already on the connect screen; wiring points marked with `TODO Phase 2`).

Flow: Connect screen → Donation screen ($25 / $50 / $75 / $100 / custom) → Thank You screen (auto-returns after 6s).

---

## 1. Stripe Dashboard setup (one time)

1. Create/log in to your Stripe account and make sure **Terminal** is enabled (Dashboard → Terminal). Tap to Pay on Android is only available in supported countries (US, UK, CA, AU, and others — check Stripe docs).
2. Create a **Location**: Dashboard → Terminal → Locations → New. Copy the ID (`tml_...`).
3. Get your **test secret key** (`sk_test_...`) from Developers → API keys.

## 2. Run the backend

```bash
cd backend
npm install
export STRIPE_SECRET_KEY=sk_test_YOUR_KEY   # Windows: set STRIPE_SECRET_KEY=...
node server.js
```

Runs on port 4242. If testing on a physical phone, your phone and PC must be on the same Wi-Fi, and you use your PC's LAN IP.

## 3. Create the Flutter project and drop these files in

On your machine (with Flutter SDK installed):

```bash
flutter create donation_app --org com.yourorg
```

Then copy from this package into it:
- `pubspec.yaml` → replace the generated one (keep your project name/org if different)
- `lib/` → replace the generated `lib/`

Then:

```bash
flutter pub get
```

## 4. Configure the app

Edit `lib/config.dart`:
- `backendUrl` — `http://10.0.2.2:4242` for emulator, `http://YOUR_PC_IP:4242` for a real phone
- `stripeLocationId` — your `tml_...` ID
- `simulated` — `true` to test without real cards; set `false` for real device testing

## 5. Android configuration

### android/app/build.gradle
Tap to Pay requires **minSdkVersion 26 or higher** (and Android 11+ at runtime on the device):

```gradle
defaultConfig {
    minSdkVersion 26
    targetSdkVersion 34
}
```

### android/app/src/main/AndroidManifest.xml
Add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.NFC" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<!-- Phase 2: M2 over Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-feature android:name="android.hardware.nfc" android:required="true" />
```

If your backend URL is plain `http://` during development, also allow cleartext in the `<application>` tag:

```xml
<application android:usesCleartextTraffic="true" ...>
```

(Remove this for production — use HTTPS.)

## 6. Run it

```bash
flutter run
```

With `simulated: true` you can go through the whole flow with a simulated reader and simulated card tap — no hardware needed.

### Testing real Tap to Pay
- Physical Android phone, Android 11+, NFC on, not rooted, Google Play services present.
- `simulated: false` in config.
- In **test mode** you can tap a real card and it won't be charged.
- Note: **live** Tap to Pay requires a release-signed build (debug builds are blocked by device attestation).

## 7. Build the APK

Debug APK (quick testing):
```bash
flutter build apk --debug
```

Release APK:
```bash
# 1. Create a signing key (one time)
keytool -genkey -v -keystore ~/donation-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias donation

# 2. Create android/key.properties:
#    storePassword=...
#    keyPassword=...
#    keyAlias=donation
#    storeFile=/absolute/path/to/donation-key.jks

# 3. Wire signing config in android/app/build.gradle (standard Flutter docs snippet)

# 4. Build
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Phase 2 checklist (M2 reader)

The service layer is already written — `TerminalService.discoverM2Readers()` and `connectM2Reader()`. To finish Phase 2:

1. Enable the "Connect Stripe M2 Reader" button in `connect_screen.dart` (replace `onPressed: null`).
2. Build a small picker screen: listen to `discoverM2Readers()`, show the list, call `connectM2Reader(reader)` on tap.
3. Request Bluetooth permissions at runtime (`permission_handler` is already a dependency): `Permission.bluetoothScan`, `Permission.bluetoothConnect`, `Permission.locationWhenInUse`.
4. Order the M2 from the Stripe Dashboard and register it to your Location.
5. Everything after connect (donation flow, thank you) is shared — no changes needed.

## Notes

- `mek_stripe_terminal` wraps Stripe's official native Terminal SDKs. Method names can shift slightly between versions — if something doesn't compile, check the package README on pub.dev; the flow (init → discover → connect → collect → confirm) stays the same.
- Never put your Stripe **secret key** in the Flutter app — it stays on the backend only.
- For a production kiosk, consider Android's screen pinning / lock task mode so donors can't leave the app.
"# gcil-koisk" 
