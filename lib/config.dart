/// App-wide configuration.
///
/// IMPORTANT: Update these before running the app.
class AppConfig {
  /// Your backend base URL (the Node server in /backend).
  /// - Android emulator talking to your PC: http://10.0.2.2:4242
  /// - Physical phone on same Wi-Fi:        http://YOUR_PC_LAN_IP:4242
  /// - Production:                          your deployed HTTPS URL
  static const String backendUrl = 'https://gcil-apk.primewebkit.com';

  /// Stripe Terminal Location ID (create one in the Stripe Dashboard
  /// under  Terminal > Locations,  e.g. 'tml_xxxxxxxxxxxx').
  static const String stripeLocationId = 'tml_GW5WuQUcquU3cU';

  /// Currency for donations.
  static const String currency = 'usd';

  /// Set to true while developing without a real card.
  /// The SDK will simulate a reader and card taps.
  static const bool simulated = false;
}
