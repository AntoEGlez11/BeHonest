import { Injectable, inject } from '@angular/core';
import { supabase } from '../clients/supabase';
import { GeoService } from './geo.service';

export interface Business {
    id?: string;
    name: string;
    category: string;
    description?: string;
    is_informal: boolean;
    location: any; // PostGIS point handling
}

@Injectable({
    providedIn: 'root'
})
export class SupabaseService {

    async createBusiness(business: Partial<Business>, lat: number, lng: number) {
        // Convert lat/lng to PostGIS point format if needed, 
        // but Supabase/PostgREST often handles basic GeoJSON or text WKT.
        // Ideally we use: 'POINT(lng lat)'

        const { data, error } = await supabase
            .from('businesses')
            .insert({
                name: business.name,
                category: business.category,
                is_informal: business.is_informal,
                // PostGIS expects 'POINT(lng lat)'
                location: `POINT(${lng} ${lat})`
            })
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    async getNearbyBusinesses(lat: number, lng: number, radiusMeters: number = 1000) {
        const { data, error } = await supabase
            .rpc('nearby_businesses', {
                lat,
                long: lng,
                radius_meters: radiusMeters
            });

        if (error) throw error;
        return data;
    }
}
