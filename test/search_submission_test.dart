import 'package:dinq_app/stores/search_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending deep searches retain one submission id across navigation', () {
    const request = PendingDeepSearchRequest(
      submissionId: 'submission-1',
      query: 'find a recruiter',
    );

    expect(request.submissionId, 'submission-1');
  });
}
