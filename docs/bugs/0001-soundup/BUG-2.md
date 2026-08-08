# Bug 0002: Apps already playing audio before SoundUp launches are not detected

**Status:** open
**behavior_changed:** no
**Last updated:** Saturday, Aug 8, 2026, 8:30 PM (UTC+8)
**Engagement:** `soundup`

## Symptom

If an app is already playing audio *before* SoundUp is launched, it does not appear in SoundUp's
menu-bar dropdown — even after an immediate poll at launch plus follow-up polls at 0.3s/0.8s/1.5s
were added as a first attempt at a fix. Only apps that *start* playing audio after SoundUp is
already running are detected.

## Repro

1. Start playing audio in an app (e.g. Music, Spotify, a browser tab).
2. Leave it playing continuously.
3. Launch SoundUp (`swift run SoundUp`).
4. Open SoundUp's dropdown.
5. The already-playing app does not appear, even after several seconds.

## Attempted fix (insufficient)

Added an immediate `poll()` in `CoreAudioProcessMonitor.start()` (already existed) plus three
follow-up polls shortly after launch, to rule out a startup race condition in Core Audio
settling `kAudioProcessPropertyIsRunningOutput` for already-running processes. This did not
resolve the symptom — human confirmed "it still not detecting idle app with audio."

## Hypotheses (ranked)

1. **The already-playing process's `AudioObjectID` isn't appearing in
   `kAudioHardwarePropertyProcessObjectList` at all** at query time, for a reason unrelated to
   simple startup timing (e.g. the process object is only registered under different
   circumstances than assumed).
2. **The process appears in the list, but `kAudioProcessPropertyIsRunningOutput` reports `false`**
   for it despite continuous playback — meaning this property does not mean what
   `CoreAudioProcessMonitor.isRunningOutput` assumes, or requires a different query approach
   (e.g. per-stream state rather than a simple boolean).
3. **The process appears with a valid `bundleID`, but is being filtered out elsewhere** (e.g. the
   BUG-1 fix that skips empty bundle IDs, or the dedup `Set`, incorrectly excluding it).

## Root cause confirmed

`[DEBUG-poll2]` logging showed `com.apple.Music` present in the process list on every poll, but
`isRunningOutput` consistently `false` despite continuous playback. Human confirmed via manual
pause/resume test: the property flips `true` immediately on Play and `false` immediately on
Pause, but never becomes `true` on its own for audio that was already playing before SoundUp
started polling. This confirms `kAudioProcessPropertyIsRunningOutput` is **edge-triggered on
play/start transitions**, not a continuous "is this making sound right now" signal — a platform
characteristic of this fairly new Core Audio API, not a bug in SoundUp's polling logic. No amount
of re-polling or polling more frequently can fix this, since the underlying property value itself
is stale for already-running streams.

Considered and rejected: replacing the architecture with a virtual audio driver (BlackHole-based
or custom), matching how SoundSource does per-app detection. Rejected because BlackHole receives
already-mixed system audio with no per-app attribution, so it would not solve per-app "already
playing" detection at all — it would only add an install step and complexity without fixing the
actual symptom. The per-process Tap API remains the right foundation; this specific edge-triggering
quirk is accepted as a **known limitation** of that architecture (documented for users: pause and
resume an already-playing app once to have it detected).

## Fix summary

Debug instrumentation (`[DEBUG-poll2]`) removed after diagnosis completed. This bug's original
scope (already-playing detection) is accepted as a documented limitation rather than fixed — see
Guide 0001 for the user-facing note.

A separate, real improvement was made in the same pass: apps are now grouped and displayed by
their **actual owning application** (e.g. "Safari") when that owning app is genuinely
dock-visible (`NSRunningApplication.activationPolicy == .regular`), resolved by walking up the
process's parent chain. Some helpers (notably `com.apple.WebKit.GPU`) are launched via XPC
directly by `launchd`, with no OS-level parent/child path to their using app at all — for these,
SoundUp falls back to the helper's own (sometimes shared/generic) identity, which is an accepted
limitation, not a bug: `com.apple.WebKit.GPU` is genuinely shared infrastructure used by every
WebKit-based app, not owned by any single one.

A second, more serious regression was found and fixed during this same investigation:
**SoundUp's own process was detecting itself as a controllable "app"** once it started actively
driving an aggregate device's IOProc (creating that IO activity makes Core Audio report SoundUp's
own process as "producing output audio"). This caused SoundUp to create a second, self-referential
tap/aggregate device (attributed to whatever app launched it, e.g. Terminal) competing for the
same physical output as the legitimate control — reproducing BUG-1's dual-aggregate-device
conflict and breaking audio again. Fixed by excluding SoundUp's own PID
(`ProcessInfo.processInfo.processIdentifier`) from the candidate process list.

Also tested and ruled out: `kAudioProcessPropertyDevices` (a process's connected-device list) as
an alternative continuous "is playing" signal — it stayed empty (`0`) even for processes with
`isRunningOutput=true`, so it does not help distinguish already-playing state either.

## Files touched

- `Sources/SoundUp/CoreAudioProcessMonitor.swift` — apps are now grouped/displayed by resolved
  owning application via `AudioProcessOwnership`; excludes SoundUp's own process from the
  candidate list.
- `Sources/SoundUp/CoreAudioGainController.swift` — matches all audio processes belonging to the
  resolved owning app (not each process's own self-reported bundle ID) when building a control.
- `Sources/SoundUp/AudioProcessOwnership.swift` (new) — resolves the owning `NSRunningApplication`
  for a given Core Audio process object (only trusting `.regular`-policy matches as confident,
  otherwise walking further up), and exposes a shared PID lookup.

## Final resolution: scope change, not a pure bug fix

After confirming the self-detection fix resolved audio (human: "its now fixed"), the human raised
the original ask again: they want SoundUp to behave like SoundSource, showing apps in the list
even when not currently playing — not just detecting already-playing audio at launch. This
reverses the Phase 1 decision to list only actively-playing apps. Confirmed with the human and
implemented as a scope change:

- Genuine, dock-visible apps (`NSRunningApplication.activationPolicy == .regular`, e.g. Music)
  are now always listed once running, regardless of `isRunningOutput` — solving the original
  complaint directly, since Music is directly visible to Core Audio's process list.
- Background helpers/daemons and shared processes (`.accessory`/`.prohibited`, e.g. a browser's
  WebKit.GPU) are still only listed while actively producing output, to avoid cluttering the list
  with system noise that isn't cleanly attributable to a real app anyway.
- `AudioActiveApp` gained an `isPlaying` flag. `AppVolumeController` now defers creating the real
  (resource-costly) Core Audio tap/aggregate control until an app is confirmed playing or the user
  explicitly moves its slider — so listing an idle app costs nothing until it's actually used.
  Covered by 4 new unit tests (list-without-control, transition-to-playing creates control,
  slider-interaction creates control immediately, never-controlled app doesn't trigger a spurious
  `removeControl`).

## Files touched (final)

- `Sources/SoundUpCore/AudioActiveApp.swift` — added `isPlaying` flag.
- `Sources/SoundUpCore/AppVolumeController.swift` — lazy gain-control creation keyed on
  `isPlaying` or explicit user interaction.
- `Sources/SoundUp/CoreAudioProcessMonitor.swift` — lists `.regular`-policy apps unconditionally;
  gates other processes on `isRunningOutput`; excludes SoundUp's own process.
- `Sources/SoundUp/CoreAudioGainController.swift`, `AudioProcessOwnership.swift` — unchanged from
  prior fix in this bug.

## Verification

**Command/steps:** Rebuild, confirm `swift build`/`swift test` pass (36/36), then manually confirm:
Music (or another regular app) appears in SoundUp's dropdown immediately once running, even before
pressing play, and that moving its slider before it plays anything still works once it does play.
**Result:** Build and unit tests pass (36/36). Manual verification pending human confirmation.
**Verified by:** Pending.
