-- 1. Structural Columns
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS subcategory TEXT; -- e.g. "coffee_shop", "tacos"
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS brand TEXT; -- e.g. "Starbucks"
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS opening_hours TEXT; -- Raw string for display

-- 2. Amenity Booleans (Useful for fast filtering)
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS wifi BOOLEAN DEFAULT false;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS takeaway BOOLEAN DEFAULT false;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS outdoor_seating BOOLEAN DEFAULT false;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS wheelchair_accessible BOOLEAN DEFAULT false;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS price_range SMALLINT DEFAULT 1; -- 1 to 4

-- 3. Relax Category Constraint
ALTER TABLE public.businesses DROP CONSTRAINT IF EXISTS businesses_category_check;

-- 4. Auto-Calculate Geography
CREATE OR REPLACE FUNCTION sync_businesses_location()
RETURNS TRIGGER AS $$
BEGIN
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_location ON public.businesses;
CREATE TRIGGER trg_sync_location
BEFORE INSERT OR UPDATE OF latitude, longitude ON public.businesses
FOR EACH ROW
EXECUTE FUNCTION sync_businesses_location();

-- 5. Clean Slate
-- 5. Clean Slate
-- We use CASCADE to clean up dependent tables (reviews, tags) automatically if they exist.
-- We check if businesses exists to avoid error if table is completely missing.
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'businesses') THEN
        TRUNCATE TABLE public.businesses CASCADE;
    END IF;
END $$;
