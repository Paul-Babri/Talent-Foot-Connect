-- Contacts WhatsApp générés depuis la fiche publique, et indicateur admin.

create table if not exists public.profile_contacts (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.player_profiles (id) on delete cascade,
  viewer_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists profile_contacts_player_idx
  on public.profile_contacts (player_id, created_at desc);

alter table public.profile_contacts enable row level security;

revoke all on table public.profile_contacts from anon, authenticated;
grant insert on table public.profile_contacts to authenticated;

drop policy if exists "Recruiters record a profile contact" on public.profile_contacts;

create policy "Recruiters record a profile contact"
  on public.profile_contacts
  for insert
  to authenticated
  with check (
    viewer_id = (select auth.uid())
    and viewer_id <> player_id
    and exists (
      select 1 from public.profiles
      where id = (select auth.uid())
        and role in ('academy', 'recruiter')
    )
  );

create or replace function public.admin_dashboard(action text, payload jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  result jsonb;
begin
  if uid is null or not exists (
    select 1 from public.admin_users where user_id = uid
  ) then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  if action = 'kpis' then
    select jsonb_build_object(
      'players', (select count(*) from public.profiles where role = 'player'),
      'players_with_video', (
        select count(distinct player_id)
        from public.feed_posts
        where media_type = 'video'
      ),
      'avg_videos', (
        select coalesce(round(avg(cnt)::numeric, 2), 0)
        from (
          select count(*) filter (where fp.media_type = 'video') as cnt
          from public.player_profiles pp
          left join public.feed_posts fp on fp.player_id = pp.id
          group by pp.id
        ) s
      ),
      'video_purchases', (
        select count(*) from public.purchases
        where status = 'paid' and sku <> 'pro_month'
      ),
      'pro_subscribers', (
        select count(*) from public.player_entitlements
        where plan = 'pro' and pro_until > now()
      ),
      'free_to_pro_rate', (
        select case
          when (select count(*) from public.player_profiles) = 0 then 0
          else round(
            (
              select count(*) from public.player_entitlements
              where plan = 'pro' and pro_until > now()
            )::numeric
            / (select count(*) from public.player_profiles),
            4
          )
        end
      ),
      'profile_views', (select count(*) from public.profile_views),
      'contacts_generated', (select count(*) from public.profile_contacts),
      'pending_purchases', (
        select count(*) from public.purchases where status = 'pending'
      )
    ) into result;
    return result;
  end if;

  if action = 'players' then
    return (
      select coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb)
      from (
        select
          pp.id,
          pp.name,
          pp.position,
          pr.email,
          pr.verified,
          coalesce(e.plan, 'free') as plan,
          e.pro_until,
          coalesce(e.video_credits, 0) as video_credits,
          (select count(*) from public.feed_posts f where f.player_id = pp.id and f.media_type = 'video') as videos,
          (select count(*) from public.feed_posts f where f.player_id = pp.id and f.media_type = 'image') as photos
        from public.player_profiles pp
        join public.profiles pr on pr.id = pp.id
        left join public.player_entitlements e on e.player_id = pp.id
        order by pp.name
        limit 200
      ) t
    );
  end if;

  if action = 'purchases' then
    return (
      select coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb)
      from (
        select id, player_id, sku, amount_fcfa, status, provider, provider_ref, created_at, paid_at
        from public.purchases
        order by created_at desc
        limit 100
      ) t
    );
  end if;

  if action = 'set_verified' then
    update public.profiles
      set verified = coalesce((payload ->> 'verified')::boolean, false),
          updated_at = now()
      where id = (payload ->> 'player_id')::uuid;
    return jsonb_build_object('ok', true);
  end if;

  if action = 'adjust_credits' then
    insert into public.player_entitlements (player_id)
    values ((payload ->> 'player_id')::uuid)
    on conflict (player_id) do nothing;

    update public.player_entitlements
      set video_credits = greatest(0, video_credits + coalesce((payload ->> 'delta')::integer, 0)),
          updated_at = now()
      where player_id = (payload ->> 'player_id')::uuid;
    return jsonb_build_object('ok', true);
  end if;

  if action = 'fulfill_purchase' then
    perform private.apply_paid_purchase(
      (payload ->> 'purchase_id')::uuid,
      coalesce(payload ->> 'provider', 'manual'),
      coalesce(payload ->> 'provider_ref', 'admin')
    );
    return jsonb_build_object('ok', true);
  end if;

  raise exception 'unknown_action' using errcode = 'P0001';
end;
$$;

revoke all on function public.admin_dashboard(text, jsonb) from public, anon;
grant execute on function public.admin_dashboard(text, jsonb) to authenticated;
