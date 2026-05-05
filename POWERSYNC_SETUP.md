# PowerSync + Supabase Setup Guide

Classi uses [PowerSync](https://www.powersync.com/) for optional remote sync and [Supabase](https://supabase.com/) as the backend. Without configuration the app works fully **local-only** with encrypted SQLite storage. Sync is opt-in.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Classi App    │────▶│  PowerSync Svc  │────▶│    Supabase     │
│ (PowerSync SDK) │     │  (self-hosted   │     │  (PostgreSQL +  │
│                 │◀────│   or managed)   │◀────│   Auth + API)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

- **Local database**: encrypted SQLite managed by PowerSync SDK
- **Sync protocol**: PowerSync service syncs data between devices
- **Backend**: Supabase PostgreSQL with row-level security

## Quick Start with Supabase Cloud

### 1. Create a Supabase project

1. Sign up at [supabase.com](https://supabase.com) and create a new project.
2. Note your **Project URL** and **Anon Key** from *Settings → API*.

### 2. Create the database tables

Run the following SQL in the Supabase SQL editor:

```sql
-- Groups
create table groups_table (
  id text primary key,
  name text not null,
  color_hex text not null default '#FF1E88E5',
  grade_scale_json text not null default '["1","2","3","4","5","6"]',
  grade_categories_json text not null,
  created_at bigint not null,
  archived_at bigint,
  user_id uuid references auth.users not null default auth.uid()
);
alter table groups_table enable row level security;
create policy "Users manage own groups" on groups_table
  for all using (auth.uid() = user_id);

-- Students
create table students_table (
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
create table grade_entries_table (
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
create table attendance_logs_table (
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
create table homework_logs_table (
  id text primary key,
  student_id text references students_table(id) on delete cascade,
  date bigint not null,
  had_homework boolean not null default true,
  created_at bigint not null,
  user_id uuid references auth.users not null default auth.uid()
);
alter table homework_logs_table enable row level security;
create policy "Users manage own homework" on homework_logs_table
  for all using (auth.uid() = user_id);

-- Material logs
create table material_logs_table (
  id text primary key,
  student_id text references students_table(id) on delete cascade,
  date bigint not null,
  had_material boolean not null default true,
  created_at bigint not null,
  user_id uuid references auth.users not null default auth.uid()
);
alter table material_logs_table enable row level security;
create policy "Users manage own material" on material_logs_table
  for all using (auth.uid() = user_id);

-- Lists
create table lists_table (
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
create table list_items_table (
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
create table notes_table (
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
```

### 3. Set up PowerSync

#### Option A – PowerSync Cloud (managed)

1. Create a free account at [app.powersync.com](https://app.powersync.com).
2. Create a new PowerSync instance and connect it to your Supabase project.
3. Note the **PowerSync endpoint URL** (e.g. `https://abc123.powersync.journeyapps.com`).
4. Add sync rules – create a file `sync-rules.yaml` in your PowerSync project:

```yaml
bucket_definitions:
  user_data:
    parameters: select request.user_id() as user_id
    data:
      - select * from groups_table where user_id = bucket.user_id
      - select * from students_table where user_id = bucket.user_id
      - select * from grade_entries_table where user_id = bucket.user_id
      - select * from attendance_logs_table where user_id = bucket.user_id
      - select * from homework_logs_table where user_id = bucket.user_id
      - select * from material_logs_table where user_id = bucket.user_id
      - select * from lists_table where user_id = bucket.user_id
      - select * from list_items_table where user_id = bucket.user_id
      - select * from notes_table where user_id = bucket.user_id
```

#### Option B – Self-hosted PowerSync

See the [PowerSync self-hosting guide](https://docs.powersync.com/self-hosting/getting-started) for Docker-based deployment.

### 4. Configure Classi

In Classi, go to **Settings → Remote Sync** and enter:

| Field | Value |
|-------|-------|
| Supabase URL | Your Supabase project URL |
| Supabase Anon Key | Your project's anon key |
| PowerSync Endpoint | Your PowerSync endpoint URL |

Save the configuration, then create a Supabase account in the app to start syncing.

## Data Encryption

All local data is encrypted using the passphrase you set when creating your library. The encryption key is derived using PBKDF2 and applied via sqlite3mc (SQLCipher-compatible). Data in transit is protected by TLS. Data at rest in Supabase is protected by Supabase's own encryption at rest.

## Local-Only Mode

If you do not configure sync credentials, Classi operates fully offline with an encrypted local database. No data leaves your device.

## Backward Compatibility

**Note:** This release is not backward-compatible with databases created in earlier versions of Classi (which used SQLCipher with integer primary keys). Existing libraries must be recreated. Export your data first using **Settings → Backups → Export backup** before upgrading.
