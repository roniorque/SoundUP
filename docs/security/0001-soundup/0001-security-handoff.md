status: complete
scope: engagement
engagement_slug: soundup
zones_done: [app, tests, deps, osint]
zones_pending: []
zone_coverage:
  app: { total: 14, tested: 14, skipped: 0, pending: 0 }
  tests: { total: 6, tested: 0, skipped: 6, pending: 0 }
  deps: { total: 1, tested: 1, skipped: 0, pending: 0 }
  osint: { total: 1, tested: 1, skipped: 0, pending: 0 }
files_tested:
  - Sources/SoundUpCore/AppLaunchState.swift
  - Sources/SoundUpCore/AppVolumeController.swift
  - Sources/SoundUpCore/AppVolumeSettingsStore.swift
  - Sources/SoundUpCore/AppVolumeState.swift
  - Sources/SoundUpCore/AudioActiveApp.swift
  - Sources/SoundUpCore/PlatformSupport.swift
  - Sources/SoundUpCore/SettingsStorage.swift
  - Sources/SoundUpCore/VolumeGainCalculator.swift
  - Sources/SoundUp/AppVolumeViewModel.swift
  - Sources/SoundUp/AudioProcessOwnership.swift
  - Sources/SoundUp/CoreAudioGainController.swift
  - Sources/SoundUp/CoreAudioProcessMonitor.swift
  - Sources/SoundUp/SoundUpApp.swift
  - Sources/SoundUp/SoundUpMenuView.swift
files_skipped:
  - path: Tests/SoundUpCoreTests/AppLaunchStateTests.swift
    reason: test-only
  - path: Tests/SoundUpCoreTests/AppVolumeControllerTests.swift
    reason: test-only
  - path: Tests/SoundUpCoreTests/AppVolumeSettingsStoreTests.swift
    reason: test-only
  - path: Tests/SoundUpCoreTests/AppVolumeStateTests.swift
    reason: test-only
  - path: Tests/SoundUpCoreTests/Fakes.swift
    reason: test-only
  - path: Tests/SoundUpCoreTests/PlatformSupportTests.swift
    reason: test-only
  - path: Tests/SoundUpCoreTests/VolumeGainCalculatorTests.swift
    reason: test-only
osint_scope: [roniorque/SoundUP]
osint_complete: true
findings:
  - id: SEC-001
    cwe: CWE-125
    severity: Medium
    summary: Potential out-of-bounds read in real-time gain-application loop if input/output buffer sizes ever mismatch
    file_or_source: Sources/SoundUp/CoreAudioGainController.swift
    scanner: checklist
  - id: SEC-002
    cwe: CWE-20
    severity: Low
    summary: No explicit bounds/sanity validation when decoding persisted settings (NaN could propagate)
    file_or_source: Sources/SoundUpCore/AppVolumeSettingsStore.swift
    scanner: checklist
  - id: SEC-003
    severity: Info
    summary: Local settings file uses default OS file permissions (acceptable — content is non-sensitive)
    file_or_source: Sources/SoundUpCore/SettingsStorage.swift
    scanner: checklist
  - id: SEC-004
    severity: Info
    summary: SoundUp inherently observes system-wide audio-process activity (disclosed, no network transmission confirmed)
    file_or_source: Sources/SoundUp/CoreAudioProcessMonitor.swift
    scanner: checklist
  - id: SEC-005
    severity: Info
    summary: Zero third-party dependencies — no supply-chain risk
    file_or_source: Package.swift
    scanner: checklist
scanner_runs:
  - tool: gitleaks
    target: full git history (12 commits)
    result: "no leaks found"
  - tool: trufflehog
    target: full git history
    result: "0 verified, 0 unverified secrets"
  - tool: semgrep
    target: Sources/ (14 files, --config auto)
    result: "0 findings (1074 community rules, only 2 Swift-specific — thin Swift coverage)"
scanner_skips:
  - "skipped: npm audit — no package.json"
  - "skipped: pip-audit — no Python dependencies"
  - "skipped: subfinder — not in PATH (not needed; no subdomains declared in scope)"
report_draft: docs/security/0001-soundup/0001-security-report.md
started: Saturday, Aug 8, 2026, 10:45 PM (UTC+8)
last_checkpoint: Saturday, Aug 8, 2026, 11:00 PM (UTC+8)
