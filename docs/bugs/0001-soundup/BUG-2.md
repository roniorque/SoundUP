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

## Fix summary

Not yet fixed. Added temporary tagged debug logging (`[DEBUG-poll2]`) to
`CoreAudioProcessMonitor.currentAudioActiveApps()` that logs every candidate process's
`AudioObjectID`, resolved bundle ID (or "nil"/"empty"), and `isRunningOutput` value on every poll,
so the next repro will show exactly where the already-playing process is being lost — whether
it's absent from the list, present but reporting not-running, or present with a bundle ID
problem.

## Files touched

- `Sources/SoundUp/CoreAudioProcessMonitor.swift` — added `[DEBUG-poll2]` per-process logging
  in `currentAudioActiveApps()`.

## Verification

**Command/steps:** Rebuild, start audio in an app, launch SoundUp, capture Console.app filtered
on "SoundUp" for `[DEBUG-poll2]` lines, share the output.
**Result:** Pending — awaiting human repro with instrumented build.
**Verified by:** Pending.
