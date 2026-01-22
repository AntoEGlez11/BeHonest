import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../../environments/environment';

let client: SupabaseClient;

try {
    console.log('Supabase: Initializing client...');
    if (!environment.supabaseUrl || environment.supabaseUrl.includes('YOUR_SUPABASE')) {
        console.warn('Supabase: Keys are missing! App will run with limited functionality.');
        client = createClient('https://example.supabase.co', 'valid-looking-placeholder-key');
    } else {
        console.log('Supabase: URL found:', environment.supabaseUrl);
        client = createClient(environment.supabaseUrl, environment.supabaseKey);
        console.log('Supabase: Client initialized successfully.');
    }
} catch (error) {
    console.error('Supabase: Failed to initialize client:', error);
    client = createClient('https://example.supabase.co', 'placeholder');
}

export const supabase = client;
