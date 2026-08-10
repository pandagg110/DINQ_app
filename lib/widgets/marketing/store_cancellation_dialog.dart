import 'package:flutter/material.dart';

import '../../services/store_cancellation_flow.dart';
import '../common/base_page.dart';

class StoreCancellationDialog extends StatelessWidget {
  const StoreCancellationDialog({
    super.key,
    required this.copy,
    required this.onCancel,
    required this.onContinue,
  });

  final StoreCancellationCopy copy;
  final VoidCallback onCancel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              copy.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF525252),
                fontFamily: 'Geist',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            NormalButton(
              onTap: onContinue,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  copy.continueLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            NormalButton(
              onTap: onCancel,
              child: const SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'Cancel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B6862),
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreCancellationNotice extends StatelessWidget {
  const StoreCancellationNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          height: 1.45,
          color: Color(0xFF1E3A5F),
          fontFamily: 'Geist',
        ),
      ),
    );
  }
}
