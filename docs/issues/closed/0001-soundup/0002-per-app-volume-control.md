# Issue 0002: Adjust an app's volume (0–100%) in real time

**Last updated:** Saturday, Aug 8, 2026, 4:30 PM (UTC+8)
**Engagement:** `soundup`

## Parent

[PRD 0001: SoundUp — per-app volume control and boost](../../PRD/0001-soundup/0001-prd.md)

## What to build

Each app listed in the menu-bar dropdown (from Issue 0001) gets a volume slider ranging 0% (muted)
to 100% (the app's own normal, unmodified output level). Moving the slider creates or reuses a
Core Audio Process Tap on that specific app's process and applies live digital gain corresponding
to the slider position. Adjusting one app's slider must have no audible effect on any other app's
audio or on the system volume. Changes apply in real time as the slider moves, not only on
release.

## Acceptance criteria

- [ ] Each app in the dropdown list shows a volume slider ranging from 0% to 100%.
- [ ] Moving an app's slider changes that app's audible output level in real time.
- [ ] Setting a slider to 0% fully silences that app's output.
- [ ] Setting a slider to 100% restores the app's normal, unmodified output level.
- [ ] Adjusting one app's slider does not change any other app's volume.
- [ ] Adjusting an app's slider does not change the macOS system volume.
- [ ] The gain-mapping logic (slider percentage → applied gain) is implemented as a pure,
      independently unit-testable function, separate from the live Core Audio integration.

## Blocked by

Issue 0001
