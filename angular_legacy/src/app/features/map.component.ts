import { Component, ElementRef, OnInit, ViewChild, inject, effect, Output, EventEmitter, NgZone } from '@angular/core';
import { GeoService } from '../core/services/geo.service';
import { SupabaseService } from '../core/services/supabase.service';
import { RatingModalComponent } from './rating-modal.component';
import { CommonModule } from '@angular/common';
import * as L from 'leaflet';

@Component({
    selector: 'app-map',
    standalone: true,
    imports: [CommonModule, RatingModalComponent],
    template: `
    <div class="relative w-full h-full">
      <div #mapContainer class="w-full h-full z-0 outline-none"></div>
      
      <!-- Overlay controls (Legacy - now handled by Home, but keeping 'Me' as backup) -->
      <!-- <div class="absolute bottom-4 right-4 z-[999]">
         <button (click)="locateUser()" class="bg-gray-800 text-white p-3 rounded-full shadow-lg hover:bg-gray-700">
           📍 Me
         </button>
      </div> -->

      <!-- Rating Modal (Keeping as integrated component for now) -->
      <app-rating-modal *ngIf="ratingBusinessId" 
        [businessId]="ratingBusinessId" 
        (closeEvent)="closeRatingModal()">
      </app-rating-modal>
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
            console.log('Coords:', coords);
            if (coords && this.map) {
                // Optional: Auto-pan to user? Maybe just show marker.
                this.updateUserMarker(coords.lat, coords.lng);
            }
        });
    }

    // Rating Logic
    ratingBusinessId: string | null = null;
    private zone = inject(NgZone);

    ngOnInit() {
        console.log('MapComponent Initialized v3 - Fixed NgZone');
        this.initMap();

        // Global bridge for Leaflet popup clicks
        (window as any).rateBusiness = (id: string) => {
            this.zone.run(() => {
                this.openRatingModal(id);
            });
        };
    }

    openRatingModal(businessId: string) {
        this.ratingBusinessId = businessId;
    }

    closeRatingModal() {
        // Reset state
        this.ratingBusinessId = null;
        // Re-focus map for UX?
    }

    private initMap() {
        // Fix Leaflet Default Icon 404 (Use CDN for reliability)
        const iconRetinaUrl = 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png';
        const iconUrl = 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png';
        const shadowUrl = 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png';
        const iconDefault = L.icon({
            iconRetinaUrl,
            iconUrl,
            shadowUrl,
            iconSize: [25, 41],
            iconAnchor: [12, 41],
            popupAnchor: [1, -34],
            tooltipAnchor: [16, -28],
            shadowSize: [41, 41]
        });
        L.Marker.prototype.options.icon = iconDefault;

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

    private userMarker: L.Marker | undefined;

    private updateUserMarker(lat: number, lng: number) {
        if (!this.map) return;

        if (this.userMarker) {
            this.userMarker.setLatLng([lat, lng]);
        } else {
            // Waze-style User Icon (Car)
            const userIcon = L.divIcon({
                className: 'bg-transparent',
                html: `<div class="relative flex items-center justify-center transform hover:scale-110 transition-transform duration-300">
                         <div style="font-size: 40px; filter: drop-shadow(0 4px 6px rgba(0,0,0,0.5));">🚙</div>
                         <div class="absolute -bottom-1 w-8 h-2 bg-black/30 rounded-full blur-sm"></div>
                       </div>`,
                iconSize: [40, 40],
                iconAnchor: [20, 20]
            });

            this.userMarker = L.marker([lat, lng], { icon: userIcon }).addTo(this.map);
        }

        // Draw/Update Radius Circle (30m) - Keep it subtle but visible
        if (this.radiusCircle) {
            this.radiusCircle.setLatLng([lat, lng]);
        } else {
            this.radiusCircle = L.circle([lat, lng], {
                radius: 30,
                color: '#10b981', // Emerald-500
                fillColor: '#10b981',
                fillOpacity: 0.1,
                weight: 1,
                dashArray: '4, 4'
            }).addTo(this.map);
        }
    }

    async loadNearbyBusinesses(lat: number, lng: number) {
        try {
            const businesses = await this.supabaseService.getNearbyBusinesses(lat, lng, 20000); // 20km

            if (!businesses) return;

            // Clear old markers
            this.markers.clearLayers();

            // Add new markers
            businesses.forEach((b: any) => {
                if (b.lat && b.lng) {

                    // Choose Emoji based on Category
                    let iconEmoji = '🏪'; // Default Store
                    if (b.category === 'Food') iconEmoji = '🍔';
                    else if (b.category === 'Service') iconEmoji = '🔧';
                    else if (b.category === 'Transport') iconEmoji = '🚕';
                    else if (b.category === 'Entertainment') iconEmoji = '🍿';
                    else if (b.is_informal) iconEmoji = '🌮'; // Street food/Informal

                    const businessIcon = L.divIcon({
                        className: 'bg-transparent',
                        html: `<div class="group relative flex flex-col items-center justify-center transform hover:-translate-y-2 transition-transform duration-300 cursor-pointer">
                                 <div class="text-3xl filter drop-shadow-md">${iconEmoji}</div>
                                 <div class="opacity-0 group-hover:opacity-100 absolute -top-8 bg-gray-900 text-white text-xs font-bold px-2 py-1 rounded-full whitespace-nowrap transition-opacity pointer-events-none">
                                   ${b.name}
                                 </div>
                               </div>`,
                        iconSize: [30, 30],
                        iconAnchor: [15, 15]
                    });

                    const marker = L.marker([b.lat, b.lng], { icon: businessIcon })
                        .addTo(this.markers)
                        .bindPopup(`
                            <div class="p-3 bg-gray-900 text-white rounded-xl min-w-[200px] border border-gray-700 shadow-xl">
                                <div class="text-center mb-2">
                                    <div class="text-3xl mb-1">${iconEmoji}</div>
                                    <h3 class="font-bold text-lg leading-tight text-white mb-1">${b.name}</h3>
                                    <div class="inline-block px-2 py-0.5 rounded-full text-[10px] uppercase font-bold tracking-wider ${b.is_informal ? 'bg-orange-500/20 text-orange-300' : 'bg-blue-500/20 text-blue-300'}">
                                        ${b.category}
                                    </div>
                                </div>
                                
                                <p class="text-xs text-gray-400 mb-4 text-center italic line-clamp-2">"${b.description || 'Sin descripción detalada...'}"</p>
                                
                                <button onclick="window.rateBusiness('${b.id || 'temp-id'}')" 
                                  class="w-full py-2.5 bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-400 hover:to-teal-400 text-white rounded-full font-black text-sm shadow-lg active:scale-95 transition-all flex items-center justify-center gap-2">
                                  <span>⭐</span> CALIFICAR
                                </button>
                            </div>
                        `, {
                            maxWidth: 240,
                            closeButton: false,
                            className: 'custom-dark-popup'
                        });
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
            radius: 30, // 30 meters restricted area
            color: '#10b981', // green-500
            fillColor: '#34d399',
            fillOpacity: 0.15,
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

        if (distance > 30) {
            // ERROR: Outside zone
            L.popup({
                closeButton: false,
                className: 'error-popup'
            })
                .setLatLng(latlng)
                .setContent(`<div class="text-red-600 font-bold bg-white px-3 py-2 rounded shadow-lg text-center">
                                🚫 Too far! (v2)<br>
                                <span class="text-xs font-normal text-gray-500">Must be within 30m</span>
                             </div>`)
                .openOn(this.map!);
            return;
        }

        // SUCCESS: Valid location
        if (this.selectedLocationMarker) this.selectedLocationMarker.remove();

        this.selectedLocationMarker = L.marker(latlng, {
            draggable: true,
            icon: L.divIcon({
                className: 'bg-transparent',
                html: `<div class="relative">
                         <div class="text-4xl filter drop-shadow-lg transform -translate-x-1/2 -translate-y-full">📍</div>
                       </div>`,
                iconSize: [40, 40],
                iconAnchor: [20, 40]
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
