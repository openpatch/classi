/// The order the lists screen puts checklists in.
enum ListSortField {
  /// Alphabetical, the way the app has always shown them.
  name,

  /// Newest first, for a list made minutes ago that is not called "A…".
  newest,

  /// Last worked on first: whatever was ticked off or added to most recently
  /// is what a teacher usually reaches for again.
  recentlyUsed,
}

extension ListSortFieldPersistence on ListSortField {
  String get storageValue => switch (this) {
    ListSortField.name => 'name',
    ListSortField.newest => 'newest',
    ListSortField.recentlyUsed => 'recently_used',
  };

  static ListSortField fromStorage(String? value) {
    return switch (value) {
      'newest' => ListSortField.newest,
      'recently_used' => ListSortField.recentlyUsed,
      _ => ListSortField.name,
    };
  }
}

/// The order a list's own entries are shown in.
enum ListItemSortField {
  /// The order they were written in, which is the order a teacher typed them.
  entered,

  /// Alphabetical by what the entry says.
  label,

  /// By the student an entry is about, in the app's student order. Entries
  /// about nobody in particular follow, in the order they were written.
  student,

  /// Still to do first, ticked off at the bottom, each in the order entered.
  openFirst,
}

extension ListItemSortFieldPersistence on ListItemSortField {
  String get storageValue => switch (this) {
    ListItemSortField.entered => 'entered',
    ListItemSortField.label => 'label',
    ListItemSortField.student => 'student',
    ListItemSortField.openFirst => 'open_first',
  };

  static ListItemSortField fromStorage(String? value) {
    return switch (value) {
      'label' => ListItemSortField.label,
      'student' => ListItemSortField.student,
      'open_first' => ListItemSortField.openFirst,
      _ => ListItemSortField.entered,
    };
  }
}
