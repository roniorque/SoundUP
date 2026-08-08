# Security Report 0001: SoundUp

**Last updated:** Saturday, Aug 8, 2026, 11:00 PM (UTC+8)
**Engagement:** `soundup`
**Scope:** Engagement (all zones touched by this build)
**Status:** complete

## Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High     | 0 |
| Medium   | 1 |
| Low      | 1 |
| Info     | 3 |

No Critical or High findings. Policy severity floor (`.cursor/rules/project-policy.mdc`: no
Critical/High may ship) is satisfied.

## Coverage

| Zone | Total | Tested | Skipped | Pending |
|------|-------|--------|---------|---------|
| app (Sources/SoundUp + Sources/SoundUpCore) | 14 | 14 | 0 | 0 |
| tests (Tests/SoundUpCoreTests) | 6 | 0 | 6 | 0 |
| deps (Package.swift) | 1 | 1 | 0 | 0 |
| infra | 0 | — | — | — (no CI/CD, Docker, or deploy config exists) |
| osint | 1 declared asset | 1 | 0 | 0 |

`files_skipped`: all 6 files under `Tests/SoundUpCoreTests/` — reason `test-only`.

## Scanner runs

| Tool | Target | Result |
|------|--------|--------|
| gitleaks | full git history (12 commits) | no leaks found |
| trufflehog | full git history | 0 verified, 0 unverified secrets |
| semgrep (`--config auto`) | `Sources/` (14 files, 1074 community rules, 2 Swift-specific) | 0 findings — note: Swift-specific rule coverage in the community ruleset is thin (2 rules), so this scan carries less weight than the manual review below |

**Scanner skips:** `skipped: npm audit — no package.json`, `skipped: pip-audit — no Python
dependencies`, `skipped: subfinder — not in PATH (not needed; no subdomains declared in scope)`.

## OSINT

**Declared scope** (per `.cursor/rules/project-policy.mdc`): the SoundUp GitHub repository and its
companion Homebrew tap repository.

- `roniorque/SoundUP` (public): git history scanned via gitleaks/trufflehog (see above, clean);
  README and commit messages manually checked for staging URLs, internal hostnames, or leaked
  credentials — none found.
- `roniorque/homebrew-soundup`: **not yet created** as of this report. Once created and populated
  (per the Issue 0007 packaging steps), it should receive the same one-time check (it will only
  ever contain a Cask formula referencing a public release URL and checksum — low risk, but worth
  a quick look before or shortly after first publishing it).

## Findings

### SEC-001 — Potential out-of-bounds read in real-time gain-application loop

- **Status:** FIXED
- **Severity:** Medium
- **CWE:** CWE-125 (Out-of-bounds Read)
- **Category:** input-validation (memory safety)
- **File:** `Sources/SoundUp/CoreAudioGainController.swift`, `applyGain(_:from:to:)`
- **Summary:** `frameCount` is computed from the **output** buffer's `mDataByteSize`, then used to
  index samples read from the **input** buffer. Core Audio's contract for a tap+aggregate device
  pair normally guarantees matching buffer sizes for the negotiated stream format, but this code's
  own doc comment already flags that format-matching between the tap and the default output
  device is an *assumption*, not a verified guarantee (see file header). If the two buffers ever
  differ in size — e.g. a future macOS version, an unusual output device, or an edge case in
  format negotiation — this reads past the end of the input buffer.
- **Impact:** Not remotely triggerable (no network input reaches this code); worst realistic case
  is a crash (denial of service against SoundUp itself) or reading adjacent heap memory into the
  output buffer (which is immediately overwritten with the same, already-in-process audio data —
  not exfiltrated anywhere). Low real-world exploitability, but a genuine memory-safety gap worth
  closing given raw pointer arithmetic is involved.
- **Fix:** `frameCount` is now `min(outputFrameCount, inputFrameCount)`, computed from both
  buffers independently before the copy loop. Output buffers are zero-initialized by Core Audio
  per its documented contract, so any unwritten trailing frames on a size mismatch are silent,
  not garbage.

### SEC-002 — No explicit bounds/sanity validation when decoding persisted settings

- **Status:** VERIFIED NOT EXPLOITABLE (no code change needed)
- **Severity:** Low (downgraded from initial assessment after testing)
- **CWE:** CWE-20 (Improper Input Validation)
- **Category:** data-exposure / input-validation
- **File:** `Sources/SoundUpCore/AppVolumeSettingsStore.swift`
- **Summary:** `readAll()` decodes `percent`/`isMuted` from the local JSON settings file with no
  explicit range check. If that file were manually edited (only possible by whoever already has
  write access to the current user's own account — no privilege escalation vector), a
  pathological value (e.g. `NaN`) could propagate to `VolumeGainCalculator.gain(forPercent:)`,
  whose `min`/`max` clamping has unspecified behavior for `NaN` inputs in Swift.
- **Impact:** Self-inflicted only (requires local file-write access the user already has to their
  own account); worst case is an unexpected gain value for one app, not a security compromise.
- **Verification:** Added a regression test (`AppVolumeSettingsStoreTests`) saving `AppVolumeState`
  with `percent: .nan` and `.infinity`. Result: `JSONEncoder`'s default behavior throws on
  non-finite `Double` values, so `writeAll()`'s `try?` silently no-ops — nothing is ever persisted
  for a non-finite value, and `setting(forBundleID:)` correctly returns `nil`. Valid JSON also has
  no native representation for `NaN`/`Infinity`, so a hand-edited file can't reintroduce this
  either. No code change was needed; downgraded from "recommend a fix" to "confirmed already
  safe by construction."

### SEC-003 — Info: local settings file uses default OS file permissions

- **Severity:** Info
- **Category:** data-exposure
- **File:** `Sources/SoundUpCore/SettingsStorage.swift` (`FileSettingsStorage`)
- **Summary:** `~/Library/Application Support/SoundUp/app-volume-settings.json` is written with
  `Data.write(options: .atomic)` and no explicit permission attributes, inheriting the user's
  default umask (typically readable by other local accounts on a shared Mac, writable only by the
  owner). This is acceptable as-is: the file only contains `{bundleID: percent, isMuted}` pairs —
  no PII, no secrets — matching the policy's own stated position
  ("plain local storage is sufficient, no encryption-at-rest requirement"). No action needed;
  recorded for completeness.

### SEC-004 — Info: SoundUp inherently observes system-wide audio-process activity

- **Severity:** Info
- **Category:** data-exposure (transparency note, not a vulnerability)
- **Files:** `Sources/SoundUp/CoreAudioProcessMonitor.swift`, `AudioProcessOwnership.swift`
- **Summary:** By design and necessity, SoundUp enumerates every currently-running regular app and
  every audio-capable Core Audio process on the system (bundle IDs, display names, playback
  state) in order to build its per-app control list. This is fully disclosed in the README/PRD as
  the app's core function. Confirmed during this review: **no networking APIs are used anywhere
  in the codebase** — this data is used only in-memory for the UI and is never transmitted,
  logged to a file, or persisted beyond the volume/mute settings already covered in SEC-003.
  Fully consistent with policy ("SoundUp is fully offline: no telemetry ... no network calls").

### SEC-005 — Info: zero third-party dependencies

- **Severity:** Info
- **Category:** dependencies
- **File:** `Package.swift`
- **Summary:** SoundUp has no external Swift Package dependencies — `Package.swift` only declares
  its own three targets. No supply-chain risk from third-party code. `npm audit`/`pip-audit` are
  not applicable (no such manifests exist).

## Recommendation

SEC-001 fixed. SEC-002 verified as not a real gap. SEC-003/004/005 require no action. All findings
resolved or confirmed non-issues — clear to proceed to `phase_9_qa`.
