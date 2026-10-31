-- KATA//RUN cloud media setup (run once in Supabase Dashboard > SQL Editor)
-- Only public, teacher-approved demonstration media: NOT recordings with pupil personal data.
-- The SQL creates seven shared media slots, a public-read bucket, and strict teacher-only write policies.

create table if not exists public.katarun_teachers (
  user_id uuid primary key references auth.users(id) on delete cascade,
  added_at timestamptz not null default now()
);
alter table public.katarun_teachers enable row level security;
-- No public/teacher policies: only the SQL Editor (admin) may manage the allowlist.
revoke all on public.katarun_teachers from anon, authenticated;

create or replace function public.katarun_is_teacher()
returns boolean
language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.katarun_teachers t where t.user_id = (select auth.uid())); $$;
revoke all on function public.katarun_is_teacher() from public, anon;
grant execute on function public.katarun_is_teacher() to authenticated;

create table if not exists public.katarun_media (
  slot text primary key check (slot in ('mascot','exercise-0','exercise-1','exercise-2','cue-0','cue-1','cue-2')),
  object_path text not null check (object_path ~ '^media/(mascot|exercise-[012]|cue-[012])/[a-zA-Z0-9-]+\.(jpg|png|webp|mp4|webm|mov)$'),
  file_name text not null check (length(file_name) between 1 and 180),
  mime_type text not null check (mime_type in ('image/jpeg','image/png','image/webp','video/mp4','video/webm','video/quicktime')),
  updated_at timestamptz not null default now()
);
alter table public.katarun_media enable row level security;
grant select on public.katarun_media to anon, authenticated;
grant insert, update, delete on public.katarun_media to authenticated;

drop policy if exists "KATARUN media public read" on public.katarun_media;
create policy "KATARUN media public read" on public.katarun_media
for select to anon, authenticated using (true);
drop policy if exists "KATARUN media teacher insert" on public.katarun_media;
create policy "KATARUN media teacher insert" on public.katarun_media
for insert to authenticated with check ((select public.katarun_is_teacher()));
drop policy if exists "KATARUN media teacher update" on public.katarun_media;
create policy "KATARUN media teacher update" on public.katarun_media
for update to authenticated using ((select public.katarun_is_teacher())) with check ((select public.katarun_is_teacher()));
drop policy if exists "KATARUN media teacher delete" on public.katarun_media;
create policy "KATARUN media teacher delete" on public.katarun_media
for delete to authenticated using ((select public.katarun_is_teacher()));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('katarun-media','katarun-media',true,41943040,
 array['image/jpeg','image/png','image/webp','video/mp4','video/webm','video/quicktime'])
on conflict (id) do update set public=true, file_size_limit=excluded.file_size_limit,
 allowed_mime_types=excluded.allowed_mime_types;

-- Public bucket allows anyone with a URL to view media. Storage writes are restricted.
drop policy if exists "KATARUN teacher upload" on storage.objects;
create policy "KATARUN teacher upload" on storage.objects for insert to authenticated
with check (bucket_id='katarun-media' and (storage.foldername(name))[1]='media'
 and (storage.foldername(name))[2] in ('mascot','exercise-0','exercise-1','exercise-2','cue-0','cue-1','cue-2')
 and (select public.katarun_is_teacher()));
drop policy if exists "KATARUN teacher read objects" on storage.objects;
create policy "KATARUN teacher read objects" on storage.objects for select to authenticated
using (bucket_id='katarun-media' and (select public.katarun_is_teacher()));
drop policy if exists "KATARUN teacher remove objects" on storage.objects;
create policy "KATARUN teacher remove objects" on storage.objects for delete to authenticated
using (bucket_id='katarun-media' and (select public.katarun_is_teacher()));

-- Optional instant cross-device updates (30-second polling also works without Realtime):
-- In Supabase Dashboard > Database > Publications, enable katarun_media in supabase_realtime.
-- If your project has the supabase_realtime publication, uncomment and run this once:
-- alter publication supabase_realtime add table public.katarun_media;

-- AFTER you create a teacher in Authentication > Users, run this separate statement,
-- replacing UUID with that teacher's actual auth.users.id:
-- insert into public.katarun_teachers(user_id) values ('REPLACE_WITH_TEACHER_USER_UUID')
-- on conflict (user_id) do nothing;
