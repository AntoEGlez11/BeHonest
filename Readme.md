# beHonest 🚙

A full-stack social platform for rating businesses, built with **Flutter & Supabase**.
*"Waze for Business Ethics"* - Rate honestly, verified by location.

## 🚀 Status: Active Development (Migration Phase)
We are currently migrating from Angular to **Flutter (Windows/Mobile)**.

### ✅ Completed Features
*   **Foundation**:
    *   [x] Project Initialized (Flutter 3.10+)
    *   [x] Architecture Set Up (Feature-first, Riverpod)
    *   [x] Supabase Integration
    *   [x] "Dark Waze" Theme (Dark Mode, Rounded UI)
*   **Core Map**:
    *   [x] Interactive Map (flutter_map + CartoDB Dark Tiles)
    *   [x] Real-time User Geolocation
    *   [x] Animated User Marker (Pulsing 🚙)

### 🚧 Work in Progress
*   [ ] Fetching Businesses from Supabase
*   [ ] Business Markers (🍔, 🔧, etc.)
*   [ ] Registration Flow (Floating Action Button)
*   [ ] User Authentication

## 🛠️ Tech Stack
*   **Framework**: Flutter
*   **Language**: Dart
*   **Backend**: Supabase (PostgreSQL + Auth + Storage)
*   **State Management**: Riverpod (`flutter_riverpod`)
*   **Maps**: `flutter_map` + `latlong2`
*   **Animations**: `flutter_animate`

## 🏃‍♂️ How to Run

### Prerequisites
1.  **Flutter SDK** installed and in PATH.
2.  **Windows Developer Mode** enabled (for symlink support).

### Commands
```bash
# Get dependencies
flutter pub get

# Run on Windows
flutter run -d windows
```

## 📂 Project Structure
```text
lib/
├── main.dart                 # Entry point
├── core/                     # Shared utilities & Theme
├── features/
│   ├── map/                  # Map Logic & Screen
│   ├── auth/                 # Login/Profile
│   └── home/                 # Main Container
└── shared/                   # Common Widgets
```
