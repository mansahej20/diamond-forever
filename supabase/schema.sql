-- Diamond Forever — catalogue schema.
-- Anyone may READ the catalogue (it is a shop window).
-- Only addresses listed in public.editors may write it.

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

-- Who may edit. An allowlist, not "anyone with an account": even if sign-ups
-- are ever left open, only addresses listed here can write.
create table if not exists public.editors (
  email    text primary key,
  note     text not null default '',
  added_at timestamptz not null default now()
);

alter table public.editors enable row level security;

-- SECURITY DEFINER on purpose: this reads public.editors, and the policies on
-- public.editors call it. Invoker rights would recurse. Execute is revoked from
-- anon so only a signed-in session can ask.
create or replace function public.is_editor()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.editors e
    where lower(e.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

revoke execute on function public.is_editor() from anon, public;
grant execute on function public.is_editor() to authenticated;

drop policy if exists "editors read the list" on public.editors;
create policy "editors read the list"
  on public.editors for select to authenticated
  using (public.is_editor());

drop policy if exists "editors manage the list" on public.editors;
create policy "editors manage the list"
  on public.editors for all to authenticated
  using (public.is_editor()) with check (public.is_editor());

drop policy if exists "catalogue readable by anyone" on public.pieces;
create policy "catalogue readable by anyone"
  on public.pieces for select
  using (true);

drop policy if exists "editors insert pieces" on public.pieces;
create policy "editors insert pieces"
  on public.pieces for insert to authenticated
  with check (public.is_editor());

drop policy if exists "editors update pieces" on public.pieces;
create policy "editors update pieces"
  on public.pieces for update to authenticated
  using (public.is_editor()) with check (public.is_editor());

drop policy if exists "editors delete pieces" on public.pieces;
create policy "editors delete pieces"
  on public.pieces for delete to authenticated
  using (public.is_editor());

-- Photographs. Public read so the shop window works signed out.
insert into storage.buckets (id, name, public)
values ('piece-photos', 'piece-photos', true)
on conflict (id) do update set public = true;

drop policy if exists "photos readable by anyone" on storage.objects;
create policy "photos readable by anyone"
  on storage.objects for select
  using (bucket_id = 'piece-photos');

drop policy if exists "editors upload photos" on storage.objects;
create policy "editors upload photos"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'piece-photos' and public.is_editor());

drop policy if exists "editors replace photos" on storage.objects;
create policy "editors replace photos"
  on storage.objects for update to authenticated
  using (bucket_id = 'piece-photos' and public.is_editor());

drop policy if exists "editors remove photos" on storage.objects;
create policy "editors remove photos"
  on storage.objects for delete to authenticated
  using (bucket_id = 'piece-photos' and public.is_editor());
