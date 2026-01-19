import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: MarkdownBody(data: _privacyMarkdown),
      ),
    );
  }
}

const String _privacyMarkdown = '''
**Effective Date: 2025.12.15**

# Privacy Policy

DINQ respects your privacy and is committed to protecting the personal data you share with us. This policy describes how we collect, use, and safeguard your information.

## Information We Collect

- Account information (name, email, profile details)
- Usage data and device information
- Content you upload or link to your DINQ card

## How We Use Information

We use your data to operate the platform, personalize your experience, provide support, and improve our services.

## Sharing

We do not sell your personal information. We may share data with service providers to operate DINQ or when required by law.

## Your Rights

You can request access, correction, or deletion of your data by contacting support@dinqlabs.com.
''';

