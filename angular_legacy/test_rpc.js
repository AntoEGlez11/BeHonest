
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://duvxujaqxtzreqywgmul.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dnh1amFxeHR6cmVxeXdnbXVsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1ODA2MDUsImV4cCI6MjA4NDE1NjYwNX0.70W3WLDhqIv8-Sebx21uovau3L1l7zIXbJjKYRQdBrg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testRpc() {
    console.log('Testing RPC nearby_businesses...');

    // 1. Try exact match Satelite
    const r1 = await supabase.rpc('nearby_businesses', {
        lat: 19.51,
        long: -99.23,
        radius_meters: 10000 // 10km
    });
    console.log('Results (Satelite 10km):', r1.data?.length, r1.error);
    if (r1.data?.length) console.log(r1.data);

    // 2. Try Mexico City Center
    const r2 = await supabase.rpc('nearby_businesses', {
        lat: 19.4326,
        long: -99.1332,
        radius_meters: 50000 // 50km
    });
    console.log('Results (CDMX 50km):', r2.data?.length, r2.error);
    if (r2.data?.length) console.log(r2.data);

    // 3. Just select everything to debug
    const { data: all, error: errAll } = await supabase.from('businesses').select('*');
    console.log('All Businesses:', all?.length, errAll);
    if (all?.length) console.log('First business location:', all[0].location);
}

testRpc();
