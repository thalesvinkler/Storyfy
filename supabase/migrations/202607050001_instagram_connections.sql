create table if not exists public.instagram_connections (
  id uuid primary key default gen_random_uuid(),
  instagram_user_id text not null,
  username text not null,
  access_token text not null,
  captions jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.instagram_connections enable row level security;

create table if not exists public.instagram_oauth_states (
  state text primary key,
  created_at timestamptz not null default now()
);

alter table public.instagram_oauth_states enable row level security;

revoke all on public.instagram_connections from anon, authenticated;
revoke all on public.instagram_oauth_states from anon, authenticated;
