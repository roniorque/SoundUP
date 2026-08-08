import Foundation

/// The volume/boost/mute state for a single app, identified elsewhere by bundle ID.
///
/// Muting is independent of the slider `percent` — muting or unmuting never
/// changes `percent`, so unmuting always restores audio at exactly the level
/// the slider was already set to.
public struct AppVolumeState: Equatable {
    public var percent: Double
    public private(set) var isMuted: Bool

    public init(percent: Double, isMuted: Bool = false) {
        self.percent = percent
        self.isMuted = isMuted
    }

    public var effectiveGain: Double {
        isMuted ? 0.0 : VolumeGainCalculator.gain(forPercent: percent)
    }

    public mutating func mute() {
        isMuted = true
    }

    public mutating func unmute() {
        isMuted = false
    }
}
