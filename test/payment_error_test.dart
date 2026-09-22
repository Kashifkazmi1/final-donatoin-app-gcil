import 'package:gcil_donation_app/services/terminal_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('payment error handling', () {
    test('maps canceled errors to a friendly message', () {
      final message = TerminalService.instance.getUserFriendlyPaymentError(
        'TerminalException: canceled — Contactless transaction was canceled',
      );

      expect(message, 'Payment canceled. Please try again.');
    });

    test('maps timeout errors to a friendly message', () {
      final message = TerminalService.instance.getUserFriendlyPaymentError(
        'Timed out while waiting for payment confirmation',
      );

      expect(message, 'Payment timed out. Please try again.');
    });

    test('maps network errors to a friendly message', () {
      final message = TerminalService.instance.getUserFriendlyPaymentError(
        'SocketException: Failed host lookup: api.stripe.com',
      );

      expect(message, 'Network error. Please check your internet connection.');
    });

    test('returns a generic fallback for unknown errors', () {
      final message = TerminalService.instance.getUserFriendlyPaymentError(
        'Unexpected failure',
      );

      expect(message, 'Payment failed. Please try again.');
    });
  });

}
