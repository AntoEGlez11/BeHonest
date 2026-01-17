import { Component, ElementRef, OnInit, ViewChild, inject, effect, Output, EventEmitter } from '@angular/core';
import { GeoService } from '../core/services/geo.service';
import { SupabaseService } from '../core/services/supabase.service';
import * as L from 'leaflet';

@Component({
    selector: 'app-map',
    standalone: true,
    template: `
    <div class="relative w-full h-[60vh] rounded-xl overflow-hidden shadow-2xl border border-gray-700">
      <div #mapContainer class="w-full h-full z-10"></div>
      
      <!-- Overlay controls could go here -->
      <div class="absolute bottom-4 right-4 z-[999]">
         <button (click)="locateUser()" class="bg-gray-800 text-white p-3 rounded-full shadow-lg hover:bg-gray-700">
           📍 Me
         </button>
      </div>
    </div>
  `,
    styles: [`
    :host { display: block; }
  `]
})
export class MapComponent implements OnInit {
    @ViewChild('mapContainer', { static: true }) mapContainer!: ElementRef;

    private geoService = inject(GeoService);
    private supabaseService = inject(SupabaseService);
    private map: L.Map | undefined;
    private markers: L.LayerGroup = L.layerGroup();

    constructor() {
        // React to position changes
        effect(() => {
            const coords = this.geoService.coordinates();
            if (coords && this.map) {
                // Optional: Auto-pan to user? Maybe just show marker.
                this.updateUserMarker(coords.lat, coords.lng);
            }
        });
    }

    ngOnInit() {
        this.initMap();
    }

    private initMap() {
        // Default center (Mexico City fallback) or current pos
        const startCoords = this.geoService.coordinates() || { lat: 19.4326, lng: -99.1332 };

        this.map = L.map(this.mapContainer.nativeElement).setView([startCoords.lat, startCoords.lng], 15);

        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
            subdomains: 'abcd',
            maxZoom: 20
        }).addTo(this.map);

        this.markers.addTo(this.map);

        // Load businesses
        this.loadNearbyBusinesses(startCoords.lat, startCoords.lng);
    }

    private userMarker: L.CircleMarker | undefined;

    private updateUserMarker(lat: number, lng: number) {
        if (!this.map) return;

        if (this.userMarker) {
            this.userMarker.setLatLng([lat, lng]);
        } else {
            this.userMarker = L.circleMarker([lat, lng], {
                radius: 8,
                fillColor: '#3b82f6',
                color: '#fff',
                weight: 2,
                opacity: 1,
                fillOpacity: 0.8
            }).addTo(this.map);
        }
    }

    async loadNearbyBusinesses(lat: number, lng: number) {
        try {
            const businesses = await this.supabaseService.getNearbyBusinesses(lat, lng, 15000); // 15km radius

            if (!businesses) return;

            // Clear old markers
            this.markers.clearLayers();

            // Add new markers
            businesses.forEach((b: any) => {
                if (b.lat && b.lng) {
                    const marker = L.marker([b.lat, b.lng])
                        .addTo(this.markers)
                        .bindPopup(`
                            <div class="p-2 min-w-[150px]">
                                <h3 class="font-bold text-lg">${b.name}</h3>
                                <p class="text-sm text-gray-600 mb-1">${b.category}</p>
                                <p class="text-xs text-gray-500">${b.description || 'No description'}</p>
                            </div>
                        `);
                }
            });

        } catch (err) {
            console.error('Error loading businesses:', err);
        }
    }

    // Selection Mode State
    private isSelecting = false;
    private searchRadiusCircle: L.Circle | undefined;
    private selectedLocationMarker: L.Marker | undefined;

    // Output for when a location is picked
    @Output() locationSelected = new EventEmitter<{ lat: number, lng: number } | null>();

    enableLocationPicker() {
        this.isSelecting = true;
        const coords = this.geoService.coordinates();

        if (!coords || !this.map) return;

        // 1. Show the Geofence (10m allowed zone)
        if (this.searchRadiusCircle) this.map.removeLayer(this.searchRadiusCircle);
        this.searchRadiusCircle = L.circle([coords.lat, coords.lng], {
            radius: 10, // 10 meters restricted area
            color: '#10b981', // green-500
            fillColor: '#34d399',
            fillOpacity: 0.2,
            weight: 2,
            dashArray: '5, 5'
        }).addTo(this.map);

        // 2. Zoom in to show the precise area
        this.map.flyTo([coords.lat, coords.lng], 19);

        // 3. Handle Clicks
        this.map.on('click', (e: L.LeafletMouseEvent) => {
            if (!this.isSelecting) return;
            this.handleMapClick(e.latlng);
        });
    }

    disableLocationPicker() {
        this.isSelecting = false;
        if (this.searchRadiusCircle) this.searchRadiusCircle.remove();
        if (this.selectedLocationMarker) this.selectedLocationMarker.remove();
        this.map?.off('click');
        // Reset view logic if needed
    }

    private handleMapClick(latlng: L.LatLng) {
        const userPos = this.geoService.coordinates();
        if (!userPos) return;

        // Calculate distance
        const userLatLng = L.latLng(userPos.lat, userPos.lng);
        const distance = userLatLng.distanceTo(latlng);

        if (distance > 10) {
            // ERROR: Outside zone
            L.popup()
                .setLatLng(latlng)
                .setContent(`<div class="text-red-600 font-bold">🚫 Too far! (${Math.round(distance)}m)</div><div class="text-xs">You must be within 10m of your location.</div>`)
                .openOn(this.map!);
            return;
        }

        // SUCCESS: Valid location
        if (this.selectedLocationMarker) this.selectedLocationMarker.remove();

        this.selectedLocationMarker = L.marker(latlng, {
            draggable: true,
            icon: L.divIcon({
                className: 'bg-transparent',
                html: '📍',
                iconSize: [24, 24],
                iconAnchor: [12, 24]
            })
        }).addTo(this.map!);

        // Emit selected coords
        this.locationSelected.emit({ lat: latlng.lat, lng: latlng.lng });
    }

    locateUser() {
        const coords = this.geoService.coordinates();
        if (coords && this.map) {
            this.map.flyTo([coords.lat, coords.lng], this.isSelecting ? 19 : 16);
        } else {
            this.geoService.startWatching();
        }
    }
}
