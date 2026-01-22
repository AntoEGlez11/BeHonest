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

    async getNearbyBusinesses(lat: number, lng: number, radiusMeters: number = 20000) {
        const { data, error } = await supabase
            .rpc('nearby_businesses', {
                lat,
                long: lng,
                radius_meters: radiusMeters
            });

        if (error) throw error;
        return data;
    }

    async addRating(rating: any, evidenceFile?: File) {
        let evidenceUrl = null;

        // 1. Upload Evidence if exists
        if (evidenceFile) {
            const fileName = `${Date.now()}_${evidenceFile.name}`;
            const { data, error } = await supabase.storage
                .from('evidence-bucket')
                .upload(fileName, evidenceFile);

            if (error) {
                console.error('Upload failed:', error);
                throw error;
            }

            // Get Public URL
            const { data: publicUrlData } = supabase.storage
                .from('evidence-bucket')
                .getPublicUrl(fileName);

            evidenceUrl = publicUrlData.publicUrl;
        }

        // 2. Insert Rating
        const { data, error } = await supabase
            .from('ratings')
            .insert({
                business_id: rating.business_id,
                user_id: rating.user_id, // TODO: Get actual logged in user
                is_honest: rating.is_honest,
                comment: rating.comment,
                evidence_url: evidenceUrl
            })
            .select()
            .single();

        if (error) throw error;
        return data;
    }
}
