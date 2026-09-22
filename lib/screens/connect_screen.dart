import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/terminal_service.dart';
import 'donation_screen.dart';

/// First screen for the Tap to Pay donation flow.
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _connecting = false;
  String? _error;

  Future<void> _connectTapToPay() async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      await [Permission.locationWhenInUse].request();
      await TerminalService.instance.connectTapToPay();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DonationScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(Icons.volunteer_activism, size: 72, color: scheme.primary),
              const SizedBox(height: 20),
              Text(
                'Set up donations',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to accept card payments.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _connecting ? null : _connectTapToPay,
                icon: _connecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.nfc),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(_connecting ? 'Setting up Tap to Pay…' : 'Tap to Pay'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
