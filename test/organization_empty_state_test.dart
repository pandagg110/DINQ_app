import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('organization empty states span the content width for centering', () {
    final source = File(
      'lib/pages/me/organization_detail_page.dart',
    ).readAsStringSync();

    final emptyStateMethod = RegExp(
      r'Widget _emptyState\(IconData icon, String text\) \{([\s\S]*?)\n  \}',
    ).firstMatch(source);

    expect(emptyStateMethod, isNotNull);
    expect(emptyStateMethod!.group(1), contains('width: double.infinity'));
  });
}
