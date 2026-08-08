# Issue 0003: Mute/unmute per app

**Last updated:** Saturday, Aug 8, 2026, 4:30 PM (UTC+8)
**Engagement:** `soundup`

## Parent

[PRD 0001: SoundUp — per-app volume control and boost](../../PRD/0001-soundup/0001-prd.md)

## What to build

Each app row in the dropdown gets a dedicated mute control, separate from the volume slider added
in Issue 0002. Muting silences that app's audio immediately without moving or resetting the
slider's position. Unmuting restores the app's audio at exactly the level the slider was already
set to before muting — the slider value is preserved throughout, not reset to 100%.

## Acceptance criteria

- [ ] Each app row has a mute control distinct from its volume slider.
- [ ] Activating mute immediately silences that app's audio.
- [ ] The slider's visual position and stored value do not change when muting.
- [ ] Unmuting restores audio at the slider's preserved level (not reset to 100% or any other
      default).
- [ ] Muting one app does not affect any other app's mute state or volume.

## Blocked by

Issue 0002
