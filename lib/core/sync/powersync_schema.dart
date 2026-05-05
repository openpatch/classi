import 'package:powersync/powersync.dart';

/// PowerSync schema definition for all syncable tables.
///
/// Each table here mirrors the corresponding Drift table definition with
/// snake_case column names. The `id` column is always TEXT (UUID) and is
/// managed by the PowerSync runtime.
///
/// DateTime columns are stored as INTEGER (milliseconds since epoch, consistent
/// with Drift's default DateTime serialization).
/// Boolean columns are stored as INTEGER (0 or 1).
const classiSchema = Schema([
  Table('groups_table', [
    Column.text('name'),
    Column.text('color_hex'),
    Column.text('grade_scale_json'),
    Column.text('grade_categories_json'),
    Column.integer('created_at'),
    Column.integer('archived_at'),
  ]),
  Table('students_table', [
    Column.text('first_name'),
    Column.text('last_name'),
    Column.text('group_id'),
    Column.text('origin_note'),
    Column.integer('created_at'),
    Column.text('avatar_json'),
    Column.integer('seat_index'),
  ]),
  Table('grade_entries_table', [
    Column.text('student_id'),
    Column.integer('date'),
    Column.text('session_label'),
    Column.text('value'),
    Column.text('category_id'),
    Column.text('category_name'),
    Column.integer('created_at'),
  ]),
  Table('material_logs_table', [
    Column.text('student_id'),
    Column.integer('date'),
    Column.integer('had_material'),
    Column.integer('created_at'),
  ]),
  Table('homework_logs_table', [
    Column.text('student_id'),
    Column.integer('date'),
    Column.integer('had_homework'),
    Column.integer('created_at'),
  ]),
  Table('attendance_logs_table', [
    Column.text('student_id'),
    Column.integer('date'),
    Column.integer('created_at'),
  ]),
  Table('lists_table', [
    Column.text('group_id'),
    Column.text('name'),
    Column.integer('created_at'),
    Column.integer('archived_at'),
  ]),
  Table('list_items_table', [
    Column.text('list_id'),
    Column.text('student_id'),
    Column.text('student_ids_json'),
    Column.text('label'),
    Column.integer('checked_at'),
    Column.integer('created_at'),
  ]),
  Table('notes_table', [
    Column.text('body'),
    Column.text('group_id'),
    Column.text('student_id'),
    Column.text('student_ids_json'),
    Column.integer('is_todo'),
    Column.integer('todo_done'),
    Column.integer('todo_done_at'),
    Column.integer('created_at'),
    Column.integer('archived_at'),
  ]),
]);
