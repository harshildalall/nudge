# Nudge — iOS Native App

Native iOS app (Swift + SwiftUI) that turns calendar events into preparation checkpoints so you can leave on time. No cross‑platform code; iOS only.

## Requirements

- Xcode 15+ (Swift 5.9)
- iOS 17.0+ (main app)
- iOS 16.1+ for Lock Screen Live Activity (widget extension)

## Open and Run

1. Open **`Nudge.xcodeproj`** in Xcode.
2. Select the **Nudge** scheme and a simulator or device.
3. Set your **Team** in Signing & Capabilities (Nudge target) so the app can run.
4. Build and run (⌘R).

## Project Structure

```
nudge/
├── Nudge.xcodeproj/
├── Nudge/
│   ├── NudgeApp.swift          # App entry
│   ├── ContentView.swift       # Root (onboarding / setup / main)
│   ├── Models/                 # EventPreset, NudgeEvent, Checkpoint
│   ├── Services/               # Calendar, Notifications, Presets, Checkpoints, Live Activity
│   ├── Shared/                 # NudgeActivityAttributes (for Live Activity)
│   ├── Theme/
│   ├── Views/
│   │   ├── Onboarding/         # Story-driven onboarding
│   │   ├── Setup/              # Calendar sync, Presets, Focus Mode
│   │   ├── Events/             # Event list
│   │   ├── Nudges/             # Active nudge / idle
│   │   ├── Settings/
│   │   └── Edit/                # Edit Event / Edit Preset
│   ├── Info.plist
│   └── Nudge.entitlements
└── NudgeWidgetExtension/       # Lock Screen Live Activity (optional target)
    ├── NudgeActivityAttributes.swift  # Duplicate for widget target
    ├── NudgeLiveActivity.swift
    └── NudgeWidgetBundle.swift
```

## Features (MVP)

- **Onboarding** — Story-driven, no login; then Setup (calendar sync, presets, Focus override).
- **Calendar** — Read-only sync (EventKit). Events list grouped by date with per-event Prep ON/OFF.
- **Presets** — Class, Exam, Interview, Social, Gym, Work (prep time, number of alarms, sound). Editable in Setup and Settings.
- **Checkpoints** — Generated from event start + preset; notifications at each checkpoint; final “LEAVE NOW”.
- **Live Activity** — Lock Screen widget with event name, start time, progress, urgency text, and Done (when widget extension is added).
- **Settings** — Presets, calendar toggles, default nudge sounds, reset presets.

## Adding the Lock Screen Live Activity (Widget Extension)

1. In Xcode: **File → New → Target → Widget Extension**.
2. Name it **NudgeWidgetExtension**, uncheck “Include Configuration App Intent”, finish.
3. Remove the template Swift files from the new target and add instead:
   - From this repo: **NudgeWidgetExtension/NudgeLiveActivity.swift**, **NudgeWidgetExtension/NudgeWidgetBundle.swift**.
   - Add **Nudge/Shared/NudgeActivityAttributes.swift** to the **NudgeWidgetExtension** target as well (same file, two targets).
4. In the widget target’s **Info.plist**, add **NSSupportsLiveActivities** = YES if not present.
5. Build; the main app will start/update the Live Activity when an event is in its prep window.

## Capabilities / Info

- **Calendar**: usage description in `Info.plist` (`NSCalendarsUsageDescription`).
- **Notifications**: requested at launch; Time Sensitive recommended so nudges work with Focus (user must enable in Settings).
- **Live Activity**: `NSSupportsLiveActivities` in app Info.plist; widget extension for Lock Screen UI.

## Data

- All data is local (UserDefaults): presets, event overrides, onboarding/setup state. No server or login.
