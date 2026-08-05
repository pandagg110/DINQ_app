import 'package:dinq_app/widgets/search/agentic_search_logic.dart';
import 'package:dinq_app/widgets/search/deep_search/deep_search_models.dart';
import 'package:dinq_app/widgets/search/search_panel/result_entry_card.dart';
import 'package:flutter_test/flutter_test.dart';

AgenticMessageGroup _group({
  String query = 'Find AI talents',
  String? displayQuery,
  DeepSearchRoundStatus status = DeepSearchRoundStatus.searching,
  List<Map<String, dynamic>> candidates = const [],
  int toolCount = 0,
}) {
  final group = AgenticMessageGroup(
    id: 1,
    userQuery: query,
    loading: status == DeepSearchRoundStatus.searching,
    candidates: candidates,
    searchType: 'global',
    searchCompleted: status == DeepSearchRoundStatus.done,
  );
  group.displayQuery = displayQuery ?? query;
  group.roundStatus = status;
  group.isDeepSearch = true;
  if (toolCount > 0) {
    group.contentBlocks = List.generate(
      toolCount,
      (i) => ToolCallPart(
        ToolCallBlock(
          id: 'tool-$i',
          name: 'search_people',
          input: const {},
          status: ToolCallStatus.running,
          startedAt: 0,
        ),
      ),
    );
  }
  return group;
}

void main() {
  group('groupHasResultWorkspaceRound', () {
    test('background-only searching round is not a result workspace', () {
      final group = _group();

      expect(groupHasResultWorkspaceRound(group), isFalse);
      expect(
        groupHasResultWorkspace(
          group,
          isSearching: true,
          backgroundProcessing: true,
        ),
        isTrue,
        reason: 'RoundSection card may still use backgroundProcessing once '
            'result-entry mode is already active',
      );
    });

    test('start-search marker while searching opens result workspace', () {
      final group = _group(displayQuery: 'Start search');
      expect(groupHasResultWorkspaceRound(group), isTrue);
    });

    test('tool calls while searching open result workspace', () {
      final group = _group(toolCount: 1);
      expect(groupHasResultWorkspaceRound(group), isTrue);
    });

    test('candidates open result workspace', () {
      final group = _group(
        status: DeepSearchRoundStatus.done,
        candidates: [
          {'name': 'Ada', 'row_id': '1'},
        ],
      );
      expect(groupHasResultWorkspaceRound(group), isTrue);
    });
  });
}
