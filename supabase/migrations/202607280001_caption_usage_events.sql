create table if not exists public.caption_usage_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  created_at timestamptz not null default now(),
  status text not null default 'started',
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists caption_usage_events_user_created_idx
  on public.caption_usage_events (user_id, created_at desc);

alter table public.caption_usage_events enable row level security;

revoke all on public.caption_usage_events from anon, authenticated;

create or replace function public.reserve_caption_usage(p_user_id uuid, p_daily_limit integer default 20)
returns table(allowed boolean, remaining integer, reset_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  day_start timestamptz := date_trunc('day', now() at time zone 'utc') at time zone 'utc';
  day_end timestamptz := date_trunc('day', now() at time zone 'utc') at time zone 'utc' + interval '1 day';
  used_count integer;
begin
  perform pg_advisory_xact_lock(hashtext(p_user_id::text || ':' || day_start::date::text));

  select count(*)::integer
    into used_count
    from public.caption_usage_events
    where user_id = p_user_id
      and created_at >= day_start;

  if used_count >= p_daily_limit then
    allowed := false;
    remaining := 0;
    reset_at := day_end;
    return next;
    return;
  end if;

  insert into public.caption_usage_events (user_id, status, metadata)
  values (p_user_id, 'started', jsonb_build_object('source', 'storyfy-caption'));

  allowed := true;
  remaining := greatest(p_daily_limit - used_count - 1, 0);
  reset_at := day_end;
  return next;
end;
$$;

revoke all on function public.reserve_caption_usage(uuid, integer) from public, anon, authenticated;
