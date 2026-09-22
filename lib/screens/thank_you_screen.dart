import 'dart:async';

import 'package:flutter/material.dart';

/// Shown after a successful donation. Auto-returns to the donation
/// screen after a few seconds so the next donor can step up.
class ThankYouScreen extends StatefulWidget {
  const ThankYouScreen({super.key, required this.amount});

  final int amount;

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 6), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite, size: 72, color: scheme.onPrimary),
              ),
              const SizedBox(height: 28),
              Text(
                'Thank you!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your \$${widget.amount} donation was received.',
                style: TextStyle(
                  fontSize: 17,
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: Text('Make Another Donation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
