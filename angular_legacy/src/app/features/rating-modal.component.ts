import { Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SupabaseService } from '../core/services/supabase.service';

@Component({
    selector: 'app-rating-modal',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './rating-modal.component.html'
})
export class RatingModalComponent {
    @Input() businessId!: string;
    @Output() closeEvent = new EventEmitter<void>();

    supabase = inject(SupabaseService);

    isHonest: boolean | null = null;
    comment = '';
    selectedFile: File | null = null;
    isSubmitting = false;

    setRating(value: boolean) {
        this.isHonest = value;
    }

    onFileSelected(event: any) {
        const file = event.target.files[0];
        if (file) {
            this.selectedFile = file;
        }
    }

    close() {
        this.closeEvent.emit();
    }

    async submit() {
        if (this.isHonest === null) return;

        try {
            this.isSubmitting = true;
            const ratingData = {
                business_id: this.businessId,
                user_id: 'temp-user-id', // TODO: Use real auth ID
                is_honest: this.isHonest,
                comment: this.comment
            };

            await this.supabase.addRating(ratingData, this.selectedFile || undefined);

            alert('¡Calificación enviada! Gracias por ser honesto.');
            this.close();
        } catch (error) {
            console.error('Error submitting rating:', error);
            alert('Error al enviar la calificación. Intenta de nuevo.');
        } finally {
            this.isSubmitting = false;
        }
    }
}
