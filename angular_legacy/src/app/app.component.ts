import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { BottomNavComponent } from './core/components/bottom-nav.component';

@Component({
    selector: 'app-root',
    standalone: true,
    imports: [RouterOutlet, BottomNavComponent],
    templateUrl: './app.component.html'
})
export class AppComponent { }
