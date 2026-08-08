# ADR 0003: Regular apps are listed while idle; controls are created lazily

**Status:** accepted (filter heuristic still being refined — see Consequences)
**Date:** Saturday, Aug 8, 2026, 9:00 PM (UTC+8)
**Engagement:** `soundup`

Phase 1 originally scoped SoundUp to list only apps *currently* producing audio. This was revised
after build: Core Audio's per-process `isRunningOutput` flag does not reliably reflect audio that
was already playing before SoundUp launched for every app (confirmed via direct testing: correct
for browser tab audio, but Music.app never reports `true` even mid-playback). Rather than chase a
detection fix for every app category, SoundUp now lists any `.regular` (dock-visible)
`NSRunningApplication` unconditionally once running, regardless of `isRunningOutput` — solving the
original complaint for apps like Music that are directly visible to Core Audio's process list.
Background helpers/daemons remain gated on `isRunningOutput`, to avoid listing pure system noise
that isn't cleanly attributable to a real app anyway (see ADR 0002).

Creating a real Process Tap + Aggregate Device (a "live control", per `AppVolumeController`) is
deferred until an app is confirmed playing (`isPlaying == true`) or the user explicitly moves its
slider — listing an idle app costs nothing until it's actually used.

## Consequences

**Known open issue (BUG-2, unresolved):** "any `.regular` app" is broader than intended — Core
Audio's process-object list includes ordinary apps with no real media capability (e.g. Terminal,
a code editor), not just genuine media apps, likely because macOS registers basic audio capability
(e.g. system alert sounds) for nearly any GUI app. The current filter therefore surfaces list
noise beyond what a user would consider a "media app." A tighter heuristic (e.g. only listing an
idle `.regular` app if the user has previously saved a custom setting for it) was proposed but not
yet implemented as of this writing — check `docs/bugs/0001-soundup/BUG-2.md` for current status
before assuming this is resolved.
