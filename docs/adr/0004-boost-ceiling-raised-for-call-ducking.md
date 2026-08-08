# ADR 0004: Boost ceiling raised to 3000% to counteract macOS call-ducking

**Status:** accepted
**Date:** Saturday, Aug 8, 2026, 10:00 PM (UTC+8)
**Engagement:** `soundup`

`VolumeGainCalculator.maxPercent` was raised from 500% to 3000% (boost fully linear to 2000%,
gently compressed to ~22.5x by 3000%), specifically to give users enough gain headroom to
counteract macOS's own system-wide audio ducking during FaceTime/phone calls. Apple's
`.videoChat`/`.voiceChat` audio session modes automatically enable `duckOthers`, reducing all
non-call audio by roughly 20dB (~10x linear) with no documented, user-facing way to disable it —
confirmed via direct web research and empirical peak-amplitude testing (see BUG-3, closed).

Two more targeted approaches — raising gain alone at the previous 500% ceiling, and making
SoundUp's relay Aggregate Device public instead of private — were tested first and disproven with
direct evidence before this fix. The ducking appears to be enforced at (or very close to) the
physical output stage, not recognizable/exemptable at the stream or device-identity level
available to third-party apps.

## Considered Options

- **Find a way to exempt SoundUp's audio from ducking entirely** — no public API found; two
  concrete attempts failed with direct evidence (see BUG-3).
- **Accept as a documented limitation, no fix** — rejected once a working (if imperfect)
  workaround was found.
- **Raise gain ceiling far beyond normal use (chosen)** — works by brute force: gain high enough
  that even after the OS's ~10x reduction, the result is still audible.

## Consequences

Pushing gain to 20x+ routinely drives the signal far past 0 dBFS (the normal maximum for digital
audio), which will produce audible distortion/clipping at those extreme settings — this is an
accepted, deliberate tradeoff (audibility over fidelity) specifically for the call-ducking use
case, not a general recommendation. Most normal "louder" use cases should stay well under 500%;
the extended range up to 3000% exists specifically for this workaround.
