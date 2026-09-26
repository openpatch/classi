typedef StudentDraft = ({
  String firstName,
  String lastName,
  String? callName,
  String? originNote,
  String? avatarJson,
});

/// A student as a WebUntis class register describes them.
///
/// Separate from [StudentDraft] on purpose: a WebUntis import always carries
/// an id and never a call name, avatar or origin note, while the form and the
/// text importers carry those and never an id.
typedef WebUntisStudentDraft = ({
  String firstName,
  String lastName,
  int webuntisStudentId,
});

/// What an import of a WebUntis class register changed.
///
/// [linked] counts students that already existed in the group by name and only
/// gained their WebUntis id, which is what makes attendance sync work for a
/// group that was typed in by hand first.
typedef WebUntisRosterImportResult = ({int added, int linked, int skipped});
