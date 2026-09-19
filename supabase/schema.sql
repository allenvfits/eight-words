begin;

create table if not exists public.words (
    id text primary key,
    word text not null check (btrim(word) <> ''),
    pronunciation text not null check (btrim(pronunciation) <> ''),
    part_of_speech text not null check (btrim(part_of_speech) <> ''),
    definition text not null check (btrim(definition) <> ''),
    example text not null check (btrim(example) <> ''),
    difficulty text not null
        check (difficulty in ('beginner', 'intermediate', 'advanced')),
    sort_order integer not null check (sort_order >= 0),
    is_active boolean not null default true,
    published_at timestamptz,
    source_name text not null default 'Eight Words original',
    source_url text,
    license_name text,
    attribution text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (difficulty, sort_order)
);

create index if not exists words_published_catalog_idx
    on public.words (difficulty, sort_order, id)
    where is_active = true and published_at is not null;

alter table public.words enable row level security;

revoke all on table public.words from anon, authenticated;
grant select on table public.words to anon, authenticated;
grant all on table public.words to service_role;

drop policy if exists "Published words are readable" on public.words;
create policy "Published words are readable"
    on public.words
    for select
    to anon, authenticated
    using (
        is_active = true
        and published_at is not null
        and published_at <= now()
    );

comment on table public.words is
    'Read-only vocabulary catalog for the Eight Words iOS app.';

commit;
