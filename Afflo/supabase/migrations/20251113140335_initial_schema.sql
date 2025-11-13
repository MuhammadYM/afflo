-- Create user_profiles table
create table if not exists public.user_profiles (
  id uuid primary key references auth.users on delete cascade,
  manifest_goal text,
  why text,
  obstacle text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Enable Row Level Security
alter table public.user_profiles enable row level security;

-- Policy: Users can view their own profile
create policy "Users can view own profile"
  on public.user_profiles
  for select
  using (auth.uid() = id);

-- Policy: Users can insert their own profile
create policy "Users can insert own profile"
  on public.user_profiles
  for insert
  with check (auth.uid() = id);

-- Policy: Users can update their own profile
create policy "Users can update own profile"
  on public.user_profiles
  for update
  using (auth.uid() = id);

-- Function to update updated_at timestamp
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Trigger to auto-update updated_at
create trigger set_updated_at
  before update on public.user_profiles
  for each row
  execute function public.handle_updated_at();
