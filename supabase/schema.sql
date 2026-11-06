-- Diamond Forever — catalogue schema.
-- Anyone may READ the catalogue (it is a shop window).
-- Only the signed-in owner may write it.

create table if not exists public.pieces (
  id          text primary key,
  name        text        not null,
  line        text        not null default 'gold' check (line in ('gold', 'diamond')),
  price       text        not null default '',
  price_note  text        not null default '',
  summary     text        not null default '',
  note        text        not null default '',
  spec        jsonb       not null default '[]'::jsonb,   -- [[label, value, isMeasurement], ...]
  frames      jsonb       not null default '[]'::jsonb,   -- storage object paths, in spin order
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists pieces_line_created_idx on public.pieces (line, created_at);

alter table public.pieces enable row level security;

-- Who counts as the owner. Kept in one function so the address lives in exactly
-- one place; change it here and every policy follows. SECURITY INVOKER: it only
-- compares the caller's own JWT email to a constant, so it needs no elevated
-- rights, and definer rights here would be surface for nothing.
create or replace function public.is_owner()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'mansahej3009@gmail.com';
$$;

drop policy if exists "catalogue readable by anyone" on public.pieces;
create policy "catalogue readable by anyone"
  on public.pieces for select
  using (true);

drop policy if exists "owner inserts" on public.pieces;
create policy "owner inserts"
  on public.pieces for insert to authenticated
  with check (public.is_owner());

drop policy if exists "owner updates" on public.pieces;
create policy "owner updates"
  on public.pieces for update to authenticated
  using (public.is_owner()) with check (public.is_owner());

drop policy if exists "owner deletes" on public.pieces;
create policy "owner deletes"
  on public.pieces for delete to authenticated
  using (public.is_owner());

-- Photographs. Public read so the shop window works signed out; owner-only write.
insert into storage.buckets (id, name, public)
values ('piece-photos', 'piece-photos', true)
on conflict (id) do update set public = true;

drop policy if exists "photos readable by anyone" on storage.objects;
create policy "photos readable by anyone"
  on storage.objects for select
  using (bucket_id = 'piece-photos');

drop policy if exists "owner uploads photos" on storage.objects;
create policy "owner uploads photos"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'piece-photos' and public.is_owner());

drop policy if exists "owner replaces photos" on storage.objects;
create policy "owner replaces photos"
  on storage.objects for update to authenticated
  using (bucket_id = 'piece-photos' and public.is_owner());

drop policy if exists "owner removes photos" on storage.objects;
create policy "owner removes photos"
  on storage.objects for delete to authenticated
  using (bucket_id = 'piece-photos' and public.is_owner());
