-- 🧨 HARD RESET & SETUP SCRIPT
-- WARNING: This will DELETE ALL DATA in 'businesses', 'reviews', and 'business_tags'.
-- Use this to fix structural errors and prepare for fresh data ingestion.

-- 1. Drop existing objects to clear conflicts
DROP TRIGGER IF EXISTS trg_sync_location ON public.businesses;
DROP FUNCTION IF EXISTS sync_businesses_location();
DROP FUNCTION IF EXISTS get_businesses_in_bounds(double precision, double precision, double precision, double precision);

-- CASCADE deletes reviews and business_tags automatically
DROP TABLE IF EXISTS public.reviews CASCADE;
DROP TABLE IF EXISTS public.business_tags CASCADE;
DROP TABLE IF EXISTS public.businesses CASCADE;
DROP TABLE IF EXISTS public.tags CASCADE;

-- 2. Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- 3. Create Businesses Table (The Truth Source)
CREATE TABLE public.businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    location GEOGRAPHY(POINT, 4326), -- PostGIS Field
    
    -- Explicit Lat/Lng for App compatibility
    latitude DOUBLE PRECISION NOT NULL DEFAULT 0,
    longitude DOUBLE PRECISION NOT NULL DEFAULT 0,
    
    -- Categories & Metadata
    category TEXT,      -- e.g. "restaurante"
    subcategory TEXT,   -- e.g. "tacos"
    brand TEXT,         -- e.g. "Starbucks"
    price_level SMALLINT CHECK (price_level BETWEEN 1 AND 4),
    
    -- Vibe Classification
    vibe TEXT,
    
    -- Contact Details
    address TEXT,
    phone TEXT,
    website TEXT,
    opening_hours TEXT, -- Display string
    
    -- Amenities (Booleans)
    wifi BOOLEAN DEFAULT false,
    takeaway BOOLEAN DEFAULT false,
    outdoor_seating BOOLEAN DEFAULT false,
    wheelchair_accessible BOOLEAN DEFAULT false,
    
    -- Arrays
    photos TEXT[] DEFAULT '{}',
    amenities TEXT[] DEFAULT '{}', -- Legacy support
    
    -- Stats
    average_score NUMERIC(3, 2) DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Create Reviews Table
CREATE TABLE public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    photos TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Create Tags Table (Optional but good for future)
CREATE TABLE public.tags (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE public.business_tags (
    business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES public.tags(id) ON DELETE CASCADE,
    PRIMARY KEY (business_id, tag_id)
);

-- 6. Indexes for Performance
CREATE INDEX businesses_geo_idx ON public.businesses USING GIST (location);
CREATE INDEX businesses_cat_idx ON public.businesses (category);

-- 7. Trigger: Auto-Sync Lat/Lng -> Location
CREATE OR REPLACE FUNCTION sync_businesses_location()
RETURNS TRIGGER AS $$
BEGIN
    -- Automatically set the PostGIS point from the lat/lng columns
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_location
BEFORE INSERT OR UPDATE OF latitude, longitude ON public.businesses
FOR EACH ROW
EXECUTE FUNCTION sync_businesses_location();

-- 8. RPC: Get Businesses by Viewport (App Critical)
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
    WHERE businesses.location && ST_MakeEnvelope(min_lng, min_lat, max_lng, max_lat, 4326);
END;
$$ LANGUAGE plpgsql;

-- 9. Grant Permissions (Fixes "Permission Denied")
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, anon, authenticated, service_role;
