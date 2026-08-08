# Issue 0005: Persist per-app settings across app relaunch and reboot

**Last updated:** Saturday, Aug 8, 2026, 4:30 PM (UTC+8)
**Engagement:** `soundup`

## Parent

[PRD 0001: SoundUp — per-app volume control and boost](../../PRD/0001-soundup/0001-prd.md)

## What to build

Persist each app's volume/boost slider value and mute state to local disk, keyed by that app's
bundle identifier. Whenever an app starts producing audio again — whether that app was relaunched,
or the whole system was rebooted — SoundUp automatically re-applies the previously stored setting
for that bundle ID without any user action. Persistence logic is implemented as pure,
independently testable read/write logic, separate from the live Core Audio integration.

## Acceptance criteria

- [ ] Setting a given app's volume/boost/mute is saved to local disk, keyed by that app's bundle
      identifier.
- [ ] Quitting and relaunching that same app automatically restores its previously saved setting
      the next time it produces audio, with no user action required.
- [ ] Rebooting the system and reopening that same app automatically restores its previously saved
      setting.
- [ ] Settings for one app are not applied to, or confused with, a different app's bundle
      identifier.
- [ ] The save/restore logic is unit-testable without a live Core Audio Process Tap or running
      audio hardware.

## Blocked by

Issues 0002, 0003, 0004
