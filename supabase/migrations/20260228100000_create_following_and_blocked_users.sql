begin;

create extension if not exists "pgcrypto" with schema extensions;

create table if not exists public.following (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  target_user_id text not null,
  created_at timestamptz not null default now()
);

create unique index if not exists following_user_target_unique on public.following (user_id, target_user_id);
create index if not exists idx_following_user_id on public.following (user_id);
create index if not exists idx_following_target_user_id on public.following (target_user_id);

alter table public.following enable row level security;

drop policy if exists "Users can view own following" on public.following;
drop policy if exists "Users can insert own following" on public.following;
drop policy if exists "Users can delete own following" on public.following;
drop policy if exists "Users can update own following" on public.following;

create policy "Users can view own following" on public.following
  for select
  to authenticated
  using (user_id = auth.uid()::text);

create policy "Users can insert own following" on public.following
  for insert
  to authenticated
  with check (user_id = auth.uid()::text);

create policy "Users can delete own following" on public.following
  for delete
  to authenticated
  using (user_id = auth.uid()::text);

create policy "Users can update own following" on public.following
  for update
  to authenticated
  using (user_id = auth.uid()::text)
  with check (user_id = auth.uid()::text);

create table if not exists public.blocked_users (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  target_user_id text not null,
  created_at timestamptz not null default now()
);

create unique index if not exists blocked_users_user_target_unique on public.blocked_users (user_id, target_user_id);
create index if not exists idx_blocked_users_user_id on public.blocked_users (user_id);
create index if not exists idx_blocked_users_target_user_id on public.blocked_users (target_user_id);

alter table public.blocked_users enable row level security;

drop policy if exists "Users can view own blocked" on public.blocked_users;
drop policy if exists "Users can insert own blocked" on public.blocked_users;
drop policy if exists "Users can delete own blocked" on public.blocked_users;
drop policy if exists "Users can update own blocked" on public.blocked_users;

create policy "Users can view own blocked" on public.blocked_users
  for select
  to authenticated
  using (user_id = auth.uid()::text);

create policy "Users can insert own blocked" on public.blocked_users
  for insert
  to authenticated
  with check (user_id = auth.uid()::text);

create policy "Users can delete own blocked" on public.blocked_users
  for delete
  to authenticated
  using (user_id = auth.uid()::text);

create policy "Users can update own blocked" on public.blocked_users
  for update
  to authenticated
  using (user_id = auth.uid()::text)
  with check (user_id = auth.uid()::text);

commit;
