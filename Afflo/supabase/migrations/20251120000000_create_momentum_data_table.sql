-- Create momentum_data table
create table if not exists public.momentum_data (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  score integer not null,
  delta text not null,
  weekly_data jsonb not null,
  breakdown jsonb not null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

-- Create index on user_id for faster queries
create index if not exists momentum_data_user_id_idx on public.momentum_data(user_id);

-- Create index on user_id + created_at for time-based queries
create index if not exists momentum_data_user_id_created_at_idx on public.momentum_data(user_id, created_at desc);

-- Enable Row Level Security
alter table public.momentum_data enable row level security;

-- Policy: Users can view their own momentum data
create policy "Users can view own momentum data"
  on public.momentum_data
  for select
  using (auth.uid() = user_id);

-- Policy: Users can insert their own momentum data
create policy "Users can insert own momentum data"
  on public.momentum_data
  for insert
  with check (auth.uid() = user_id);

-- Policy: Users can update their own momentum data
create policy "Users can update own momentum data"
  on public.momentum_data
  for update
  using (auth.uid() = user_id);

-- Policy: Users can delete their own momentum data
create policy "Users can delete own momentum data"
  on public.momentum_data
  for delete
  using (auth.uid() = user_id);

-- Trigger to auto-update updated_at (reuse existing function)
create trigger set_updated_at
  before update on public.momentum_data
  for each row
  execute function public.handle_updated_at();
