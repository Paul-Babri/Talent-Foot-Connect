-- TalentFoot V1: entitlements, social, performance, purchases, admin.
-- Privileged logic lives in schema private. Public RPCs that must bypass RLS
-- check auth.uid() / auth.role() before doing anything.

create schema if not exists private;

revoke all on schema private from public;
revoke all on schema private from anon, authenticated;
grant usage on schema private to postgres, service_role;

-- ---------------------------------------------------------------------------
-- Entitlements
-- ---------------------------------------------------------------------------

create table public.player_entitlements (
  player_id uuid primary key references public.player_profiles (id) on delete cascade,
  plan text not null default 'free' check (plan in ('free', 'pro')),
  pro_until timestamptz,
  video_credits integer not null default 0 check (video_credits >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.feed_posts
  add column comments_count integer not null default 0 check (comments_count >= 0);

alter table public.player_profiles
  add column followers_count integer not null default 0 check (followers_count >= 0);

create index player_entitlements_pro_idx
  on public.player_entitlements (player_id)
  where plan = 'pro';

create index feed_posts_player_media_idx
  on public.feed_posts (player_id, media_type);

insert into public.player_entitlements (player_id)
select id from public.player_profiles
on conflict (player_id) do nothing;

-- ---------------------------------------------------------------------------
-- Club history, performance, social, purchases, views, admins
-- ---------------------------------------------------------------------------

create table public.player_club_history (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.player_profiles (id) on delete cascade,
  club_name text not null check (char_length(trim(club_name)) > 0),
  year_label text not null check (char_length(trim(year_label)) > 0),
  sort_order smallint not null check (sort_order between 1 and 3),
  unique (player_id, sort_order)
);

create index player_club_history_player_idx
  on public.player_club_history (player_id, sort_order);

create table public.player_performance (
  player_id uuid primary key references public.player_profiles (id) on delete cascade,
  acceleration smallint not null check (acceleration between 1 and 10),
  finishing smallint not null check (finishing between 1 and 10),
  dribble smallint not null check (dribble between 1 and 10),
  vision smallint not null check (vision between 1 and 10),
  updated_at timestamptz not null default now()
);

create table public.feed_likes (
  post_id uuid not null references public.feed_posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index feed_likes_user_idx on public.feed_likes (user_id);

create table public.player_follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  player_id uuid not null references public.player_profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, player_id),
  check (follower_id <> player_id)
);

create index player_follows_player_idx on public.player_follows (player_id);

create table public.feed_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.feed_posts (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 500),
  created_at timestamptz not null default now()
);

create index feed_comments_post_idx
  on public.feed_comments (post_id, created_at);

create table public.purchases (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.player_profiles (id) on delete cascade,
  sku text not null check (sku in ('video_unit', 'pack_5', 'pack_10', 'pro_month')),
  amount_fcfa integer not null,
  status text not null default 'pending' check (status in ('pending', 'paid', 'failed', 'cancelled')),
  provider text,
  provider_ref text,
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  check (
    (sku = 'video_unit' and amount_fcfa = 100)
    or (sku = 'pack_5' and amount_fcfa = 400)
    or (sku = 'pack_10' and amount_fcfa = 700)
    or (sku = 'pro_month' and amount_fcfa = 2000)
  )
);

create index purchases_player_idx on public.purchases (player_id, created_at desc);
create unique index purchases_provider_ref_idx
  on public.purchases (provider, provider_ref)
  where provider_ref is not null;

create table public.profile_views (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.player_profiles (id) on delete cascade,
  viewer_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

create index profile_views_player_idx on public.profile_views (player_id, created_at desc);

create table public.profile_contacts (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.player_profiles (id) on delete cascade,
  viewer_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

create index profile_contacts_player_idx on public.profile_contacts (player_id, created_at desc);

create table public.admin_users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Private helpers
-- ---------------------------------------------------------------------------

create or replace function private.contains_contact(body text)
returns boolean
language sql
immutable
set search_path = public
as $$
  select
    regexp_replace(coalesce(body, ''), '[^0-9]', '', 'g') ~ '[0-9]{6,}'
    or coalesce(body, '') ~* '(whatsapp|wa\.me|telegram|t\.me|\+225)';
$$;

create or replace function private.pro_is_active(p_player uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.player_entitlements e
    where e.player_id = p_player
      and e.plan = 'pro'
      and e.pro_until is not null
      and e.pro_until > now()
  );
$$;

create or replace function private.player_can_publish(p_player uuid, p_media text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  credits integer;
  used integer;
begin
  if p_media = 'video' and private.pro_is_active(p_player) then
    return true;
  end if;

  select coalesce(video_credits, 0)
    into credits
  from public.player_entitlements
  where player_id = p_player;

  credits := coalesce(credits, 0);

  select count(*)::integer
    into used
  from public.feed_posts
  where player_id = p_player
    and media_type = p_media;

  if p_media = 'video' then
    return used < 3 + credits;
  elsif p_media = 'image' then
    return used < 10;
  end if;

  return false;
end;
$$;

create or replace function private.apply_paid_purchase(
  p_id uuid,
  p_provider text,
  p_ref text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  rec public.purchases%rowtype;
begin
  select * into rec
  from public.purchases
  where id = p_id
  for update;

  if not found then
    raise exception 'purchase_not_found' using errcode = 'P0001';
  end if;

  if rec.status = 'paid' then
    return;
  end if;

  if rec.status <> 'pending' then
    raise exception 'purchase_not_pending' using errcode = 'P0001';
  end if;

  insert into public.player_entitlements (player_id)
  values (rec.player_id)
  on conflict (player_id) do nothing;

  if rec.sku = 'video_unit' then
    update public.player_entitlements
      set video_credits = video_credits + 1, updated_at = now()
      where player_id = rec.player_id;
  elsif rec.sku = 'pack_5' then
    update public.player_entitlements
      set video_credits = video_credits + 5, updated_at = now()
      where player_id = rec.player_id;
  elsif rec.sku = 'pack_10' then
    update public.player_entitlements
      set video_credits = video_credits + 10, updated_at = now()
      where player_id = rec.player_id;
  elsif rec.sku = 'pro_month' then
    update public.player_entitlements
      set plan = 'pro',
          pro_until = greatest(coalesce(pro_until, now()), now()) + interval '1 month',
          updated_at = now()
      where player_id = rec.player_id;
  else
    raise exception 'unknown_sku' using errcode = 'P0001';
  end if;

  update public.purchases
    set status = 'paid',
        provider = p_provider,
        provider_ref = nullif(p_ref, ''),
        paid_at = now()
    where id = p_id;
end;
$$;

revoke all on function private.contains_contact(text) from public, anon, authenticated;
revoke all on function private.pro_is_active(uuid) from public, anon, authenticated;
revoke all on function private.player_can_publish(uuid, text) from public, anon, authenticated;
revoke all on function private.apply_paid_purchase(uuid, text, text) from public, anon, authenticated;
grant execute on function private.apply_paid_purchase(uuid, text, text) to service_role;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

create or replace function private.enforce_feed_quota()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not private.player_can_publish(new.player_id, new.media_type) then
    raise exception 'quota_exceeded' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger feed_posts_enforce_quota
  before insert on public.feed_posts
  for each row execute function private.enforce_feed_quota();

create or replace function private.sync_like_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.feed_posts
      set likes_count = likes_count + 1
      where id = new.post_id;
    return new;
  end if;
  update public.feed_posts
    set likes_count = greatest(0, likes_count - 1)
    where id = old.post_id;
  return old;
end;
$$;

create trigger feed_likes_sync_count
  after insert or delete on public.feed_likes
  for each row execute function private.sync_like_count();

create or replace function private.sync_comment_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.feed_posts
      set comments_count = comments_count + 1
      where id = new.post_id;
    return new;
  end if;
  update public.feed_posts
    set comments_count = greatest(0, comments_count - 1)
    where id = old.post_id;
  return old;
end;
$$;

create trigger feed_comments_sync_count
  after insert or delete on public.feed_comments
  for each row execute function private.sync_comment_count();

create or replace function private.reject_contact_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if private.contains_contact(new.body) then
    raise exception 'contact_not_allowed' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger feed_comments_reject_contact
  before insert or update on public.feed_comments
  for each row execute function private.reject_contact_comment();

create or replace function private.sync_follower_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.player_profiles
      set followers_count = followers_count + 1
      where id = new.player_id;
    return new;
  end if;
  update public.player_profiles
    set followers_count = greatest(0, followers_count - 1)
    where id = old.player_id;
  return old;
end;
$$;

create trigger player_follows_sync_count
  after insert or delete on public.player_follows
  for each row execute function private.sync_follower_count();

create or replace function private.protect_feed_counters()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_user not in ('postgres', 'supabase_admin') then
    new.likes_count := old.likes_count;
    new.comments_count := old.comments_count;
  end if;
  return new;
end;
$$;

create trigger feed_posts_protect_counters
  before update on public.feed_posts
  for each row execute function private.protect_feed_counters();

create or replace function private.protect_player_counters()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_user not in ('postgres', 'supabase_admin') then
    new.followers_count := old.followers_count;
  end if;
  return new;
end;
$$;

create trigger player_profiles_protect_counters
  before update on public.player_profiles
  for each row execute function private.protect_player_counters();

create or replace function private.protect_verified()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_user not in ('postgres', 'supabase_admin')
     and new.verified is distinct from old.verified then
    new.verified := old.verified;
  end if;
  return new;
end;
$$;

create trigger profiles_protect_verified
  before update on public.profiles
  for each row execute function private.protect_verified();

create or replace function private.ensure_player_entitlement()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.player_entitlements (player_id)
  values (new.id)
  on conflict (player_id) do nothing;
  return new;
end;
$$;

create trigger player_profiles_entitlement
  after insert on public.player_profiles
  for each row execute function private.ensure_player_entitlement();

-- ---------------------------------------------------------------------------
-- Public RPCs
-- ---------------------------------------------------------------------------

create or replace function public.my_publish_quota()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  credits integer := 0;
  plan text := 'free';
  until_at timestamptz;
  videos_used integer := 0;
  photos_used integer := 0;
  pro_active boolean := false;
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;

  select e.plan, e.pro_until, e.video_credits
    into plan, until_at, credits
  from public.player_entitlements e
  where e.player_id = uid;

  plan := coalesce(plan, 'free');
  credits := coalesce(credits, 0);
  pro_active := plan = 'pro' and until_at is not null and until_at > now();

  select count(*) filter (where media_type = 'video')::integer,
         count(*) filter (where media_type = 'image')::integer
    into videos_used, photos_used
  from public.feed_posts
  where player_id = uid;

  return jsonb_build_object(
    'plan', plan,
    'pro_active', pro_active,
    'pro_until', until_at,
    'video_credits', credits,
    'videos_used', coalesce(videos_used, 0),
    'photos_used', coalesce(photos_used, 0),
    'free_video_limit', 3,
    'free_photo_limit', 10,
    'can_video', pro_active or coalesce(videos_used, 0) < 3 + credits,
    'can_photo', coalesce(photos_used, 0) < 10
  );
end;
$$;

revoke all on function public.my_publish_quota() from public, anon;
grant execute on function public.my_publish_quota() to authenticated;

create or replace function public.apply_paid_purchase(
  p_id uuid,
  p_provider text,
  p_ref text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  perform private.apply_paid_purchase(p_id, p_provider, coalesce(p_ref, ''));
end;
$$;

revoke all on function public.apply_paid_purchase(uuid, text, text) from public, anon, authenticated;
grant execute on function public.apply_paid_purchase(uuid, text, text) to service_role;

create or replace function public.mark_purchase_failed(
  p_id uuid,
  p_provider text,
  p_ref text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  update public.purchases
    set status = 'failed',
        provider = p_provider,
        provider_ref = nullif(p_ref, '')
    where id = p_id
      and status = 'pending';
end;
$$;

revoke all on function public.mark_purchase_failed(uuid, text, text) from public, anon, authenticated;
grant execute on function public.mark_purchase_failed(uuid, text, text) to service_role;

create or replace function public.am_i_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users where user_id = auth.uid()
  );
$$;

revoke all on function public.am_i_admin() from public, anon;
grant execute on function public.am_i_admin() to authenticated;

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

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.player_entitlements enable row level security;
alter table public.player_club_history enable row level security;
alter table public.player_performance enable row level security;
alter table public.feed_likes enable row level security;
alter table public.player_follows enable row level security;
alter table public.feed_comments enable row level security;
alter table public.purchases enable row level security;
alter table public.profile_views enable row level security;
alter table public.admin_users enable row level security;

revoke all on public.player_entitlements from anon, authenticated;
grant select (player_id, plan, pro_until) on public.player_entitlements to anon, authenticated;

create policy "Plans are visible"
  on public.player_entitlements
  for select
  to anon, authenticated
  using (true);

create policy "Club history is visible"
  on public.player_club_history
  for select
  to anon, authenticated
  using (true);

create policy "Players manage own club history"
  on public.player_club_history
  for all
  to authenticated
  using (player_id = (select auth.uid()))
  with check (player_id = (select auth.uid()));

create policy "Owner reads own performance"
  on public.player_performance
  for select
  to authenticated
  using (player_id = (select auth.uid()));

create policy "PRO performance is public"
  on public.player_performance
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.player_entitlements e
      where e.player_id = player_performance.player_id
        and e.plan = 'pro'
        and e.pro_until > now()
    )
  );

create policy "PRO players write own performance"
  on public.player_performance
  for insert
  to authenticated
  with check (
    player_id = (select auth.uid())
    and exists (
      select 1
      from public.player_entitlements e
      where e.player_id = (select auth.uid())
        and e.plan = 'pro'
        and e.pro_until > now()
    )
  );

create policy "PRO players update own performance"
  on public.player_performance
  for update
  to authenticated
  using (player_id = (select auth.uid()))
  with check (
    player_id = (select auth.uid())
    and exists (
      select 1
      from public.player_entitlements e
      where e.player_id = (select auth.uid())
        and e.plan = 'pro'
        and e.pro_until > now()
    )
  );

create policy "Likes are visible"
  on public.feed_likes
  for select
  to anon, authenticated
  using (true);

create policy "Users like as themselves"
  on public.feed_likes
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy "Users remove own likes"
  on public.feed_likes
  for delete
  to authenticated
  using (user_id = (select auth.uid()));

create policy "Follows are visible"
  on public.player_follows
  for select
  to anon, authenticated
  using (true);

create policy "Users follow as themselves"
  on public.player_follows
  for insert
  to authenticated
  with check (follower_id = (select auth.uid()));

create policy "Users unfollow themselves"
  on public.player_follows
  for delete
  to authenticated
  using (follower_id = (select auth.uid()));

create policy "Comments are visible"
  on public.feed_comments
  for select
  to anon, authenticated
  using (true);

create policy "Users comment as themselves"
  on public.feed_comments
  for insert
  to authenticated
  with check (author_id = (select auth.uid()));

create policy "Users delete own comments"
  on public.feed_comments
  for delete
  to authenticated
  using (author_id = (select auth.uid()));

create policy "Players read own purchases"
  on public.purchases
  for select
  to authenticated
  using (player_id = (select auth.uid()));

create policy "Players create pending purchases"
  on public.purchases
  for insert
  to authenticated
  with check (
    player_id = (select auth.uid())
    and status = 'pending'
  );

create policy "Viewers record a profile view"
  on public.profile_views
  for insert
  to authenticated
  with check (
    viewer_id = (select auth.uid())
    and viewer_id <> player_id
  );

alter table public.profile_contacts enable row level security;

revoke all on table public.profile_contacts from anon, authenticated;
grant insert on table public.profile_contacts to authenticated;

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

-- admin_users: no client policies. Only security definer functions read it.
