import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../../environments/environment';

let client: SupabaseClient;

try {
    if (!environment.supabaseUrl || environment.supabaseUrl.includes('YOUR_SUPABASE')) {
        console.warn('Supabase keys are missing! App will run with limited functionality.');
        // Initialize with a dummy url to prevent crash, but requests will fail
        client = createClient('https://example.supabase.co', 'valid-looking-placeholder-key');
    } else {
        client = createClient(environment.supabaseUrl, environment.supabaseKey);
    }
} catch (error) {
    console.error('Failed to initialize Supabase client:', error);
    // Fallback to prevent app crash
    client = createClient('https://example.supabase.co', 'placeholder');
}

export const supabase = client;
