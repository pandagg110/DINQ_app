import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

class CookiesPage extends StatelessWidget {
  const CookiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Cookie Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: MarkdownBody(data: _cookiesMarkdown),
      ),
    );
  }
}

const String _cookiesMarkdown = '''
# Cookie Policy

DINQ uses cookies and similar technologies to provide, secure, and improve our services.

## What are cookies?

Cookies are small text files stored on your device that help websites remember information about your visit.

## How we use cookies

- Authentication and session management
- Preference and settings storage
- Analytics and performance monitoring

You can control cookies through your browser settings. Disabling cookies may impact the functionality of DINQ.
''';

