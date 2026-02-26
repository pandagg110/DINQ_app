import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recommendation_models.dart' as rec;
import '../../stores/user_store.dart';
import '../../widgets/discover/recommended_papers_widget.dart';
import 'paper_filters_page.dart';

/// Recommended Papers 页：类似 ChatHistoryPage，单独页面打开
class RecommendedPapersPage extends StatefulWidget {
  const RecommendedPapersPage({super.key});

  @override
  State<RecommendedPapersPage> createState() => _RecommendedPapersPageState();
}

class _RecommendedPapersPageState extends State<RecommendedPapersPage> {
  rec.PaperFiltersState _filters = rec.PaperFiltersState();

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final userId = userStore.user?.user.id;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF171717)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'PAPERS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF171717),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/discover/settings.png',
              width: 24,
              height: 24,
              color: const Color(0xFF171717),
            ),
            onPressed: () async {
              final result = await Navigator.of(context).push<rec.PaperFiltersState>(
                MaterialPageRoute(
                  builder: (context) => PaperFiltersPage(initialFilters: _filters),
                ),
              );
              if (result != null && mounted) {
                setState(() => _filters = result);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RecommendedPapersWidget(
          userId: userId,
          isFullView: true,
          initialFilters: _filters,
          onFiltersChanged: (f) => setState(() => _filters = f),
          onBack: () => Navigator.of(context).pop(),
          onSearchAuthorAndBack: (query) => Navigator.of(context).pop(query),
        ),
      ),
    );
  }
}
