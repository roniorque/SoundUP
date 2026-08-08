# Bug 0003: Other apps sound quieter than normal during active FaceTime calls, even at max boost

**Status:** verified
**behavior_changed:** yes
**Last updated:** Saturday, Aug 8, 2026, 10:00 PM (UTC+8)
**Engagement:** `soundup`

## Symptom

While on an active FaceTime call, other apps' audio (e.g. Music) sounded capped/quieter than
normal even when boosted to SoundUp's then-maximum of 500% (~4.25x gain), and confirmed the
system volume itself was already at max.

## Root cause

Confirmed via web research: macOS's `.videoChat`/`.voiceChat` audio session modes (used by
FaceTime) automatically enable `duckOthers`, which reduces all other apps' audio system-wide by
roughly 20dB (~10x linear reduction), as an intentional, undocumented-as-disableable Apple
behavior. Two hypotheses to bypass or exempt SoundUp's own relay audio from this ducking were
tested and disproven with direct evidence:

1. Raising the boost ceiling from 500% to 3000% alone did not escape the cap (tested first,
   before the fix below — see history in this file's earlier revisions if needed).
2. Making the Aggregate Device public instead of private made no difference either.

Peak-amplitude instrumentation (`[DEBUG-peak1]`, since removed) confirmed the tap correctly
captures the app's real (undamped) audio amplitude, and that pushing gain high enough (~20-22x)
produces an output signal loud enough to be clearly audible despite the OS's ~10x reduction
happening downstream. This is not a true bypass of ducking — it is out-muscling it with gain far
beyond the normal audio range (0 dBFS), which necessarily introduces audible distortion/clipping
at those extreme settings. This is an accepted tradeoff for audibility during a call, not a clean
fix.

## Fix summary

Raised `VolumeGainCalculator.maxPercent` from 500 to 3000, with boost now fully linear
(uncompressed) up to 2000% (20x) and only gently compressed from 2000–3000%, reaching ~22.5x at
the top of the range — enough headroom to substantially counteract the ~10x call-ducking
reduction when needed, while normal (non-call) use only requires much lower slider positions to
sound very loud.

## Files touched

- `Sources/SoundUpCore/VolumeGainCalculator.swift` — raised ceiling to 3000%, threshold to 2000%.
- `Tests/SoundUpCoreTests/VolumeGainCalculatorTests.swift` — updated to reflect new range/curve.
- `Sources/SoundUp/CoreAudioGainController.swift` — temporary `[DEBUG-peak1]` instrumentation
  added and removed during diagnosis; no net change to production behavior beyond the ceiling
  change already covered by `VolumeGainCalculator`.

## Verification

**Command/steps:** Rebuilt, boosted Music to ~2200% (~22.5x gain) during an active FaceTime call,
confirmed via `[DEBUG-peak1]` that the tap was capturing real (near-full-scale) input audio and
producing a correspondingly large output signal.
**Result:** Passed — human confirmed "its now working. it was fixed."
**Verified by:** Human confirmation.
