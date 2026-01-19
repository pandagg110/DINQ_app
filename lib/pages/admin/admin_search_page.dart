import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/search_store.dart';
import '../../widgets/layout/app_header.dart';

class AdminSearchPage extends StatefulWidget {
  const AdminSearchPage({super.key});

  @override
  State<AdminSearchPage> createState() => _AdminSearchPageState();
}

class _AdminSearchPageState extends State<AdminSearchPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SearchStore>();

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(showAuthButtons: true),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Discover Talent', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search AI-native talent',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (value) {
                      store.triggerSearch(value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  if (store.pendingQuery != null)
                    Text('Results for "${store.pendingQuery}"', style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: store.openTabs.length,
                      itemBuilder: (context, index) {
                        final tab = store.openTabs[index];
                        return ListTile(
                          title: Text(tab.candidate['name']?.toString() ?? 'Candidate'),
                          subtitle: Text(tab.candidate['title']?.toString() ?? 'Profile overview'),
                          onTap: () => store.setActiveTab(tab.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

