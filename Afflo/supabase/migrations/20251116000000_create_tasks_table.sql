-- Create tasks table
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  text text not null,
  is_completed boolean default false not null,
  "order" smallint default 0 not null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

-- Create index on user_id for faster queries
create index if not exists tasks_user_id_idx on public.tasks(user_id);

-- Create index on user_id + order for sorting
create index if not exists tasks_user_id_order_idx on public.tasks(user_id, "order");

-- Enable Row Level Security
alter table public.tasks enable row level security;

-- Policy: Users can view their own tasks
create policy "Users can view own tasks"
  on public.tasks
  for select
  using (auth.uid() = user_id);

-- Policy: Users can insert their own tasks
create policy "Users can insert own tasks"
  on public.tasks
  for insert
  with check (auth.uid() = user_id);

-- Policy: Users can update their own tasks
create policy "Users can update own tasks"
  on public.tasks
  for update
  using (auth.uid() = user_id);

-- Policy: Users can delete their own tasks
create policy "Users can delete own tasks"
  on public.tasks
  for delete
  using (auth.uid() = user_id);

-- Trigger to auto-update updated_at (reuse existing function)
create trigger set_updated_at
  before update on public.tasks
  for each row
  execute function public.handle_updated_at();
