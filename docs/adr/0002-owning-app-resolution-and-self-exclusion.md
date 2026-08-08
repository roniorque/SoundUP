# ADR 0002: Owning-app resolution walks parent PIDs, and SoundUp excludes its own process

**Status:** accepted
**Date:** Saturday, Aug 8, 2026, 9:00 PM (UTC+8)
**Engagement:** `soundup`

`AudioProcessOwnership` resolves the real, user-facing app for a Core Audio process by walking up
its parent-PID chain, trusting only a `.regular` (dock-visible) `NSRunningApplication` match as
confident and falling back to the process's own identity otherwise. This was necessary because
some helper processes (e.g. `com.apple.WebKit.GPU`) are launched via XPC directly by `launchd`,
with no OS-level parent/child relationship to the app using them (e.g. Safari) at all — no amount
of parent-PID walking can find "Safari" for such a process, and `com.apple.WebKit.GPU` is in fact
shared infrastructure used by every WebKit-based app, not owned by any single one. Showing a
generic/helper name in this case is accepted as a limitation, not a bug.

Separately, SoundUp's own process must be excluded from the candidate process list
(`ProcessInfo.processInfo.processIdentifier`, checked in `CoreAudioProcessMonitor`). The moment
SoundUp creates an Aggregate Device to drive real output for a controlled app, Core Audio reports
SoundUp's *own* process as "producing output audio" — without this exclusion, SoundUp would detect
and attempt to tap itself, creating a second, conflicting Aggregate Device on the same physical
output and silently breaking audio for the legitimate control. This is surprising and easy to
accidentally remove during future refactors, hence recorded here.

## Consequences

Removing the self-exclusion guard, or relaxing the `.regular`-policy-first matching back to
accepting any `NSRunningApplication` match at hop 0, will reproduce silence bugs that look
identical to a live Core Audio wiring failure but are actually this self-detection issue — check
here first before re-diagnosing from scratch.
