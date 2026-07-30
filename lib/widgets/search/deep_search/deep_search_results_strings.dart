/// 与 Web `messages/en/search.json` → `enrich.results.*` 严格对齐的展示文案。
abstract final class DeepSearchResultsStrings {
  DeepSearchResultsStrings._();

  static const empty = 'Candidates will appear here as they are found.';
  static const interrupted =
      'Search stopped. Partial results are preserved.';
  static const searchingNotice =
      'DINQ is searching public sources, verifying evidence, and preparing ranked candidates.';
  static const dismissNotice = 'Dismiss notice';
  static const noFilterMatch =
      'No candidates match the selected source filters.';
  static const showLess = 'Show less';
  static const showMore = 'Show more';
  static const copyResults = 'Copy search results as Markdown';
  static const mobileBack = 'Back to search process';

  static const headerTitle = 'Search results';
  static const headerShare = 'Share';
  static const headerSaveCandidates = 'Save candidates';

  static String headerSaveSelectedCandidates(int count) =>
      count == 1 ? 'Save 1 candidate' : 'Save $count candidates';

  static const toastComingSoon = 'Coming soon';
  static const toastSelectCandidatesFirst = 'Select candidates first';
  static const toastAlreadySaved = 'Selected candidates are already saved';

  static String toastSavedCandidates(int count) =>
      count == 1 ? 'Saved 1 candidate' : 'Saved $count candidates';

  static const viewToggleCard = 'Card view';
  static const viewToggleTable = 'Table view';

  static const exportButton = 'Export';
  static const exportExporting = 'Exporting…';
  static const exportPdfUnavailable =
      'PDF export unavailable for this search';
  static const exportWaitForFinish = 'Wait for the search to finish';
  static const exportFailed = 'Export failed';
  static const toastAddedToFolder = 'Added to folder';
  static const toastRemovedFromShortlist = 'Removed from shortlist';

  static String toastRemovedFromShortlistCount(int count) => count == 1
      ? 'Removed 1 candidate from shortlist'
      : 'Removed $count candidates from shortlist';

  static const filtersClear = 'Clear';

  static const columnGroup = 'Group';
  static const columnCandidate = 'Candidate';
  static const columnName = 'Name';
  static const columnMatch = 'Match';
  static const columnCompany = 'Company';
  static const columnTitle = 'Title';
  static const columnMatchReason = 'Match Reason';
  static const columnProfile = 'Profile';

  static const bookmarkAdd = 'Add to shortlist';
  static const bookmarkRemove = 'Remove from shortlist';
  static const bookmarkAddShort = 'Add';
  static const bookmarkAdded = 'Added';
}
