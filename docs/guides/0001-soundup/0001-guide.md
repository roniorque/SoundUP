# Guide 0001: Building and running SoundUp locally

**Last updated:** Saturday, Aug 8, 2026, 6:00 PM (UTC+8)
**Engagement:** `soundup`

## Requirements

- macOS 14.4 (Sonoma) or later.
- Xcode (full app, not just Command Line Tools) — required to run a `MenuBarExtra` app with a
  real audio-capture permission prompt and to add entitlements/Info.plist keys.

## Running tests (no Xcode required)

From the repository root:

```
swift test
```

This runs all 30 tests in `Tests/SoundUpCoreTests` against the pure logic in `SoundUpCore`
(gain/limiter math, mute state, persistence, OS-version/launch-state checks, and the
`AppVolumeController` coordination logic against fakes). No audio hardware or permissions are
needed for this.

## Building the executable (no Xcode required)

```
swift build
swift run SoundUp
```

This compiles and can run the app as a bare command-line process. On a real Mac this should show
a menu-bar icon (a speaker glyph), but running it this way has not been manually verified end to
end — see the Phase 5 handoff for what still needs checking in Xcode.

## Opening in Xcode

1. Open the package folder in Xcode: `File → Open…` and select the folder containing
   `Package.swift`. Xcode will treat it as a Swift Package and let you run the `SoundUp`
   executable target directly.
2. Before the audio-capture permission prompt will work correctly, add to the `SoundUp` target's
   build settings / Info.plist:
   - `NSAudioCaptureUsageDescription` — a string explaining why SoundUp needs this permission
     (e.g. "SoundUp needs this permission to adjust the volume of individual apps.").
   - The entitlement required for Core Audio process taps. Confirm the exact key against current
     Apple documentation/sample code (e.g. the WWDC24 "Meet Audio Taps" sample) when you're in
     Xcode, since this repository does not yet include an `.entitlements` file.
3. Run the app (⌘R). Play audio from another app (e.g. Music, Spotify, or a browser tab) and
   confirm it appears in SoundUp's menu-bar dropdown.
4. Move that app's slider and confirm its volume changes live, independently of system volume and
   other apps. Try muting/unmuting, and try boosting above 100% to confirm it gets louder without
   becoming unlistenably distorted.
5. Quit and relaunch the same app, and confirm SoundUp restores its previous setting automatically
   (Issue 0005).

## Project layout

```
Package.swift
Sources/
  SoundUpCore/   — pure logic, no Core Audio dependency, fully unit tested
  SoundUp/       — executable target: SwiftUI MenuBarExtra shell + real Core Audio integration
Tests/
  SoundUpCoreTests/ — 30 tests covering SoundUpCore
docs/
  ideas/, PRD/, issues/, handoffs/, guides/  — SDLC planning artifacts
.cursor/rules/project-policy.mdc — git/testing/security/code-style policy
```

## If something doesn't work

If the Core Audio integration (`CoreAudioGainController`, `CoreAudioProcessMonitor`) doesn't
behave as expected once you can actually run and hear it, that's expected to need iteration — it
was written directly against this machine's real Core Audio headers but has never been run
against live audio hardware. Call `phase_6_bug_fix` with what you observe (which app, what
happened vs. what was expected) and it'll be tracked as a bug slice against Issue 0001/0002.
