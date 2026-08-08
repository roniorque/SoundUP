# SoundUp

**Last updated:** Saturday, Aug 8, 2026, 9:00 PM (UTC+8)

SoundUp is a free, open-source macOS menu-bar app for controlling and boosting the volume of
individual apps independently, built on Apple's Core Audio Process Tap API.

## Language

**Process Tap**:
Apple's Core Audio mechanism (`AudioHardwareCreateProcessTap`, macOS 14.2+) for capturing a
specific process's audio in real time without a virtual driver or kernel extension.
_Avoid_: Virtual driver, audio hook (SoundUp does not use either).

**Aggregate Device**:
A private, SoundUp-created Core Audio device combining a Process Tap with the system's real
default output device, used to write gain-adjusted audio back to physical hardware.
_Avoid_: Virtual output, mixer.

**Owning Application**:
The real, user-facing app (an `NSRunningApplication` with `.regular` activation policy, e.g.
Safari) that SoundUp attributes an audio-producing Core Audio process to. Distinct from the raw
audio process itself, which may be an internal helper (e.g. `com.apple.WebKit.GPU`) with no OS
parent/child link to its owning app.
_Avoid_: Parent app (ambiguous with OS process parentage, which doesn't always match).

**Gain**:
The linear amplitude multiplier applied to a tapped app's audio. 1.0 is unity (unmodified). Values
below 1.0 attenuate; values above 1.0 are boost, soft-limited via `VolumeGainCalculator`.
_Avoid_: Volume (ambiguous with the 0–500% slider percentage, which maps to gain via
`VolumeGainCalculator`, not a 1:1 value).

**Boost**:
Gain above unity (slider percentage above 100%), letting an app play louder than its own normal
maximum. Capped at 500% slider (soft-limited, asymptotic, never reaching the unlimited linear
equivalent).
_Avoid_: Amplification (used interchangeably in casual conversation, but "boost" is SoundUp's
canonical term in UI and docs).

**Controlled App**:
An app for which SoundUp has created a real Process Tap + Aggregate Device (a "live control").
Distinct from a merely *listed* app, which may not yet have a live control — see Lazy Control.

**Lazy Control**:
The policy of not creating a real Process Tap/Aggregate Device for a listed app until it either
starts producing audio or the user explicitly interacts with its slider — avoiding the resource
cost of tapping every visible app up front.

**Idle App**:
An app that is listed in SoundUp's menu but not currently producing audio (`isPlaying == false`).
Genuine dock-visible (`.regular`) apps are listed even while idle; background helpers/daemons are
only listed while actively playing, to avoid listing noise.
