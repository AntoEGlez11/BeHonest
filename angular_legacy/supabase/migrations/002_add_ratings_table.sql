-- 2. RATINGS TABLE (Hito 2 MVP)
create table if not exists public.ratings (
    id uuid default gen_random_uuid() primary key,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    business_id uuid references public.businesses(id) not null,
    user_id text not null, -- Keeping as text for MVP to allow 'temp-user-id' or anon ratings
    is_honest boolean not null,
    comment text,
    evidence_url text
);

-- Enable RLS
alter table public.ratings enable row level security;

-- Policies (MVP: Open access for testing)
create policy "Ratings are viewable by everyone" 
on public.ratings for select 
using (true);

create policy "Anyone can insert ratings" 
on public.ratings for insert 
with check (true);

-- Storage bucket note:
-- Make sure a public bucket named 'evidence-bucket' exists in Supabase Storage.
