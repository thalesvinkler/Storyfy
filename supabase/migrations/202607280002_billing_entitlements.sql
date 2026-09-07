create table if not exists public.user_entitlements (
  user_id uuid primary key,
  plan text not null default 'free' check (plan in ('free', 'plus', 'creator')),
  source text not null default 'manual',
  product_id text,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_entitlements enable row level security;

revoke all on public.user_entitlements from anon, authenticated;

create or replace function public.current_storyfy_plan(p_user_id uuid)
returns text
language sql
security definer
set search_path = public
stable
as $$
  select coalesce((
    select plan
      from public.user_entitlements
      where user_id = p_user_id
        and (expires_at is null or expires_at > now())
      limit 1
  ), 'free');
$$;

create or replace function public.storyfy_caption_monthly_limit(p_plan text)
returns integer
language sql
immutable
as $$
  select case p_plan
    when 'creator' then 150
    when 'plus' then 20
    else 2
  end;
$$;

create or replace function public.reserve_caption_usage_monthly(p_user_id uuid)
returns table(allowed boolean, plan text, monthly_limit integer, used integer, remaining integer, reset_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  month_start timestamptz := date_trunc('month', now() at time zone 'utc') at time zone 'utc';
  month_end timestamptz := date_trunc('month', now() at time zone 'utc') at time zone 'utc' + interval '1 month';
  used_count integer;
begin
  plan := public.current_storyfy_plan(p_user_id);
  monthly_limit := public.storyfy_caption_monthly_limit(plan);

  perform pg_advisory_xact_lock(hashtext(p_user_id::text || ':' || month_start::date::text));

  select count(*)::integer
    into used_count
    from public.caption_usage_events
    where user_id = p_user_id
      and created_at >= month_start;

  used := used_count;

  if used_count >= monthly_limit then
    allowed := false;
    remaining := 0;
    reset_at := month_end;
    return next;
    return;
  end if;

  insert into public.caption_usage_events (user_id, status, metadata)
  values (p_user_id, 'started', jsonb_build_object('source', 'storyfy-caption', 'plan', plan));

  allowed := true;
  used := used_count + 1;
  remaining := greatest(monthly_limit - used, 0);
  reset_at := month_end;
  return next;
end;
$$;

revoke all on function public.current_storyfy_plan(uuid) from public, anon, authenticated;
revoke all on function public.storyfy_caption_monthly_limit(text) from public, anon, authenticated;
revoke all on function public.reserve_caption_usage_monthly(uuid) from public, anon, authenticated;
