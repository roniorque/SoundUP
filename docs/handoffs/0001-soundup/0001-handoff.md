# Handoff 0001: SoundUp Phase 5 build

**Last updated:** Saturday, Aug 8, 2026, 6:00 PM (UTC+8)
**Engagement:** `soundup`

## What was built

A Swift Package (`Package.swift`) with three targets:

- **SoundUpCore** — pure, fully unit-tested logic with no Core Audio dependency:
  - `VolumeGainCalculator` — slider % (0–200) → gain, with a soft (tanh) limiter above 100%
    (Issues 0002, 0004).
  - `AppVolumeState` — per-app percent/mute state; muting preserves the slider value
    (Issue 0003).
  - `AppVolumeSettingsStore` + `SettingsStorage` — persistence keyed by bundle ID, storage
    injected for testability (Issue 0005).
  - `PlatformSupport` — macOS 14.4+ version check (Issue 0006).
  - `AppLaunchState` — resolves unsupported-OS / permission-denied / ready, with user-facing
    messages (Issue 0006).
  - `AppVolumeController` — coordinates detection → restore-persisted-setting → apply-gain →
    persist-on-change, against the `AudioActivityMonitor` / `ProcessGainController` protocols
    (Issues 0001, 0002, 0003, 0005 integration behavior).
- **SoundUp** — the executable/app target:
  - `CoreAudioProcessMonitor` — real `AudioActivityMonitor` using
    `kAudioHardwarePropertyProcessObjectList` / `kAudioProcessPropertyIsRunningOutput` /
    `kAudioProcessPropertyBundleID` (Issue 0001).
  - `CoreAudioGainController` — real `ProcessGainController` using
    `AudioHardwareCreateProcessTap`, a private aggregate device, and an `AudioDeviceIOProcID`
    block that copies gain-scaled samples from the tap to the default output device
    (Issue 0002).
  - `AppVolumeViewModel`, `SoundUpMenuView`, `SoundUpApp` — the `MenuBarExtra` UI shell wiring
    the above together.
- **SoundUpCoreTests** — 30 tests, all passing, using Swift Testing (`import Testing`), covering
  every pure-logic module and `AppVolumeController`'s coordination behavior against fakes at the
  Core Audio boundary.

## Test results

```
swift test
✔ Test run with 30 tests passed
```

`swift build` succeeds for all three targets (SoundUpCore, SoundUp, SoundUpCoreTests) on this
machine (macOS 15.7.3, Swift 6.1.2, Xcode Command Line Tools only — no full Xcode installed).

## What still needs manual verification (cannot be done in this environment)

This environment has Command Line Tools but not the full Xcode app, and has no way to launch a
GUI app, grant a TCC audio-capture permission, or hear real audio. The following **must** be
verified by hand, in Xcode, on real hardware, before this is considered working:

1. **Issue 0001/0002 — `CoreAudioGainController`.** This is the highest-risk, least-verified
   code in the build. It was written directly against the real Core Audio headers on this
   machine (not from memory) and compiles cleanly, but the following are unverified at runtime:
   - Whether the audio-capture permission prompt appears and behaves as expected on first tap
     creation.
   - Whether the assumption of 32-bit-float, buffer-count-matching samples between the tap and
     the default output device holds for real apps (Spotify, Zoom, Safari, etc.) — if a device
     uses a different sample format or channel layout, the IOProc's direct buffer copy will need
     adjustment.
   - Whether muting the tapped process at the source (`CATapMuteBehavior.muted`) cleanly prevents
     double playback without introducing audible glitches when a control is created/destroyed.
   - Overall audio quality of the limiter curve at various boost levels — the math is unit
     tested, but nobody has listened to it yet.
2. **Xcode project setup.** To run this as a real macOS app (rather than a bare command-line
   executable via `swift run`), you'll need to either open this Swift Package directly in Xcode
   (Xcode can run SwiftUI `App`-based executable targets directly) or wrap it in a full `.xcodeproj`,
   and add:
   - `NSAudioCaptureUsageDescription` in Info.plist (required for the audio-capture permission
     prompt to show a reason).
   - An entitlement enabling audio capture — Apple's Process Tap sample projects use
     `com.apple.security.device.audio-input`-adjacent entitlements; confirm the exact entitlement
     key required against current Apple documentation/sample code when you open this in Xcode,
     since this project currently has no `.entitlements` file at all.
3. **Issue 0006 permission-denied detection.** `AppLaunchState` currently always resolves
   `isPermissionDenied: false` at launch (see `AppVolumeViewModel.init`) — there is no real check
   of the system's TCC permission state yet, since no confirmed public API for that was found in
   the available headers. `CoreAudioGainController.createControl` will currently just log and
   silently no-op if tap creation fails for a permission-related reason, rather than surfacing
   `.permissionDenied` to the UI. Wiring a real permission-denied signal back into
   `AppLaunchState`/`AppVolumeViewModel` is the main remaining gap for Issue 0006 and should be
   the next thing tackled once you can observe the actual failure mode in Xcode.
4. **Issue 0007 (packaging)** was not started — it's HITL and requires your GitHub/Homebrew
   account decisions (see `docs/issues/0001-soundup/0007-unsigned-release-homebrew-tap.md`).

## Recommended next step

Open this package in Xcode on your machine, run it, grant the audio-capture permission when
prompted, and play audio from a couple of apps (e.g. Music/Spotify and a browser tab) to confirm
the slider actually changes their loudness and the boost is audible without harsh distortion. If
`swift test` behavior differs from what's reported here in a full Xcode environment, or the
Core Audio wiring needs fixes, call `phase_6_bug_fix` with what you observe.
