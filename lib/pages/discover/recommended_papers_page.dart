import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/user_store.dart';
import '../../widgets/discover/recommended_papers_widget.dart';

/// Recommended Papers 页：类似 ChatHistoryPage，单独页面打开
class RecommendedPapersPage extends StatelessWidget {
  const RecommendedPapersPage({super.key});

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
      ),
      body: SafeArea(
        child: RecommendedPapersWidget(
          userId: userId,
          isFullView: true,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
