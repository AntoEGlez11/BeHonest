import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { GeoService } from '../core/services/geo.service';
import { SupabaseService } from '../core/services/supabase.service';
import { Router } from '@angular/router';
import { DecimalPipe } from '@angular/common';

@Component({
    selector: 'app-business-registration',
    standalone: true,
    imports: [ReactiveFormsModule, DecimalPipe],
    templateUrl: './business-registration.component.html',
    styleUrl: './business-registration.component.css'
})
export class BusinessRegistrationComponent {
    private fb = inject(FormBuilder);
    private geoService = inject(GeoService);
    private supabaseService = inject(SupabaseService);
    private router = inject(Router);

    isSubmitting = signal(false);
    errorMessage = signal<string | null>(null);

    form = this.fb.group({
        name: ['', [Validators.required, Validators.minLength(3)]],
        category: ['Informal', Validators.required],
        description: [''],
        is_informal: [true]
    });

    // Expose GeoService signals to template
    currentPosition = this.geoService.currentPosition;
    locationError = this.geoService.error;

    constructor() {
        this.geoService.startWatching();
    }

    async onSubmit() {
        if (this.form.invalid) return;

        // Validate we have location
        const coords = this.geoService.coordinates();
        if (!coords) {
            this.errorMessage.set('We need your location to register the business.');
            return;
        }

        this.isSubmitting.set(true);
        this.errorMessage.set(null);

        try {
            const formValue = this.form.value;
            const businessData = {
                name: formValue.name!,
                category: formValue.category!,
                description: formValue.description || '',
                is_informal: formValue.is_informal!
            };

            await this.supabaseService.createBusiness(
                businessData,
                coords.lat,
                coords.lng
            );

            // Success! Redirect to home or dashboard
            // For now, simple alert or redirect
            alert('Business Created Successfully!');
            this.router.navigate(['/']);

        } catch (err: any) {
            this.errorMessage.set(err.message || 'Failed to create business');
        } finally {
            this.isSubmitting.set(false);
        }
    }
}
