-- feed_posts + storage bucket feed (applied remotely)

create table if not exists public.feed_posts (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.player_profiles (id) on delete cascade,
  media_url text not null,
  media_type text not null check (media_type in ('image', 'video')),
  caption text,
  likes_count integer not null default 0,
  created_at timestamptz not null default now()
);
