import Foundation

/// Maps a volume slider percentage (0–200) to a linear amplitude gain.
///
/// 100% is unity gain (the app's own unmodified output). Below 100% the mapping
/// is linear. Above 100% a soft limiter (tanh) is applied to the boosted portion
/// so gain approaches its ceiling asymptotically instead of growing linearly,
/// keeping boosted audio audibly louder while reducing hard clipping compared
/// to unlimited linear gain at the same slider setting.
public enum VolumeGainCalculator {
    public static let minPercent: Double = 0
    public static let unityPercent: Double = 100
    public static let maxPercent: Double = 200

    public static func gain(forPercent percent: Double) -> Double {
        let clamped = min(max(percent, minPercent), maxPercent)

        if clamped <= unityPercent {
            return clamped / unityPercent
        }

        let boostFraction = (clamped - unityPercent) / unityPercent
        return 1.0 + tanh(boostFraction)
    }
}
