# Issue 0004: Boost above 100% up to 200% with clipping control

**Last updated:** Saturday, Aug 8, 2026, 4:30 PM (UTC+8)
**Engagement:** `soundup`

## Parent

[PRD 0001: SoundUp — per-app volume control and boost](../../PRD/0001-soundup/0001-prd.md)

## What to build

Extend each app's volume slider range from the 0–100% established in Issue 0002 up to 200%.
Values above 100% apply additional digital gain beyond the app's normal unity output level. A soft
limiter engages once gain exceeds 100% to control hard clipping, so boosted audio is audibly
louder without becoming unlistenably distorted. The limiter curve is a pure, testable function
independent of the live Core Audio path.

## Acceptance criteria

- [ ] Each app's slider range extends to 200%, with 100% still representing unmodified output.
- [ ] Setting a slider above 100% produces an audible increase in loudness beyond the app's
      normal maximum.
- [ ] A soft limiter is engaged for any gain value above 100%, measurably reducing hard clipping
      compared to unlimited linear gain at the same setting.
- [ ] The gain-to-output mapping above 100%, including the limiter curve, is implemented as a
      pure, independently unit-testable function.
- [ ] Boosting one app's slider above 100% has no effect on any other app's audio or on system
      volume.

## Blocked by

Issue 0002
