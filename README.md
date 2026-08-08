# SoundUp

A free, open-source macOS menu-bar app for controlling — and boosting — the volume of individual
apps independently, without touching system volume or any other app.

Built on Apple's Core Audio Process Tap API (macOS 14.4+). No virtual driver, no kernel extension,
no Apple Developer fee, no App Store.

## Features

- Independent volume control per app, from a menu-bar dropdown.
- Boost any app up to 3000% of its own normal maximum (fully linear up to 2000%, gently limited
  above that), loud enough to compensate for macOS's own system-wide audio ducking during
  FaceTime/phone calls.
- Mute/unmute per app without losing your slider position.
- Settings persist per app across relaunches and reboots.
- Fully offline — no telemetry, no network calls, nothing captured ever leaves your machine.

## Requirements

- macOS 14.4 (Sonoma) or later.

## Installation

### Homebrew (recommended)

```
brew tap roniorque/soundup
brew install --cask soundup
```

Then launch SoundUp from Spotlight (⌘+Space, type "SoundUp") or Launchpad — it runs entirely from
the menu bar, with no Dock icon or window. To quit, click the SoundUp icon in the menu bar and
choose **Quit SoundUp** at the bottom of the dropdown.

SoundUp is unsigned (no Apple Developer Program fee, no App Store) — Homebrew Cask automatically
strips the quarantine flag so it opens without a Gatekeeper warning. The first time it needs to
adjust another app's audio, macOS will show a one-time permission prompt; approve it to let
SoundUp work.

### Manual download

Download the latest `SoundUp-vX.Y.Z.zip` from the
[Releases page](https://github.com/roniorque/SoundUP/releases), unzip it, and move `SoundUp.app`
to your `Applications` folder. Since it's unsigned and downloaded directly (not via Homebrew), the
first launch will show a Gatekeeper "unidentified developer" warning — right-click the app and
choose **Open**, then confirm, to bypass this once.

### Build from source

Requires the [Swift](https://www.swift.org) toolchain (ships with Xcode, or installable via
Command Line Tools).

```
swift build
swift run SoundUp
```

See [`docs/guides/0001-soundup/0001-guide.md`](docs/guides/0001-soundup/0001-guide.md) for full
build/run/test instructions, including how to open the project in Xcode.

## Running tests

```
swift test
```

## Project structure

```
Sources/
  SoundUpCore/   — pure logic (gain math, persistence, state), fully unit tested
  SoundUp/       — menu-bar app shell + real Core Audio integration
Tests/
  SoundUpCoreTests/
docs/            — planning, build, and bug-fix history (see docs/ideas, docs/PRD, docs/issues,
                   docs/bugs, docs/adr)
CONTEXT.md       — project glossary/domain language
```

## Known limitations

- Some apps' audio is produced by shared system helpers (e.g. a browser's WebKit GPU process)
  that aren't cleanly attributable to one specific app — these may show a generic name.
- The idle-app list currently includes any regular running app, not just genuine media apps; this
  is being refined (see `docs/bugs/0001-soundup/BUG-2.md`).

## License

See [LICENSE](LICENSE).
