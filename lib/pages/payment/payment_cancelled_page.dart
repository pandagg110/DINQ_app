import 'package:flutter/material.dart';

import '../../services/subscription_pricing_navigation.dart';

class PaymentCancelledPage extends StatelessWidget {
  const PaymentCancelledPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel, size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('Payment cancelled', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your payment was not completed.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => openSubscriptionPricing(
                context,
                mode: SubscriptionPricingNavigationMode.go,
              ),
              child: const Text('Return to Pricing'),
            ),
          ],
        ),
      ),
    );
  }
}
