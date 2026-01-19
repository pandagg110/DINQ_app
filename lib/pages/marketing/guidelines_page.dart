import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

class GuidelinesPage extends StatelessWidget {
  const GuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Community Guidelines'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: MarkdownBody(data: _guidelinesMarkdown),
      ),
    );
  }
}

const String _guidelinesMarkdown = '''
# Community Guidelines

DINQ is built for professionals and builders. Please help us keep the community respectful and constructive.

## Be authentic

Share work and achievements that represent your real experience.

## Be respectful

Harassment, hate speech, and discriminatory behavior are not tolerated.

## Protect privacy

Do not publish sensitive information about yourself or others without consent.

## Use the platform responsibly

Avoid spam, misleading content, or unauthorized automation.

If you see content that violates these guidelines, contact support@dinqlabs.com.
''';

