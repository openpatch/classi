/// Indexes for every foreign key and date column the app filters on.
///
/// Until schema version 25 the database had no indexes at all, so every lookup
/// by group, by student or by date was a full table scan, and every cascading
/// delete scanned each child table. The statements are `IF NOT EXISTS` and are
/// run both from `onCreate` (fresh libraries) and from the version 25 migration
/// step (existing ones), so the two paths cannot drift apart.
///
/// Naming: `idx_<table>_<columns>`.
const List<String> databaseIndexStatements = [
  // Students are always read through their group.
  'CREATE INDEX IF NOT EXISTS idx_students_group_id '
      'ON students_table (group_id)',

  // A WebUntis attendance sync looks students up by their WebUntis id.
  'CREATE INDEX IF NOT EXISTS idx_students_webuntis_student_id '
      'ON students_table (webuntis_student_id)',

  // Groups are listed per school year.
  'CREATE INDEX IF NOT EXISTS idx_groups_school_year_id '
      'ON groups_table (school_year_id)',

  // Grade entries are read per student, per day, and aggregated per category.
  'CREATE INDEX IF NOT EXISTS idx_grade_entries_student_id_date '
      'ON grade_entries_table (student_id, date)',
  'CREATE INDEX IF NOT EXISTS idx_grade_entries_date '
      'ON grade_entries_table (date)',
  'CREATE INDEX IF NOT EXISTS idx_grade_entries_category_id '
      'ON grade_entries_table (category_id)',

  // The three participation logs are all read by (student, date) and swept by
  // date range for a timeframe.
  'CREATE INDEX IF NOT EXISTS idx_attendance_logs_student_id_date '
      'ON attendance_logs_table (student_id, date)',
  'CREATE INDEX IF NOT EXISTS idx_attendance_logs_date '
      'ON attendance_logs_table (date)',
  'CREATE INDEX IF NOT EXISTS idx_homework_logs_student_id_date '
      'ON homework_logs_table (student_id, date)',
  'CREATE INDEX IF NOT EXISTS idx_homework_logs_date '
      'ON homework_logs_table (date)',
  'CREATE INDEX IF NOT EXISTS idx_material_logs_student_id_date '
      'ON material_logs_table (student_id, date)',
  'CREATE INDEX IF NOT EXISTS idx_material_logs_date '
      'ON material_logs_table (date)',

  // Sessions drive the timetable and lesson mode.
  'CREATE INDEX IF NOT EXISTS idx_sessions_group_id_date '
      'ON sessions_table (group_id, date)',

  // The weekly timetable reads every group's slots.
  'CREATE INDEX IF NOT EXISTS idx_lesson_slots_group_id '
      'ON lesson_slots_table (group_id)',

  // Notes and checklists filter by group.
  'CREATE INDEX IF NOT EXISTS idx_notes_group_id ON notes_table (group_id)',
  'CREATE INDEX IF NOT EXISTS idx_notes_student_id ON notes_table (student_id)',
  'CREATE INDEX IF NOT EXISTS idx_lists_group_id ON lists_table (group_id)',
  'CREATE INDEX IF NOT EXISTS idx_list_items_list_id '
      'ON list_items_table (list_id)',
  'CREATE INDEX IF NOT EXISTS idx_list_items_student_id '
      'ON list_items_table (student_id)',

  // Seating plans.
  'CREATE INDEX IF NOT EXISTS idx_seating_plans_group_id '
      'ON seating_plans_table (group_id)',
  'CREATE INDEX IF NOT EXISTS idx_seating_plan_positions_plan_id '
      'ON seating_plan_positions_table (seating_plan_id)',
  'CREATE INDEX IF NOT EXISTS idx_seating_plan_positions_student_id '
      'ON seating_plan_positions_table (student_id)',

  // Timeframes hang off a school year, their grades off a timeframe.
  'CREATE INDEX IF NOT EXISTS idx_timeframes_school_year_id '
      'ON timeframes_table (school_year_id)',
  'CREATE INDEX IF NOT EXISTS idx_timeframe_grades_timeframe_id '
      'ON timeframe_grades_table (timeframe_id)',
  'CREATE INDEX IF NOT EXISTS idx_timeframe_grades_student_id '
      'ON timeframe_grades_table (student_id)',
];
