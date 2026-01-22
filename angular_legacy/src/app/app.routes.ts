import { Routes } from '@angular/router';
import { DashboardComponent } from './features/dashboard.component';
import { HomeComponent } from './features/home.component';

export const routes: Routes = [
    { path: '', component: HomeComponent },
    { path: 'dashboard', component: DashboardComponent },
    { path: '**', redirectTo: '' }
];
