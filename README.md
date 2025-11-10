# Afflo - SwiftUI

Afflo iOS app built with SwiftUI and Supabase.

## Project Structure

```
Afflo/
├── Views/          # SwiftUI views
├── Components/     # Reusable UI components
├── Models/         # Data models
├── Services/       # Business logic & API clients
├── Constants/      # Design tokens (Colors, Typography)
└── Resources/      # Assets (fonts, images)
```

## Setup

### Prerequisites
- Xcode 15+
- iOS 17+
- Supabase account (or local instance)

### Installation

1. Clone the repo
2. Open `Afflo.xcodeproj` in Xcode
3. Update Supabase credentials in `Services/SupabaseClient.swift`
4. Build and run

### Supabase Configuration

Currently configured for local Supabase instance (`http://127.0.0.1:54321`).

For production, update the URL and anon key in `SupabaseClient.swift`.

## Design System

### Colors
- Background: `#FFFAF1` (light), `#151718` (dark)
- Primary font: Anonymous Pro

### Typography
- Title: 32px bold
- Subtitle: 20px bold
- Default: 16px regular

## Migration

This is a SwiftUI migration from the original Expo React Native app.
Original Expo codebase: `../afflo-expo`
