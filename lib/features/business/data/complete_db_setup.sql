-- 🏗️ BeHonest Complete Database Schema
-- Run this script to fully initialize or repair the database structure.

-- 1. Enable PostGIS Extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Businesses Table
CREATE TABLE IF NOT EXISTS public.businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT, -- e.g. "restaurante", "shop"
    subcategory TEXT, -- e.g. "tacos", "pharmacy"
    brand TEXT, -- e.g. "Oxxo"
    
    -- Geospatial Data
    latitude DOUBLE PRECISION NOT NULL DEFAULT 0,
    longitude DOUBLE PRECISION NOT NULL DEFAULT 0,
    location GEOGRAPHY(POINT, 4326),

    -- Contact & Details
    address TEXT,
    phone TEXT,
    website TEXT,
    opening_hours TEXT, -- Display string like "Mon-Fri 9-5"
    
    -- Stats
    average_score NUMERIC(3, 2) DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    price_level SMALLINT CHECK (price_level BETWEEN 1 AND 4),
    
    -- Amenities (Booleans for fast filtering)
    wifi BOOLEAN DEFAULT false,
    takeaway BOOLEAN DEFAULT false,
    outdoor_seating BOOLEAN DEFAULT false,
    wheelchair_accessible BOOLEAN DEFAULT false,
    
    -- Arrays
    photos TEXT[],
    amenities TEXT[], -- Legacy/Extended array support
    
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for Geospatial Search
CREATE INDEX IF NOT EXISTS businesses_geo_idx ON public.businesses USING GIST (location);

-- 3. Reviews Table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL, -- Links to auth.users if needed
    
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    photos TEXT[],
    
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. User Profiles Table (Optional)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY,
    username TEXT,
    avatar_url TEXT
);

-- 5. Helper Function: Sync Lat/Lng to PostGIS Location
CREATE OR REPLACE FUNCTION sync_businesses_location()
RETURNS TRIGGER AS $$
BEGIN
    -- Create a PostGIS point from the lat/long columns
    -- WGS84 (SRID 4326) is standard for GPS
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to run on Insert/Update
DROP TRIGGER IF EXISTS trg_sync_location ON public.businesses;
CREATE TRIGGER trg_sync_location
BEFORE INSERT OR UPDATE OF latitude, longitude ON public.businesses
FOR EACH ROW
EXECUTE FUNCTION sync_businesses_location();

-- 6. RPC Function: Get Businesses in Viewport
-- Efficiently returns only businesses inside the screen boundaries
CREATE OR REPLACE FUNCTION get_businesses_in_bounds(
    min_lat DOUBLE PRECISION,
    min_lng DOUBLE PRECISION,
    max_lat DOUBLE PRECISION,
    max_lng DOUBLE PRECISION
) RETURNS SETOF public.businesses AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.businesses
    WHERE business.location && ST_MakeEnvelope(min_lng, min_lat, max_lng, max_lat, 4326);
END;
$$ LANGUAGE plpgsql;

-- 7. Grant Permissions (Assuming standard Supabase setup)
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- 8. Optional: Clean only if desired (Commented out for safety)
-- TRUNCATE TABLE public.businesses CASCADE;
