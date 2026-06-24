/// 对齐 Web `messages/en/shortlist.json`。
abstract final class ShortlistStrings {
  static const headerTitle = 'Shortlist';
  static const headerBackToMy = 'Back to My';
  static const viewToggleCard = 'Card view';
  static const viewToggleTable = 'Table view';

  static const foldersTitle = 'Folders';
  static const foldersClose = 'Close';
  static const foldersCloseAria = 'Close folders';
  static const foldersOpenAria = 'Open folders';
  static const foldersDefaultName = 'Default';
  static const foldersUnknown = 'Unknown folder';

  static const searchPlaceholder = 'Search keyword (fuzzy)';
  static const statusLabel = 'Status';
  static const statusAll = 'All';
  static const exportLabel = 'Export';
  static const exportingLabel = 'Exporting';

  static String statusLabelFor(String status) => switch (normalizeStatusKey(status)) {
        'email_obtained' => statusEmailObtained,
        'contacted' => statusContacted,
        _ => statusNotObtained,
      };

  static const statusNotObtained = 'Not obtained';
  static const statusEmailObtained = 'Email obtained';
  static const statusContacted = 'Contacted';

  static String selectionCount(int count) => '$count selected';
  static const selectionCancel = 'Cancel';
  static const selectionDelete = 'Delete';
  static const selectionMove = 'Move';

  static const loadingFolders = 'Loading folders...';

  static const emptyNoFoldersTitle = 'No folders available';
  static const emptyNoFoldersDescription =
      'Refresh the page or create a folder to continue.';
  static const emptyNoMatchesTitle = 'No matches';
  static const emptyNoMatchesDescription =
      'Try a different keyword or status, or reset to see more.';
  static const emptyNoMatchesReset = 'Reset filters';
  static const emptyNoFavoritesTitle = 'This folder is empty';
  static const emptyNoFavoritesDescription =
      'Bookmark candidates into this folder, or switch to another.';

  static const tableNewBadge = 'NEW';
  static const rowActionsAdded = 'Added';
  static const rowActionsRemove = 'Remove';

  static const cardRemove = 'Remove';
  static String cardRemoveAria(String name) => 'Remove $name from shortlist';
  static const cardRemoveConfirm = 'Remove?';
  static const cardConfirmYes = 'Yes';
  static const cardConfirmNo = 'No';
  static const cardTagRemoveTitle = 'Remove tag';
  static const cardTagCollapse = 'Collapse tags';
  static const cardTagNewPlaceholder = 'New tag';
  static const cardTagAdd = 'Tag';

  static const moveFolderTitle = 'Change folder';
  static const moveFolderCurrentFolder = 'Current folder';
  static String moveFolderPrompt(int count) =>
      count == 1 ? 'Move 1 favorite to:' : 'Move $count favorites to:';
  static const moveFolderNoOtherFolders = 'No other folders';

  static const defaultCandidate = 'this candidate';

  static String bulkRemoveTitle(int count) => count == 1
      ? 'Remove 1 candidate from shortlist?'
      : 'Remove $count candidates from shortlist?';
  static const bulkRemoveMessage = 'This action cannot be undone.';
  static const bulkRemoveConfirm = 'Remove';

  static String singleRemoveTitle(String name) => 'Remove $name from shortlist?';
  static const singleRemoveMessage = 'This action cannot be undone.';
  static const singleRemoveConfirm = 'Remove';

  static String bulkMoveTitle(int count, String target) => count == 1
      ? 'Move 1 favorite to "$target"?'
      : 'Move $count favorites to "$target"?';
  static const bulkMoveConfirm = 'Move';

  static String bulkRemovePartial(int ok, int total, int fail) =>
      'Removed $ok of $total. $fail failed.';
  static String bulkRemoveSuccess(int count) =>
      count == 1 ? 'Removed 1 candidate' : 'Removed $count candidates';
  static String removeSuccess(String name) => 'Removed $name';
  static const removeError = 'Failed to remove';
  static String bulkMovePartial(int ok, int total, int fail) =>
      'Moved $ok of $total. $fail failed.';
  static String bulkMoveSuccess(int count, String target) => count == 1
      ? 'Moved 1 favorite to $target'
      : 'Moved $count favorites to $target';

  static const exportNoFolder = 'Select a folder before exporting';
  static const exportEmpty = 'No candidates to export';
  static String exportPdfLimit(int max) =>
      'PDF export supports up to $max candidates. Narrow the current filters.';
  static String exportSuccess(int count) =>
      count == 1 ? 'Exported 1 candidate' : 'Exported $count candidates';
  static const exportError = 'Export failed';

  static const enrichFailed = 'Enrich failed';
  static const loadFoldersTitle = 'Could not load folders';
  static const loadFoldersDescription =
      'Check your connection and try again.';
  static const loadFoldersRetry = 'Retry';

  static const projectCreateFolder = 'Create Folder';
  static const projectLoading = 'Loading…';
  static const projectRetryLoad = 'Retry loading folders';
  static const projectDefaultProject = 'Default';
  static const projectNamePlaceholder = 'Folder name';
  static String projectDeleteConfirm(String name) => 'Delete "$name"?';
  static const projectConfirm = 'Confirm';
  static const projectCancel = 'Cancel';
  static const projectConfirmDelete = 'Confirm delete';
  static const projectRename = 'Rename';
  static const projectDelete = 'Delete';
  static String projectMoreActions(String name) => 'More actions for $name';
  static const projectCreated = 'Folder created';
  static const projectRenamed = 'Folder renamed';
  static const projectDeleted = 'Folder deleted';

  static const exportModalTitle = 'Export shortlist';
  static const exportModalSubtitle = 'Choose a format to download.';
  static const exportModalClose = 'Close';
  static const exportCsvLabel = 'CSV';
  static const exportCsvDescription =
      'Spreadsheet-friendly, best for re-import or analysis.';
  static const exportPdfLabel = 'PDF';
  static const exportPdfDescription =
      'Print-ready document with current layout.';

  static const confirmModalConfirm = 'Confirm';
  static const confirmModalCancel = 'Cancel';

  static String normalizeStatusKey(String status) {
    if (status == 'email_obtained' || status == 'contacted') return status;
    return 'not_obtained';
  }
}
