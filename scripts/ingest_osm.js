
const { createClient } = require('@supabase/supabase-js');

// Configuration
const SUPABASE_URL = 'https://duvxujaqxtzreqywgmul.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dnh1amFxeHR6cmVxeXdnbXVsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1ODA2MDUsImV4cCI6MjA4NDE1NjYwNX0.70W3WLDhqIv8-Sebx21uovau3L1l7zIXbJjKYRQdBrg';

// Coyoacán Center Approx
const BOUNDS = '19.336,-99.182,19.356,-99.162';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function fetchFromOSM() {
    const query = `
    [out:json];
    (
      node["shop"](${BOUNDS});
      node["amenity"](${BOUNDS});
    );
    out body;
  `;

    const url = `https://overpass-api.de/api/interpreter?data=${encodeURIComponent(query)}`;

    console.log('Fetching from Overpass API...');
    console.log(url);

    try {
        // Node 18+ has native fetch. If on older node, we might need axios, but let's try fetch first.
        const response = await fetch(url);
        const data = await response.json();
        return data.elements;
    } catch (error) {
        console.error('Error fetching OSM data:', error);
        return [];
    }
}

async function ingest() {
    const nodes = await fetchFromOSM();
    if (!nodes) return;

    console.log(`Found ${nodes.length} nodes.`);

    const businesses = nodes
        .filter(n => n.tags && n.tags.name) // Only named places
        .map(n => ({
            name: n.tags.name,
            description: n.tags.shop || n.tags.amenity || 'Business',
            location: `POINT(${n.lon} ${n.lat})`, // PostGIS format
        }));

    console.log(`Prepared ${businesses.length} businesses for insertion.`);

    if (businesses.length > 0) {
        const chunkSize = 50;
        for (let i = 0; i < businesses.length; i += chunkSize) {
            const chunk = businesses.slice(i, i + chunkSize);
            console.log(`Inserting chunk ${Math.floor(i / chunkSize) + 1}...`);

            const { error } = await supabase
                .from('businesses')
                .upsert(chunk, { onConflict: 'name' });

            if (error) {
                console.error('Supabase Error:', error);
            }
        }
        console.log('Done!');
    }
}

ingest();
