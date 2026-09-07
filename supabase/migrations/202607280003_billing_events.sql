create table if not exists public.billing_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  product_id text not null,
  transaction_id text,
  original_transaction_id text,
  plan text not null check (plan in ('plus', 'creator')),
  source text not null default 'storekit_local_verified',
  purchased_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create unique index if not exists billing_events_transaction_idx
  on public.billing_events (transaction_id)
  where transaction_id is not null;

create index if not exists billing_events_user_created_idx
  on public.billing_events (user_id, created_at desc);

alter table public.billing_events enable row level security;

revoke all on public.billing_events from anon, authenticated;
