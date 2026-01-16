import { Injectable, signal, computed } from '@angular/core';

@Injectable({
    providedIn: 'root'
})
export class GeoService {
    // Signals for state
    private _currentPosition = signal<GeolocationPosition | null>(null);
    private _error = signal<string | null>(null);
    private _isWatching = signal<boolean>(false);

    // Read-only signals
    readonly currentPosition = this._currentPosition.asReadonly();
    readonly error = this._error.asReadonly();
    readonly isWatching = this._isWatching.asReadonly();

    // Derived signal for easy coordinate access
    readonly coordinates = computed(() => {
        const pos = this._currentPosition();
        return pos ? {
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
            accuracy: pos.coords.accuracy
        } : null;
    });

    private watchId: number | null = null;
    private readonly options: PositionOptions = {
        enableHighAccuracy: true,
        timeout: 5000,
        maximumAge: 0
    };

    constructor() { }

    startWatching(): void {
        if (!navigator.geolocation) {
            this._error.set('Geolocation is not supported by your browser.');
            return;
        }

        if (this._isWatching()) return;

        this._isWatching.set(true);
        this._error.set(null);

        this.watchId = navigator.geolocation.watchPosition(
            (position) => {
                this._currentPosition.set(position);
                this._error.set(null);
            },
            (err) => {
                this._error.set(this.getErrorMessage(err));
                console.error('GeoService Error:', err);
            },
            this.options
        );
    }

    stopWatching(): void {
        if (this.watchId !== null) {
            navigator.geolocation.clearWatch(this.watchId);
            this.watchId = null;
        }
        this._isWatching.set(false);
    }

    getCurrentPosition(): Promise<GeolocationPosition> {
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject('Geolocation not supported');
                return;
            }

            navigator.geolocation.getCurrentPosition(
                (pos) => {
                    this._currentPosition.set(pos);
                    resolve(pos);
                },
                (err) => {
                    this._error.set(this.getErrorMessage(err));
                    reject(err);
                },
                this.options
            );
        });
    }

    private getErrorMessage(error: GeolocationPositionError): string {
        switch (error.code) {
            case error.PERMISSION_DENIED:
                return 'User denied the request for Geolocation.';
            case error.POSITION_UNAVAILABLE:
                return 'Location information is unavailable.';
            case error.TIMEOUT:
                return 'The request to get user location timed out.';
            default:
                return 'An unknown error occurred.';
        }
    }
}
