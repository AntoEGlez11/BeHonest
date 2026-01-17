import { Component, inject, signal, Input, Output, EventEmitter } from '@angular/core';
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
    private supabaseService = inject(SupabaseService);

    @Input() forcedLocation!: { lat: number, lng: number };
    @Output() cancelled = new EventEmitter<void>();
    @Output() registered = new EventEmitter<void>();

    isSubmitting = signal(false);
    errorMessage = signal<string | null>(null);

    form = this.fb.group({
        name: ['', [Validators.required, Validators.minLength(3)]],
        category: ['Informal', Validators.required],
        description: [''],
        is_informal: [true]
    });

    async onSubmit() {
        if (this.form.invalid) return;

        if (!this.forcedLocation) {
            this.errorMessage.set('Location is missing.');
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
                this.forcedLocation.lat,
                this.forcedLocation.lng
            );

            this.registered.emit();

        } catch (err: any) {
            this.errorMessage.set(err.message || 'Failed to create business');
        } finally {
            this.isSubmitting.set(false);
        }
    }

    onCancel() {
        this.cancelled.emit();
    }
}
