-- Enable PostGIS extension for geospatial calculations
create extension if not exists postgis;

-- 1. PROFILES (Extends auth.users)
create table public.profiles (
  id uuid references auth.users not null primary key,
  username text unique,
  trust_score float default 50.0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. BUSINESSES (Formal and Informal)
create table public.businesses (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  category text not null,
  description text,
  is_informal boolean default true,
  founder_id uuid references public.profiles(id),
  location geography(Point, 4326) not null, -- PostGIS Point
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Index for fast geospatial queries (e.g., "businesses near me")
create index businesses_geo_index on public.businesses using GIST (location);

-- 3. REVIEWS (The Proof of Visit)
create table public.reviews (
  id uuid default gen_random_uuid() primary key,
  business_id uuid references public.businesses(id) not null,
  user_id uuid references public.profiles(id) not null,
  rating_quality int check (rating_quality between 1 and 5),
  rating_price int check (rating_price between 1 and 5),
  rating_attention int check (rating_attention between 1 and 5),
  proof_image_url text,
  verified boolean default false,
  checkin_location geography(Point, 4326), -- Where they actually were
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS POLICIES (Row Level Security)
alter table public.profiles enable row level security;
alter table public.businesses enable row level security;
alter table public.reviews enable row level security;

-- Public read access
create policy "Public profiles are viewable by everyone" on public.profiles for select using (true);
create policy "Businesses are viewable by everyone" on public.businesses for select using (true);
create policy "Reviews are viewable by everyone" on public.reviews for select using (true);

-- Authenticated insert access
create policy "Users can insert their own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Authenticated users can create businesses" on public.businesses for insert with check (auth.role() = 'authenticated');
create policy "Authenticated users can create reviews" on public.reviews for insert with check (auth.role() = 'authenticated');

-- 4. RPC: Nearby Businesses
-- Function to find businesses within X meters of a point
create or replace function public.nearby_businesses(
  lat float,
  long float,
  radius_meters float
)
returns table (
  id uuid,
  name text,
  category text,
  description text,
  lat float,
  lng float,
  dist_meters float
)
language sql
security definer
as $$
  select 
    id, 
    name, 
    category, 
    description, 
    st_y(location::geometry) as lat, 
    st_x(location::geometry) as lng, 
    st_distance(location, st_setsrid(st_makepoint(long, lat), 4326)) as dist_meters
  from public.businesses
  where ST_DWithin(
    location,
    ST_SetSRID(ST_MakePoint(long, lat), 4326),
    radius_meters
  );
$$;
