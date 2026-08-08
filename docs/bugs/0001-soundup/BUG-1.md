# Bug 0001: No audio produced despite successful Core Audio setup

**Status:** open
**behavior_changed:** no
**Last updated:** Saturday, Aug 8, 2026, 7:00 PM (UTC+8)
**Engagement:** `soundup`

## Symptom

After SoundUp creates a per-app volume control for an audio-active app (e.g. a WebKit helper
process, or a video-playing tab), the app appears in the menu bar with a working slider, but no
audio is audible at any slider setting (including 100%, which should be unmodified/unity gain).

## Repro

1. Launch SoundUp.
2. Play a video/audio in a browser tab (or any app).
3. Observe the app/process appear in SoundUp's dropdown with a slider.
4. Move the slider to any value, including 100%.
5. No sound is heard at all.

## Evidence gathered so far

- Console.app filtered on "SoundUp" shows **no error lines** — none of
  `AudioHardwareCreateProcessTap`, `AudioHardwareCreateAggregateDevice`,
  `AudioDeviceCreateIOProcIDWithBlock`, or `AudioDeviceStart` are failing (no
  `"SoundUp: failed to create audio control for ..."` line, which `CoreAudioGainController` logs
  on any of those failing).
- The audio-capture permission prompt appeared and was presumably granted.
- `AVAudioSession_MacOS` logs show `setPlayState Started Input/Output` firing twice with distinct
  session IDs, consistent with two aggregate-device I/O sessions being registered as active (one
  per controlled app) — the OS believes I/O is running.
- No crash, no other error output.

## Hypotheses (ranked)

1. **The IOProc callback block is never actually invoked by Core Audio**, despite
   `AudioDeviceStart` returning `noErr`. Prediction: adding a log inside the IOProc block that
   fires on every call (or every Nth call) will show zero invocations if this is the cause.
2. **The IOProc is invoked, but `inInputData`'s buffers are empty/null** (tap negotiated a
   different stream format than assumed, or the tap simply isn't receiving audio from the target
   process for some other reason), so the gain-copy loop's `guard let ... else { continue }`
   silently skips every buffer, leaving `outOutputData` zeroed (per Core Audio's documented
   zero-initialized buffer contract) — i.e., silence, but "successful" silence.
3. **The aggregate device's private/non-published nature (`kAudioAggregateDeviceIsPrivateKey`)
   or the tap's `muteBehavior = .muted` setting prevents the OS from ever routing this aggregate
   device's output stream to the physical DAC**, even though the sub-device list references the
   real output device — i.e., the audio is being "played" into a device object that never reaches
   speakers/headphones.
4. **A sample format mismatch** (assumed 32-bit float, but the tap or output device actually
   negotiated a different format/channel count), causing the buffer-count or byte-size math to
   silently produce garbage or zero-length copies rather than crashing.

## Findings from instrumented run

Captured `[DEBUG-au1]` output ruled out hypotheses 1 and 2: the IOProc callback fires
continuously (~11ms intervals, consistent with real audio), and both input and output buffers
are non-null with realistic byte sizes (`2ch/4096B`) the entire time. The gain-scaling data path
is confirmed working end to end up to the point of writing into the aggregate device's own
output buffer.

Two new observations narrow the remaining hypotheses:

1. **Two aggregate devices were created simultaneously, both wrapping the same physical
   `BuiltInSpeakerDevice`** — one for `com.apple.WebKit.GPU`, and a second for a process with a
   **blank bundle ID**, created at the exact moment video playback started. The blank-bundle-ID
   process is very likely the actual audio-producing helper — `WebKit.GPU` may not be a real
   audio source at all, meaning the original repro may have been tapping the wrong process.
2. Having two aggregate devices concurrently claim the same physical output device as a
   sub-device is a plausible source of hardware-ownership contention in Core Audio, independent
   of whether the per-process attribution is correct.

## Fix summary (partial)

Filtered out processes with an empty/blank bundle ID from `CoreAudioProcessMonitor`'s active-app
list (they can't be meaningfully displayed, controlled, or persisted per Issue 0005's bundle-ID
keying anyway). This should also collapse the "two simultaneous aggregate devices on one output"
condition down to one control at a time in the common single-app-playing case, isolating whether
that contention was the true cause of the silence, or whether a deeper output-routing issue
remains even with a single aggregate device active.

**Not yet resolved** — root cause of the silence itself is still open. Next diagnostic step: 
retest with exactly one audio-active app so only one aggregate device exists, and confirm whether
audio is now audible.

## Files touched

- `Sources/SoundUp/CoreAudioGainController.swift` — added tagged debug logging (`[DEBUG-au1]`)
  inside the IOProc block and after each setup step.
- `Sources/SoundUp/CoreAudioProcessMonitor.swift` — skip processes with an empty bundle ID when
  building the active-apps list.

## Verification

**Command/steps:** Rebuild (`swift build`), relaunch SoundUp, play audio from exactly one app,
confirm only one `[DEBUG-au1] tap+aggregate created` line appears, and check whether audio is
now audible.
**Result:** Pending — awaiting human retest.
**Verified by:** Pending.
