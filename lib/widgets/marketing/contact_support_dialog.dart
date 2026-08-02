import 'package:flutter/material.dart';

class ContactSupportDialog extends StatelessWidget {
  const ContactSupportDialog({super.key, required this.onContact});

  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Contact support'),
      content: const Text(
        'Tell us what you need and our team will help you choose the right '
        'plan. Email support@dinqlabs.com to continue.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: onContact,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF171717),
          ),
          child: const Text('Email support'),
        ),
      ],
    );
  }
}
