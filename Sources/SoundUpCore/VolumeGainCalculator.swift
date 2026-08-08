import Foundation

/// Maps a volume slider percentage (0–500) to a linear amplitude gain.
///
/// 100% is unity gain (the app's own unmodified output). Below 100% the mapping
/// is linear. Above 100%, a soft-clip-to-ceiling curve (`ceiling * tanh(x / ceiling)`)
/// is applied to the boosted portion: gain keeps increasing meaningfully across the
/// full boosted range while always staying below the unlimited linear equivalent at
/// the same slider setting, reducing (but not eliminating) clipping at high boost.
public enum VolumeGainCalculator {
    public static let minPercent: Double = 0
    public static let unityPercent: Double = 100
    public static let maxPercent: Double = 500

    /// The maximum additional gain (as a multiple of unity) available at `maxPercent`,
    /// e.g. 4.0 at maxPercent=500 means gain approaches, but never reaches, 5.0.
    private static var boostCeiling: Double { (maxPercent - unityPercent) / unityPercent }

    public static func gain(forPercent percent: Double) -> Double {
        let clamped = min(max(percent, minPercent), maxPercent)

        if clamped <= unityPercent {
            return clamped / unityPercent
        }

        let boostFraction = (clamped - unityPercent) / unityPercent
        let ceiling = boostCeiling
        return 1.0 + ceiling * tanh(boostFraction / ceiling)
    }
}
