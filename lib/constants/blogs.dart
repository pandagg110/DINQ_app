class BlogMeta {
  const BlogMeta({
    required this.slug,
    required this.title,
    required this.description,
    required this.date,
    required this.author,
    required this.cover,
    required this.tags,
  });

  final String slug;
  final String title;
  final String description;
  final String date;
  final String author;
  final String cover;
  final List<String> tags;
}

const List<BlogMeta> BLOG_LIST = [
  BlogMeta(
    slug: 'ai-tsb',
    title: 'AI Talent Search Benchmark',
    description:
        'Evaluating AI Agents on their ability to search, verify, and reason about human talent data across the web.',
    date: '2026-01-06',
    author: 'DINQ Team',
    cover:
        'https://assets.dinq.me/uploads/pdfs/c38091b5-9b0b-4162-9cd2-b95c93209bce/1767024228_Gemini_Generated_Image_qinoxpqinoxpqino.png',
    tags: ['AI Talent Search', 'Benchmark'],
  ),
];

