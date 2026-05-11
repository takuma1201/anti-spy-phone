# AntiSpy Phone — macOS Desktop Companion

A native macOS companion app for the AntiSpy Phone (Google Pixel + GrapheneOS).  
Connects via USB/ADB and provides a security dashboard + GrapheneOS hardening settings manager.

## Setup in Xcode

1. Open **Xcode → File → New → Project**
2. Choose **macOS → App**
3. Product Name: `AntiSpyPhone`
4. Interface: **SwiftUI**, Language: **Swift**
5. Minimum deployment: **macOS 14.0**
6. Save into this directory (so it sits alongside the `AntiSpyPhone/` folder)
7. Delete the auto-generated `ContentView.swift` and `<AppName>App.swift`
8. Drag the entire `AntiSpyPhone/` folder into the Xcode project navigator (check "Copy items if needed" = **off**)
9. Add the `LocalAuthentication` framework: Target → General → Frameworks & Libraries → +

Build and run (⌘R). Touch ID prompt appears on first launch.

## Project Structure

```
AntiSpyPhone/
├── AntiSpyPhoneApp.swift        — @main entry point + Touch ID gate
├── ContentView.swift            — NavigationSplitView root (sidebar + 3 sections)
├── DesignSystem/
│   ├── Colors.swift             — Dark premium color palette (#0A0A0F base)
│   └── Typography.swift         — Font helpers + cursor modifier
├── Models/
│   ├── Device.swift             — Connected device model + mock data
│   ├── SecurityEvent.swift      — Log event model + 120 mock events
│   └── HardeningSetting.swift   — GrapheneOS hardening categories + mock settings
└── Views/
    ├── Sidebar/
    │   └── SidebarView.swift    — Device list + nav (Dashboard/Settings/Logs)
    ├── Dashboard/
    │   ├── DashboardView.swift          — Routes connected vs disconnected
    │   ├── ConnectedStateView.swift     — Stat tiles, live indicator, quick status grid
    │   └── DisconnectedStateView.swift  — USB prompt with pulsing ring
    ├── Settings/
    │   ├── SettingsView.swift           — HSplitView: category list + detail panel
    │   └── HardeningCategoryView.swift  — Raw settings: toggles, dropdowns, read-only
    └── Logs/
        ├── LogsView.swift               — Filterable log list (time range + event type)
        └── LogDetailView.swift          — JSON viewer + copy to clipboard
```

## Design System

| Token | Value | Use |
|-------|-------|-----|
| `appBackground` | `#0A0A0F` | Window background |
| `appSurface` | `#13131A` | Cards, panels |
| `appSurfaceElevated` | `#1C1C26` | Sidebar |
| `accentTeal` | `#00E5CC` | Active states, selected nav |
| `statusGreen` | `#00CC88` | Connected, granted |
| `statusRed` | `#FF4466` | Denied, violations |

All system fonts — SF Pro falls back to Hiragino Sans for Japanese automatically.

## Screens

### Dashboard
- **Disconnected**: pulsing gray ring + USB connection prompt (JP/EN bilingual)
- **Connected**: device header with live indicator, 3 stat tiles (ADB bridge, GrapheneOS version, Verified Boot), CTA to Settings, quick status grid of 6 key toggles

### Settings
- Left panel: 6 hardening categories (Sensor Permissions, Network Sandbox, App Sandbox, Storage Scopes, Exploit Mitigations, Attestation)
- Right panel: per-category settings with teal toggle switches, dropdown menus, and read-only monospace badges
- No confirmation dialogs — changes apply silently (power user mode)

### Logs
- Toolbar: time range segmented control + event type filter chips
- Log list: timestamp | type badge | package | detail — virtualized, 120+ rows
- Right panel: selected event detail with timestamp, package, full JSON with copy button

## Next Steps (ADB integration)

Replace mock data with real ADB bridge:
- `Device.mockDevices` → real ADB device list via `adb devices`
- `HardeningCategory.mock` → read props via `adb shell getprop`
- `SecurityEvent.mock()` → stream from `adb logcat -s GrapheneOS`
