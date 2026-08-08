# ADR 0001: Core Audio Process Tap API, not a virtual audio driver

**Status:** accepted
**Date:** Saturday, Aug 8, 2026, 9:00 PM (UTC+8)
**Engagement:** `soundup`

SoundUp uses Apple's Core Audio Process Tap API (`AudioHardwareCreateProcessTap`, macOS 14.2+)
rather than a virtual audio driver (a custom DriverKit extension, or building on an existing one
like BlackHole) to capture and adjust per-app audio. This was chosen during Phase 1 grilling to
keep the project buildable and distributable at $0 cost: a virtual driver requires a system
extension, almost always requiring a paid Apple Developer account for the entitlement Apple grants
to audio drivers, plus a heavier user-approval flow. The Process Tap API needs only a one-time
audio-capture permission prompt.

## Considered Options

- **Custom virtual driver** (what Rogue Amoeba's SoundSource does) — rejected: large engineering
  effort, near-certainly requires a paid Apple Developer account for the driver entitlement.
- **Build on BlackHole** (existing free/open-source virtual driver) — reconsidered mid-build when
  per-app detection proved harder than expected via the Process Tap API alone, but rejected again:
  BlackHole only exposes already-mixed system audio with no per-app attribution, so it would not
  have solved per-app detection at all — only added an install step and complexity.

## Consequences

The Process Tap API's per-process `isRunningOutput` flag does not behave uniformly across apps —
it reliably reflects real-time play/pause state for some apps (e.g. browser tabs) but not others
(e.g. Music.app), and internal helper processes (e.g. `com.apple.WebKit.GPU`) have no OS-level
parent/child link back to their owning app. These are accepted, documented platform constraints of
this architecture — see ADR 0002 and ADR 0003.
