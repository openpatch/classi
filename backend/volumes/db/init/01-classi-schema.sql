-- Classi database schema for self-hosted Supabase
-- Run this against the Supabase PostgreSQL instance (already handled via volume mount).

-- Groups
create table if not exists groups_table (
  id text primary key,
  name text not null,
  color_hex text not null default '#FF1E88E5',
  grade_scale_json text not null default '["1","2","3","4","5","6"]',
  grade_categories_json text not null default '[]',
  created_at bigint not null,
  archived_at bigint,
  user_id uuid references auth.users not null default auth.uid()
);
alter table groups_table enable row level security;
create policy "Users manage own groups" on groups_table
  for all using (auth.uid() = user_id);

-- Students
create table if not exists students_table (
  id text primary key,
  first_name text not null,
  last_name text not null,
  group_id text references groups_table(id) on delete cascade,
  origin_note text,
  created_at bigint not null,
  avatar_json text,
  seat_index int,
  user_id uuid references auth.users not null default auth.uid()
);
alter table students_table enable row level security;
create policy "Users manage own students" on students_table
  for all using (auth.uid() = user_id);

-- Grade entries
create table if not exists grade_entries_table (
  id text primary key,
  student_id text references students_table(id) on delete cascade,
  date bigint not null,
  session_label text not null,
  value text not null,
  category_id text,
  category_name text,
  created_at bigint not null,
  user_id uuid references auth.users not null default auth.uid()
);
alter table grade_entries_table enable row level security;
create policy "Users manage own grades" on grade_entries_table
  for all using (auth.uid() = user_id);

-- Attendance logs
create table if not exists attendance_logs_table (
  id text primary key,
  student_id text references students_table(id) on delete cascade,
  date bigint not null,
  created_at bigint not null,
  user_id uuid references auth.users not null default auth.uid()
);
alter table attendance_logs_table enable row level security;
create policy "Users manage own attendance" on attendance_logs_table
  for all using (auth.uid() = user_id);

-- Homework logs
create table if not exists homework_logs_table (
  id text primary key,
  student_id text references students_table(id) on delete cascade,
  date bigint not null,
  had_homework boolean not null default false,
  created_at bigint not null,
  user_id uuid references auth.users not null default auth.uid()
);
alter table homework_logs_table enable row level security;
create policy "Users manage own homework" on homework_logs_table
  for all using (auth.uid() = user_id);

-- Material logs
create table if not exists material_logs_table (
  id text primary key,
  student_id text references students_table(id) on delete cascade,
  date bigint not null,
  had_material boolean not null default false,
  created_at bigint not null,
  user_id uuid references auth.users not null default auth.uid()
);
alter table material_logs_table enable row level security;
create policy "Users manage own material" on material_logs_table
  for all using (auth.uid() = user_id);

-- Lists
create table if not exists lists_table (
  id text primary key,
  group_id text references groups_table(id) on delete cascade,
  name text not null,
  created_at bigint not null,
  archived_at bigint,
  user_id uuid references auth.users not null default auth.uid()
);
alter table lists_table enable row level security;
create policy "Users manage own lists" on lists_table
  for all using (auth.uid() = user_id);

-- List items
create table if not exists list_items_table (
  id text primary key,
  list_id text references lists_table(id) on delete cascade,
  student_id text references students_table(id) on delete set null,
  student_ids_json text,
  label text,
  checked_at bigint,
  created_at bigint not null,
  user_id uuid references auth.users not null default auth.uid()
);
alter table list_items_table enable row level security;
create policy "Users manage own list items" on list_items_table
  for all using (auth.uid() = user_id);

-- Notes
create table if not exists notes_table (
  id text primary key,
  body text not null,
  group_id text references groups_table(id) on delete set null,
  student_id text references students_table(id) on delete set null,
  student_ids_json text,
  is_todo boolean not null default false,
  todo_done boolean not null default false,
  todo_done_at bigint,
  created_at bigint not null,
  archived_at bigint,
  user_id uuid references auth.users not null default auth.uid()
);
alter table notes_table enable row level security;
create policy "Users manage own notes" on notes_table
  for all using (auth.uid() = user_id);
