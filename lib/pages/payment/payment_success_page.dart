import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            const Text('Payment successful', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your subscription has been activated.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/admin/mydinq'),
              child: const Text('Go to My DINQ'),
            ),
          ],
        ),
      ),
    );
  }
}

