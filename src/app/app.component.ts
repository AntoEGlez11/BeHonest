import { Component, inject } from '@angular/core';
import { RouterOutlet, RouterLink } from '@angular/router';
import { GeoService } from './core/services/geo.service';
import { DecimalPipe } from '@angular/common';

@Component({
    selector: 'app-root',
    standalone: true,
    imports: [RouterOutlet, DecimalPipe, RouterLink],
    templateUrl: './app.component.html',
    styleUrl: './app.component.css'
})
export class AppComponent {
    geoService = inject(GeoService);

    toggleLocation() {
        if (this.geoService.isWatching()) {
            this.geoService.stopWatching();
        } else {
            this.geoService.startWatching();
        }
    }
}
