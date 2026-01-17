import { Component, inject, ViewChild } from '@angular/core';
import { RouterOutlet, RouterLink } from '@angular/router';
import { GeoService } from './core/services/geo.service';
import { DecimalPipe } from '@angular/common';
import { CommonModule } from '@angular/common';
import { BusinessRegistrationComponent } from './features/business-registration.component';
import { MapComponent } from './features/map.component';

@Component({
    selector: 'app-root',
    standalone: true,
    imports: [RouterOutlet, DecimalPipe, RouterLink, MapComponent, CommonModule, BusinessRegistrationComponent],
    templateUrl: './app.component.html'
})
export class AppComponent {
    geoService = inject(GeoService);
    isRegistering = false;
    selectedLocation: { lat: number, lng: number } | null = null;
    @ViewChild(MapComponent) mapComponent!: MapComponent;

    toggleLocation() {
        if (this.geoService.isWatching()) {
            this.geoService.stopWatching();
        } else {
            this.geoService.startWatching();
        }
    }

    startRegistration() {
        console.log('App: Starting registration. Resetting location.');
        this.isRegistering = true;
        this.selectedLocation = null;
        console.log('App: isRegistering:', this.isRegistering, 'selectedLocation:', this.selectedLocation);

        // Wait for view to update then enable picker
        setTimeout(() => {
            console.log('App: Enabling picker');
            this.mapComponent.enableLocationPicker();
        }, 100);
    }

    cancelRegistration() {
        this.isRegistering = false;
        this.selectedLocation = null;
        this.mapComponent.disableLocationPicker();
    }

    onLocationSelected(coords: { lat: number, lng: number } | null) {
        console.log('App: Location selected event:', coords);
        this.selectedLocation = coords;
    }

    onBusinessRegistered() {
        this.isRegistering = false;
        this.selectedLocation = null;
        this.mapComponent.disableLocationPicker();
        // Refresh map markers
        const coords = this.geoService.coordinates();
        if (coords) this.mapComponent.loadNearbyBusinesses(coords.lat, coords.lng);
    }
}
