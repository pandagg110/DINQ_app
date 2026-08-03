import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Search bottom navigation uses magnifier icons', () {
    final navigationSource = File(
      'lib/pages/main_tab/main_tab_bottom_view.dart',
    ).readAsStringSync();

    final searchModel = RegExp(
      r'MainTabModel\(\s*'
      r'pageType:\s*MainTabType\.search,\s*'
      r'title:\s*"Search",\s*'
      r'iconName:\s*"",\s*'
      r'selIconName:\s*"",\s*'
      r'iconSvg:\s*"assets/icons/nav-search-outline\.svg",\s*'
      r'selIconSvg:\s*"assets/icons/nav-search-fill\.svg",\s*'
      r'\)',
    );

    expect(navigationSource, matches(searchModel));

    final outline = File(
      'assets/icons/nav-search-outline.svg',
    ).readAsStringSync();
    final selected = File(
      'assets/icons/nav-search-fill.svg',
    ).readAsStringSync();

    expect(outline, contains('M17 17L21 21'));
    expect(outline, isNot(contains('fill="black"')));
    expect(selected, contains('M17 17L21 21'));
    expect(selected, contains('fill="black"'));
  });
}
