-- Migration: Add RLS policies for local dev mock user
-- This allows the mock user (00000000-0000-0000-0000-000000000000) to bypass RLS in local development

-- Policy: Allow dev user to select their profile
create policy "Dev user can view own profile"
  on public.user_profiles
  for select
  using (id = '00000000-0000-0000-0000-000000000000'::uuid);

-- Policy: Allow dev user to insert their profile
create policy "Dev user can insert own profile"
  on public.user_profiles
  for insert
  with check (id = '00000000-0000-0000-0000-000000000000'::uuid);

-- Policy: Allow dev user to update their profile
create policy "Dev user can update own profile"
  on public.user_profiles
  for update
  using (id = '00000000-0000-0000-0000-000000000000'::uuid);

-- Policy: Allow dev user to delete their profile
create policy "Dev user can delete own profile"
  on public.user_profiles
  for delete
  using (id = '00000000-0000-0000-0000-000000000000'::uuid);

-- Add similar policies for tasks table
create policy "Dev user can view own tasks"
  on public.tasks
  for select
  using (user_id = '00000000-0000-0000-0000-000000000000'::uuid);

create policy "Dev user can insert own tasks"
  on public.tasks
  for insert
  with check (user_id = '00000000-0000-0000-0000-000000000000'::uuid);

create policy "Dev user can update own tasks"
  on public.tasks
  for update
  using (user_id = '00000000-0000-0000-0000-000000000000'::uuid);

create policy "Dev user can delete own tasks"
  on public.tasks
  for delete
  using (user_id = '00000000-0000-0000-0000-000000000000'::uuid);
