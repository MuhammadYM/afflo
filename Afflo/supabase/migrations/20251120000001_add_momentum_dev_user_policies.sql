-- Migration: Add RLS policies for momentum_data table for dev user
-- This allows the mock user (00000000-0000-0000-0000-000000000000) to access momentum_data in local development

-- Policy: Allow dev user to view own momentum data
create policy "Dev user can view own momentum data"
  on public.momentum_data
  for select
  using (user_id = '00000000-0000-0000-0000-000000000000'::uuid);

-- Policy: Allow dev user to insert own momentum data
create policy "Dev user can insert own momentum data"
  on public.momentum_data
  for insert
  with check (user_id = '00000000-0000-0000-0000-000000000000'::uuid);

-- Policy: Allow dev user to update own momentum data
create policy "Dev user can update own momentum data"
  on public.momentum_data
  for update
  using (user_id = '00000000-0000-0000-0000-000000000000'::uuid);

-- Policy: Allow dev user to delete own momentum data
create policy "Dev user can delete own momentum data"
  on public.momentum_data
  for delete
  using (user_id = '00000000-0000-0000-0000-000000000000'::uuid);
