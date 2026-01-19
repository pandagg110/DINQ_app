import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Terms of Use'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: MarkdownBody(data: _termsMarkdown),
      ),
    );
  }
}

const String _termsMarkdown = '''
**Effective Date: 2025.12.15**

# Terms of Use

These Terms of Use (the "Terms", and together with any applicable Supplemental Terms, the "Agreement") govern the relationship between **Lemma Labs** ("Company", "we," "us," "our") and the entity or individual ("User," "you," "your") using or accessing DINQ.

PLEASE READ THIS AGREEMENT CAREFULLY. BY ACCESSING OR USING THE SERVICES YOU AGREE TO BE BOUND BY THIS AGREEMENT.

## Introduction

Our mission is to empower professionals to build and showcase their careers through an intelligent, dynamic platform. Our services are designed to promote economic opportunity for our members by enabling you and millions of other professionals to connect, share ideas, learn, and find opportunities in a trusted network.

## Eligibility

You must be at least 18 years old and have the authority to enter into this Agreement.

## Account Registration

You are responsible for the accuracy of your account information and the security of your credentials.

## Subscriptions

If you subscribe to any feature or functionality for a term, your subscription will automatically renew unless you opt out in accordance with the Agreement.

## Privacy

Your use of the Services is subject to the DINQ Privacy Policy.

## Contact

If you have questions about these Terms, please contact support@dinqlabs.com.
''';

