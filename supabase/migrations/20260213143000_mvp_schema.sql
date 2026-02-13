begin;

create extension if not exists pgcrypto;

create table if not exists public.lobbies (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  language text not null,
  round_limit int not null,
  risk_level int default 1,
  status text default 'waiting',
  host_user_id uuid,
  created_at timestamptz default now(),
  constraint lobbies_code_key unique (code)
);

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  lobby_id uuid references public.lobbies(id) on delete cascade,
  auth_user_id uuid,
  nickname text,
  score int default 0,
  created_at timestamptz default now()
);

create table if not exists public.rounds (
  id uuid primary key default gen_random_uuid(),
  lobby_id uuid references public.lobbies(id) on delete cascade,
  statement text,
  risk_level int,
  started_at timestamptz,
  ended_at timestamptz
);

create table if not exists public.answers (
  id uuid primary key default gen_random_uuid(),
  round_id uuid references public.rounds(id) on delete cascade,
  player_id uuid references public.players(id) on delete cascade,
  answer text check (answer in ('yes', 'no')),
  response_time_ms int,
  created_at timestamptz default now(),
  unique (round_id, player_id)
);

create index if not exists idx_players_lobby_id on public.players (lobby_id);
create index if not exists idx_rounds_lobby_id on public.rounds (lobby_id);

alter table public.lobbies enable row level security;
alter table public.players enable row level security;
alter table public.rounds enable row level security;
alter table public.answers enable row level security;

drop policy if exists lobbies_select_for_members on public.lobbies;
drop policy if exists lobbies_insert_authenticated on public.lobbies;

drop policy if exists players_select_own on public.players;
drop policy if exists players_insert_authenticated on public.players;
drop policy if exists players_update_own on public.players;
drop policy if exists players_delete_own on public.players;

drop policy if exists rounds_select_for_members on public.rounds;
drop policy if exists rounds_insert_authenticated on public.rounds;

drop policy if exists answers_select_for_members on public.answers;
drop policy if exists answers_insert_authenticated on public.answers;

create policy lobbies_select_for_members
on public.lobbies
for select
to authenticated
using (
  host_user_id = auth.uid()
  or exists (
    select 1
    from public.players p
    where p.lobby_id = lobbies.id
      and p.auth_user_id = auth.uid()
  )
);

create policy lobbies_insert_authenticated
on public.lobbies
for insert
to authenticated
with check (
  auth.uid() is not null
  and (host_user_id is null or host_user_id = auth.uid())
);

create policy players_select_own
on public.players
for select
to authenticated
using (auth_user_id = auth.uid());

create policy players_update_own
on public.players
for update
to authenticated
using (auth_user_id = auth.uid())
with check (auth_user_id = auth.uid());

create policy players_delete_own
on public.players
for delete
to authenticated
using (auth_user_id = auth.uid());

create policy players_insert_authenticated
on public.players
for insert
to authenticated
with check (
  auth.uid() is not null
  and auth_user_id = auth.uid()
);

create policy rounds_select_for_members
on public.rounds
for select
to authenticated
using (
  exists (
    select 1
    from public.players p
    where p.lobby_id = rounds.lobby_id
      and p.auth_user_id = auth.uid()
  )
);

create policy rounds_insert_authenticated
on public.rounds
for insert
to authenticated
with check (
  auth.uid() is not null
  and exists (
    select 1
    from public.players p
    where p.lobby_id = rounds.lobby_id
      and p.auth_user_id = auth.uid()
  )
);

create policy answers_select_for_members
on public.answers
for select
to authenticated
using (
  exists (
    select 1
    from public.rounds r
    join public.players p on p.lobby_id = r.lobby_id
    where r.id = answers.round_id
      and p.auth_user_id = auth.uid()
  )
);

create policy answers_insert_authenticated
on public.answers
for insert
to authenticated
with check (
  auth.uid() is not null
  and exists (
    select 1
    from public.players p
    join public.rounds r on r.id = answers.round_id
    where p.id = answers.player_id
      and p.auth_user_id = auth.uid()
      and p.lobby_id = r.lobby_id
  )
);

create or replace function public.reset_lobby_scores(lobby_uuid uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if lobby_uuid is null then
    raise exception 'lobby_uuid cannot be null';
  end if;

  if auth.uid() is not null and not exists (
    select 1
    from public.lobbies l
    where l.id = lobby_uuid
      and l.host_user_id = auth.uid()
  ) then
    raise exception 'not allowed';
  end if;

  update public.players
  set score = 0
  where lobby_id = lobby_uuid;
end;
$$;

revoke all on function public.reset_lobby_scores(uuid) from public;
grant execute on function public.reset_lobby_scores(uuid) to authenticated;
grant execute on function public.reset_lobby_scores(uuid) to service_role;

commit;
