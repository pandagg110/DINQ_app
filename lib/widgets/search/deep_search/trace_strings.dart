/// 与 Web `messages/en/search.json` → `trace.*` 严格对齐的展示文案。
abstract final class TraceStrings {
  TraceStrings._();

  // trace.agent.*
  static const search = 'Search';
  static const searching = 'Searching';
  static const searchComplete = 'Search complete';
  static const searchFailed = 'Search failed';
  static const initializing = 'Initializing';
  static const initializingEllipsis = 'Initializing…';

  static String agentFound(int count) =>
      count == 1 ? '1 found' : '$count found';

  static String multiFinished(int count) => '$count Search agents finished';

  static String multiRunning(int count) => 'Running $count Search agents';

  static const multiInitializing = 'Initializing Search agents';

  static String chainSubtitle(int found, int toolCount) =>
      '${agentFound(found)} · ${toolCountLabel(toolCount)}';

  // trace.tool.*
  static const submittedCandidates = 'Submitted candidates';
  static const preparingToolsEllipsis = 'Preparing tools…';

  static String toolCountLabel(int count) =>
      count == 1 ? '1 tool' : '$count tools';

  static String toolUses(int count) =>
      count == 1 ? '1 tool use' : '$count tool uses';

  // trace.thinking.*
  static const thought = 'Thought';

  static String thoughtForDuration(String duration) => 'Thought for $duration';

  // trace.thinkingMessages.*
  static const thinkingMessages = [
    'Strategizing',
    'Brewing a plan',
    'Connecting the dots',
    'Crunching signals',
    'Let me cook',
  ];

  // trace.searchingMessages.*
  static const searchingMessages = [
    'Scouting talent',
    'Digging deeper',
    'Exploring leads',
    'Mining the web',
    'Scanning networks',
    'Following the trail',
    'Going down the rabbit hole',
    'Pulling threads',
    'Vibing with data',
    'Almost there',
  ];

  // trace.sourceMeta.*
  static const sourceAcademic = 'Academic databases';
  static const sourceTechTalent = 'Tech talent platforms';
  static const sourceWebIntel = 'Web intelligence';
  static const sourceDefault = 'Source';

  static String sourceLabelForAgentName(String name) {
    switch (name) {
      case 'academic-search':
        return sourceAcademic;
      case 'tech-talent-search':
        return sourceTechTalent;
      case 'web-intelligence':
        return sourceWebIntel;
      default:
        return sourceDefault;
    }
  }

  // trace.groupLabel.*
  static const groupPreparingTools = 'Preparing tools';
  static const groupSubmittingCandidates = 'Submitting candidates';
  static const groupSearchingTalentSources = 'Searching talent sources';
  static const groupSearchingTechnicalProfiles = 'Searching technical profiles';
  static const groupSearchingWebSources = 'Searching web sources';
  static const groupRunningTools = 'Running tools';

  static String groupLabelForKey(String key) {
    switch (key) {
      case 'preparingTools':
        return groupPreparingTools;
      case 'submittingCandidates':
        return groupSubmittingCandidates;
      case 'searchingTalentSources':
        return groupSearchingTalentSources;
      case 'searchingTechnicalProfiles':
        return groupSearchingTechnicalProfiles;
      case 'searchingWebSources':
        return groupSearchingWebSources;
      case 'runningTools':
        return groupRunningTools;
      default:
        return groupRunningTools;
    }
  }
}
