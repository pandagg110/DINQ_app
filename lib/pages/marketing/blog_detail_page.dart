import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../constants/blogs.dart';
import '../../widgets/layout/app_footer.dart';
import '../../widgets/layout/app_header.dart';

class BlogDetailPage extends StatelessWidget {
  const BlogDetailPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final meta = BLOG_LIST.firstWhere((item) => item.slug == slug, orElse: () => BLOG_LIST.first);

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(showAuthButtons: true),
          Expanded(
            child: FutureBuilder<String>(
              future: _loadMarkdown(context, slug),
              builder: (context, snapshot) {
                final content = snapshot.data ?? 'Loading...';
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meta.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${meta.author} • ${meta.date}', style: const TextStyle(color: Color(0xFF6B7280))),
                      const SizedBox(height: 16),
                      MarkdownBody(data: content),
                      const SizedBox(height: 24),
                      const AppFooter(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/blogs'),
        child: const Icon(Icons.arrow_back),
      ),
    );
  }

  Future<String> _loadMarkdown(BuildContext context, String slug) async {
    final asset = 'assets/blogs/$slug.md';
    return DefaultAssetBundle.of(context).loadString(asset);
  }
}

