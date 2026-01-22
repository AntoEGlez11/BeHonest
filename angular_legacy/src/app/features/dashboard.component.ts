import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { SupabaseService } from '../core/services/supabase.service';

@Component({
    selector: 'app-dashboard',
    standalone: true,
    imports: [CommonModule, RouterLink],
    templateUrl: './dashboard.component.html'
})
export class DashboardComponent implements OnInit {
    supabase = inject(SupabaseService);

    userProfile: any = null;
    vehicles: any[] = [];
    loading = true;
    error: string | null = null;

    async ngOnInit() {
        await this.loadDashboardData();
    }

    async loadDashboardData() {
        try {
            this.loading = true;
            // TODO: Implement actual user session check
            // For now, we'll try to fetch some public data or mock it to verify the view works
            this.userProfile = {
                name: 'Usuario Demo',
                email: 'demo@behonest.com',
                role: 'user'
            };

            // Attempt to get real data if available
            // const user = await this.supabase.getUser(); 
            // if (user) this.userProfile = user;

            this.loading = false;
        } catch (err: any) {
            this.error = 'Error loading dashboard: ' + err.message;
            this.loading = false;
        }
    }

    logout() {
        console.log('Logging out...');
        // this.supabase.signOut();
    }
}
