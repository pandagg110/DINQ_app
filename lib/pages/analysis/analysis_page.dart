import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/top_talents_service.dart';
import '../../widgets/layout/app_header.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final TopTalentsService _service = TopTalentsService();
  final TextEditingController _searchController = TextEditingController();
  AnalysisTab _selected = AnalysisTab.scholar;
  bool _isLoading = false;
  List<dynamic> _talents = [];

  @override
  void initState() {
    super.initState();
    _fetchTalents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(showAuthButtons: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DINQ Analysis', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Discover AI talent insights across Scholar, GitHub, and LinkedIn.'),
                  const SizedBox(height: 24),
                  _buildSearchBar(context),
                  const SizedBox(height: 16),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _talents.map((item) => _PeopleCard(data: item)).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search a scholar, GitHub user, or LinkedIn profile',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) => _search(value),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _search(_searchController.text),
          child: const Text('Analyze'),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      children: AnalysisTab.values.map((tab) {
        final isActive = _selected == tab;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(tab.label),
            selected: isActive,
            onSelected: (_) => _selectTab(tab),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectTab(AnalysisTab tab) async {
    setState(() => _selected = tab);
    await _fetchTalents();
  }

  Future<void> _fetchTalents() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> response;
      switch (_selected) {
        case AnalysisTab.github:
          response = await _service.getGitHubTalents(count: 3);
          break;
        case AnalysisTab.linkedin:
          response = await _service.getLinkedInTalents(count: 3);
          break;
        case AnalysisTab.scholar:
          response = await _service.getScholarTalents(count: 3);
          break;
      }
      _talents = response['talents'] as List<dynamic>? ?? [];
    } catch (_) {
      _talents = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _search(String input) {
    final value = input.trim();
    if (value.isEmpty) return;
    switch (_selected) {
      case AnalysisTab.github:
        context.go('/analysis/github?user=$value');
        break;
      case AnalysisTab.linkedin:
        context.go('/analysis/linkedin?user=$value');
        break;
      case AnalysisTab.scholar:
        context.go('/analysis/scholar?user=$value');
        break;
    }
  }
}

enum AnalysisTab { scholar, github, linkedin }

extension AnalysisTabExtension on AnalysisTab {
  String get label {
    switch (this) {
      case AnalysisTab.scholar:
        return 'Scholar';
      case AnalysisTab.github:
        return 'GitHub';
      case AnalysisTab.linkedin:
        return 'LinkedIn';
    }
  }
}

class _PeopleCard extends StatelessWidget {
  const _PeopleCard({required this.data});

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    final map = data as Map<String, dynamic>;
    final name = map['name']?.toString() ?? 'Talent';
    final image = map['image']?.toString() ?? map['photo_url']?.toString();
    final title = map['position']?.toString() ?? map['title']?.toString() ?? '';
    final org = map['institution']?.toString() ?? map['company']?.toString() ?? '';

    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: image != null ? NetworkImage(image) : null,
            backgroundColor: const Color(0xFFE5E5E5),
            child: image == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (title.isNotEmpty) Text(title, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          if (org.isNotEmpty) Text(org, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        ],
      ),
    );
  }
}

