import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/terminal_service.dart';
import 'thank_you_screen.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  static const presets = [25, 50, 75, 100];

  int? _selected; // selected preset in dollars
  final _customCtrl = TextEditingController();
  bool _processing = false;

  int? get _amountDollars {
    if (_customCtrl.text.isNotEmpty) {
      return int.tryParse(_customCtrl.text);
    }
    return _selected;
  }

  Future<void> _donate() async {
    final dollars = _amountDollars;
    if (dollars == null || dollars < 1) return;

    setState(() {
      _processing = true;
    });
    try {
      await TerminalService.instance.takeDonation(amountCents: dollars * 100);
      if (!mounted) return;

      // Reset the form immediately and send the donor to the success screen.
      setState(() {
        _selected = null;
        _customCtrl.clear();
      });
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ThankYouScreen(amount: dollars)),
      );
    } catch (e) {
      final message = TerminalService.instance.getUserFriendlyPaymentError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canDonate = (_amountDollars ?? 0) >= 1 && !_processing;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Make a donation',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Every gift makes a difference.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),

              // Preset amounts — big kiosk-friendly tiles
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.9,
                children: [
                  for (final amount in presets)
                    _AmountTile(
                      amount: amount,
                      selected: _selected == amount && _customCtrl.text.isEmpty,
                      onTap: () {
                        setState(() {
                          _selected = amount;
                          _customCtrl.clear();
                          FocusScope.of(context).unfocus();
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // Custom amount
              TextField(
                controller: _customCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  hintText: 'Custom amount',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onChanged: (_) => setState(() => _selected = null),
              ),

              const Spacer(),
              FilledButton(
                onPressed: canDonate ? _donate : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    _processing
                        ? 'Tap card on phone…'
                        : _amountDollars != null
                            ? 'Donate \$${_amountDollars!}'
                            : 'Select an amount',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final int amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: selected ? 3 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '\$$amount',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
