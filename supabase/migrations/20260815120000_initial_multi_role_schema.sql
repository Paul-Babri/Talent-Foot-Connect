-- Applied remotely via MCP as initial_multi_role_schema + fix_security_definer_grants
-- Project: talent-foot-connect (rcpeireebmvgsidbnept)

create type public.user_role as enum ('player', 'academy', 'recruiter');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role public.user_role not null,
  email text,
  phone text,
  verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.player_profiles (
  id uuid primary key references public.profiles (id) on delete cascade,
  name text not null,
  age integer not null check (age >= 10 and age <= 50),
  position text,
  height_cm integer,
  weight_kg integer,
  club text,
  academy text,
  city text,
  country text,
  goals integer default 0,
  assists integer default 0,
  description text,
  photo_url text,
  video_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.academy_profiles (
  id uuid primary key references public.profiles (id) on delete cascade,
  name text not null,
  city text,
  country text,
  description text,
  logo_url text,
  photo_url text,
  video_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.recruiter_profiles (
  id uuid primary key references public.profiles (id) on delete cascade,
  name text not null,
  type text,
  country text,
  description text,
  besoins text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
