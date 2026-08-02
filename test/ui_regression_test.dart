import 'package:dinq_app/models/shortlist_models.dart';
import 'package:dinq_app/pages/shortlist/widgets/shortlist_candidate_card.dart';
import 'package:dinq_app/pages/splash_page.dart';
import 'package:dinq_app/stores/search_store.dart';
import 'package:dinq_app/stores/shortlist_store.dart';
import 'package:dinq_app/widgets/search/search_box/search_box_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('shortlist enrich cache keys use the unique favorite id', () {
    final item = FavoriteItem(
      id: 'favorite-keith',
      projectId: 'project-1',
      title: 'Keith',
      field: const {
        'row_id': 'reused-search-row-0',
        'name': 'Keith',
        'profile_url': 'https://dinq.me/keith',
      },
      tags: '',
      status: 'not_obtained',
    );

    expect(item.toEnrichRow()['row_id'], 'favorite-keith');
  });

  testWidgets('mobile search prompt asks users to search for talent', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SearchStore(),
        child: const MaterialApp(
          home: Scaffold(body: SearchBoxWidget(isMobile: true)),
        ),
      ),
    );

    expect(find.text('Search for talent'), findsOneWidget);
    expect(find.text('Ask'), findsNothing);
  });

  testWidgets('shortlist cards do not show acquisition status', (tester) async {
    final store = ShortlistStore();
    addTearDown(store.dispose);
    final item = FavoriteItem(
      id: 'favorite-1',
      projectId: 'project-1',
      title: 'Ada Lovelace',
      field: const {'name': 'Ada Lovelace', 'title': 'Engineer'},
      tags: '',
      status: 'not_obtained',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShortlistCandidateCard(
            item: item,
            store: store,
            selectionMode: false,
            isSelected: false,
            onTap: () {},
            onLongPress: () {},
            onToggleSelect: () {},
          ),
        ),
      ),
    );

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Not obtained'), findsNothing);
  });

  testWidgets('first-install splash completes once after its display delay', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(home: SplashPage(onComplete: () => completions++)),
    );

    await tester.pump(const Duration(milliseconds: 1199));
    expect(completions, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(completions, 1);
  });
}
