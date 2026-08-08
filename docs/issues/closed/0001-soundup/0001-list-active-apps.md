# Issue 0001: List apps currently playing audio in the menu bar

**Last updated:** Saturday, Aug 8, 2026, 4:30 PM (UTC+8)
**Engagement:** `soundup`

## Parent

[PRD 0001: SoundUp — per-app volume control and boost](../../PRD/0001-soundup/0001-prd.md)

## What to build

A menu-bar (status item) SwiftUI app with no dock icon and no separate window. Clicking the
status item opens a dropdown listing every app currently producing audio output on the system.
The list updates dynamically and in real time as apps start or stop producing audio — it is driven
by Core Audio process-audio-activity signals, not a static/manual list. Apps that are running but
not currently producing audio do not appear. This slice has no volume controls yet; it is purely
detection + display.

## Acceptance criteria

- [ ] App runs as a menu-bar-only utility: no dock icon, no separate app window.
- [ ] Opening the status item shows a dropdown list of apps currently producing audio.
- [ ] An app appears in the list within a short, real-time delay of starting to play audio.
- [ ] An app disappears from the list within a short, real-time delay of stopping audio playback.
- [ ] An app that is running but silent does not appear in the list.
- [ ] The app clearly detects and messages when running on macOS below 14.4, since audio
      detection here depends on the Process Tap API family available from Sonoma 14.4 onward.

## Blocked by

None - can start immediately
