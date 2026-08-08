# Issue 0006: Permission & unsupported-OS handling

**Last updated:** Saturday, Aug 8, 2026, 4:30 PM (UTC+8)
**Engagement:** `soundup`

## Parent

[PRD 0001: SoundUp — per-app volume control and boost](../../PRD/0001-soundup/0001-prd.md)

## What to build

Handle the two failure paths around Core Audio's Process Tap / audio-capture permission cleanly,
without crashing or failing silently:

1. The user denies the macOS system permission prompt required to tap other apps' audio.
2. The app is run on a macOS version earlier than 14.4, where the Process Tap API family does not
   exist.

In both cases, the app should detect the condition and present clear in-app messaging explaining
what happened and, where applicable, how to resolve it (e.g. re-granting permission in System
Settings). The app must not crash or hang in either case.

## Acceptance criteria

- [ ] If the user denies the audio-capture permission prompt, the app detects this and shows a
      clear message rather than crashing, hanging, or silently doing nothing.
- [ ] The denial-state message explains how the user can grant the permission later (e.g. via
      System Settings) if they change their mind.
- [ ] On launch, the app detects if it is running on macOS earlier than 14.4 and shows a clear,
      specific message that the OS version is unsupported, rather than crashing or behaving
      unpredictably.
- [ ] Neither failure path leaves the menu-bar item in a broken or unresponsive state.

## Blocked by

Issue 0001
