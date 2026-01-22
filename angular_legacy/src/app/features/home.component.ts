import { Component, inject, ViewChild, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GeoService } from '../core/services/geo.service';
import { BusinessRegistrationComponent } from './business-registration.component';
import { MapComponent } from './map.component';
import { RouterLink } from '@angular/router';

@Component({
    selector: 'app-home',
    standalone: true,
    imports: [CommonModule, BusinessRegistrationComponent, MapComponent, RouterLink],
    templateUrl: './home.component.html'
})
export class HomeComponent implements OnInit {
    geoService = inject(GeoService);
    isRegistering = false;
    isSidebarOpen = false;
    selectedLocation: { lat: number, lng: number } | null = null;
    @ViewChild(MapComponent) mapComponent!: MapComponent;

    toggleSidebar() {
        this.isSidebarOpen = !this.isSidebarOpen;
    }

    // Auto-location on startup
    ngOnInit() {
        console.log('Home: Auto-starting location tracking...');
        this.geoService.startWatching();
    }

    startRegistration() {
        console.log('Home: Starting registration. Resetting location.');
        this.isRegistering = true;
        this.selectedLocation = null;

        // Wait for view to update then enable picker
        setTimeout(() => {
            console.log('Home: Enabling picker');
            this.mapComponent.enableLocationPicker();
        }, 100);
    }

    cancelRegistration() {
        this.isRegistering = false;
        this.selectedLocation = null;
        if (this.mapComponent) this.mapComponent.disableLocationPicker();
    }

    onLocationSelected(coords: { lat: number, lng: number } | null) {
        console.log('Home: Location selected event:', coords);
        this.selectedLocation = coords;
    }

    onBusinessRegistered() {
        this.isRegistering = false;
        this.selectedLocation = null;
        if (this.mapComponent) this.mapComponent.disableLocationPicker();
        // Refresh map markers
        const coords = this.geoService.coordinates();
        if (coords) this.mapComponent.loadNearbyBusinesses(coords.lat, coords.lng);
    }
}
