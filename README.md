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
3. **Configure Supabase credentials:**
   ```bash
   cp Afflo/Config.plist.example Afflo/Config.plist
   ```
   Then edit `Afflo/Config.plist` with your Supabase URL and anon key
4. Add `Config.plist` to Xcode project (right-click Afflo folder → Add Files)
5. Build and run

### Supabase Configuration

The app uses `Afflo/Config.plist` for environment configuration (gitignored).

**Config.plist structure:**
```xml
<dict>
    <key>SUPABASE_URL</key>
    <string>YOUR_SUPABASE_URL</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>YOUR_ANON_KEY</string>
    <key>USE_LOCAL</key>
    <true/> <!-- or <false/> for production -->
</dict>
```

- Set `USE_LOCAL` to `true` for local Supabase (`http://127.0.0.1:54321`)
- Set `USE_LOCAL` to `false` to use production credentials from Config.plist

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
