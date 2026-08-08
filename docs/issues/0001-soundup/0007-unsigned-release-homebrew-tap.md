# Issue 0007: Unsigned build + GitHub release + Homebrew tap

**Last updated:** Saturday, Aug 8, 2026, 4:30 PM (UTC+8)
**Engagement:** `soundup`

## Parent

[PRD 0001: SoundUp — per-app volume control and boost](../../PRD/0001-soundup/0001-prd.md)

## What to build

Produce a distributable, unsigned build of SoundUp (no Apple Developer Program membership, no
notarization) and publish it as a GitHub release on the main SoundUp repository. Create a
companion Homebrew tap repository containing a Cask formula so users can install via
`brew tap` + `brew install --cask`, which strips the quarantine attribute and avoids the standard
Gatekeeper "unidentified developer" block. Document, in the main repo's README, the manual
one-time Gatekeeper bypass steps needed for users who download the release zip directly instead
of using Homebrew.

This slice is HITL: creating and naming the Homebrew tap repository, and any related GitHub
account/org decisions, require a human choice.

## Acceptance criteria

- [ ] A built, unsigned `.app` (or equivalent packaged artifact) is attached to a GitHub release
      on the main SoundUp repository.
- [ ] A separate Homebrew tap repository exists with a working Cask formula referencing that
      release artifact.
- [ ] Running `brew tap <owner>/<tap>` followed by `brew install --cask soundup` successfully
      installs the app without triggering the Gatekeeper "unidentified developer" block.
- [ ] The main repository's README documents the manual Gatekeeper bypass steps for users who
      download the release zip directly instead of using Homebrew.
- [ ] The README states clearly that no Apple Developer Program fee or App Store listing is
      required to install or use the app.

## Blocked by

Issues 0001, 0002, 0003, 0004, 0005, 0006
