# SoundUp

A free, open-source macOS menu-bar app for controlling — and boosting — the volume of individual
apps independently, without touching system volume or any other app.

Built on Apple's Core Audio Process Tap API (macOS 14.4+). No virtual driver, no kernel extension,
no Apple Developer fee, no App Store.

## Features

- Independent volume control per app, from a menu-bar dropdown.
- Boost any app up to 500% of its own normal maximum, with soft limiting to control distortion.
- Mute/unmute per app without losing your slider position.
- Settings persist per app across relaunches and reboots.
- Fully offline — no telemetry, no network calls, nothing captured ever leaves your machine.

## Requirements

- macOS 14.4 (Sonoma) or later.
- [Swift](https://www.swift.org) toolchain (ships with Xcode, or installable via Command Line
  Tools) to build from source.

## Building and running

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
