import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mek_stripe_terminal/mek_stripe_terminal.dart';

import '../config.dart';

/// Wraps the Stripe Tap to Pay flow so the UI stays clean.
class TerminalService {
  TerminalService._();
  static final TerminalService instance = TerminalService._();

  Terminal? _terminal;
  Reader? _connectedReader;

  bool get isConnected => _connectedReader != null;

  // ---------------------------------------------------------------------
  // 1. INIT — the SDK fetches short-lived connection tokens from YOUR backend
  // ---------------------------------------------------------------------
  Future<Terminal> _getTerminal() async {
    if (_terminal != null) return _terminal!;

    _terminal = await Terminal.getInstance(
      shouldPrintLogs: false,
      fetchToken: _fetchConnectionToken,
    );
    return _terminal!;
  }

  Future<String> _fetchConnectionToken() async {
    final res = await http
        .post(Uri.parse('${AppConfig.backendUrl}/connection_token'))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Connection token request failed.');
    }
    final secret = (jsonDecode(res.body) as Map<String, dynamic>)['secret'];
    if (secret is! String || secret.isEmpty) {
      throw Exception('Connection token response was invalid.');
    }
    return secret;
  }

  // ---------------------------------------------------------------------
  // 2a. PHASE 1 — TAP TO PAY (phone as reader)
  // ---------------------------------------------------------------------
  Future<void> connectTapToPay() async {
    final terminal = await _getTerminal();

    final discovered = Completer<Reader>();
    late final StreamSubscription sub;
    sub = terminal
        .discoverReaders(const LocalMobileDiscoveryConfiguration(
      isSimulated: AppConfig.simulated,
    ))
        .listen((readers) {
      if (readers.isNotEmpty && !discovered.isCompleted) {
        discovered.complete(readers.first);
      }
    }, onError: (e) {
      if (!discovered.isCompleted) discovered.completeError(e as Object);
    });

    try {
      final reader = await discovered.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception(
            'Tap to Pay setup timed out. Check NFC is on and try again.'),
      );

      _connectedReader = await terminal.connectMobileReader(
        reader,
        locationId: AppConfig.stripeLocationId,
      );
    } finally {
      await sub.cancel();
    }
  }

  // ---------------------------------------------------------------------
  // 3. TAKE A DONATION
  //    Backend creates the PaymentIntent -> SDK collects the tap -> confirm.
  // ---------------------------------------------------------------------
  String getUserFriendlyPaymentError(Object error) {
    if (error is TerminalException) {
      switch (error.code) {
        case TerminalExceptionCode.canceled:
          return 'Payment canceled. Please try again.';
        case TerminalExceptionCode.cardReadTimedOut:
        case TerminalExceptionCode.requestTimedOut:
          return 'Payment timed out. Please try again.';
        case TerminalExceptionCode.cardRemoved:
        case TerminalExceptionCode.cardLeftInReader:
          return 'Card removed too early. Please try again and keep the card in place.';
        case TerminalExceptionCode.cardInsertNotRead:
        case TerminalExceptionCode.cardSwipeNotRead:
          return 'The card could not be read. Please try again.';
        case TerminalExceptionCode.declinedByStripeApi:
        case TerminalExceptionCode.declinedByReader:
          return 'The card was declined. Please try another card.';
        case TerminalExceptionCode.notConnectedToReader:
          return 'Tap to Pay is not connected. Please try again.';
        case TerminalExceptionCode.notConnectedToInternet:
        case TerminalExceptionCode.stripeApiConnectionError:
        case TerminalExceptionCode.connectionTokenProviderError:
          return 'Network error. Please check your internet connection.';
        default:
          return 'Payment failed. Please try again.';
      }
    }

    final lower = error.toString().toLowerCase();
    if (lower.contains('canceled') || lower.contains('cancelled')) {
      return 'Payment canceled. Please try again.';
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Payment timed out. Please try again.';
    }
    if (lower.contains('connection token') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'Payment failed. Please try again.';
  }

  Future<void> takeDonation({required int amountCents}) async {
    final terminal = await _getTerminal();
    if (_connectedReader == null) {
      throw Exception('No reader connected.');
    }

    // Create the PaymentIntent on the backend (amount lives server-side).
    final res = await http.post(
      Uri.parse('${AppConfig.backendUrl}/create_payment_intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amountCents,
        'currency': AppConfig.currency,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to create payment: ${res.body}');
    }
    final clientSecret = (jsonDecode(res.body)
        as Map<String, dynamic>)['client_secret'] as String;

    // Collect the card tap and confirm. Errors (including TerminalException
    // with its typed error code) propagate as-is — callers should translate
    // them with [getUserFriendlyPaymentError].
    var intent = await terminal.retrievePaymentIntent(clientSecret);
    intent = await terminal.collectPaymentMethod(intent);
    await terminal.confirmPaymentIntent(intent);
  }

}
