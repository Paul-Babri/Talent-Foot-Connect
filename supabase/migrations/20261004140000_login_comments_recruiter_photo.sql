alter table public.recruiter_profiles
  add column if not exists photo_url text;

create or replace function public.resolve_login_email(p_login text)
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  normalized text := lower(regexp_replace(trim(coalesce(p_login, '')), '\s+', ' ', 'g'));
  found text;
begin
  if normalized = '' then
    return null;
  end if;

  select u.email into found
  from auth.users u
  where lower(regexp_replace(trim(coalesce(u.raw_user_meta_data->>'name', '')), '\s+', ' ', 'g')) = normalized
  order by u.created_at
  limit 1;

  return found;
end;
$$;

revoke all on function public.resolve_login_email(text) from public;
grant execute on function public.resolve_login_email(text) to anon, authenticated;

create or replace function public.comments_for_post(p_post_id uuid)
returns table (
  id uuid,
  author_id uuid,
  author_name text,
  body text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    c.id,
    c.author_id,
    coalesce(pp.name, rp.name, ap.name, 'Membre') as author_name,
    c.body,
    c.created_at
  from public.feed_comments c
  left join public.player_profiles pp on pp.id = c.author_id
  left join public.recruiter_profiles rp on rp.id = c.author_id
  left join public.academy_profiles ap on ap.id = c.author_id
  where c.post_id = p_post_id
  order by c.created_at;
$$;

revoke all on function public.comments_for_post(uuid) from public;
grant execute on function public.comments_for_post(uuid) to anon, authenticated;
