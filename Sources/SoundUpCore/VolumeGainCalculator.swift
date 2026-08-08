import Foundation

/// Maps a volume slider percentage (0–3000) to a linear amplitude gain.
///
/// 100% is unity gain (the app's own unmodified output). Below 100% the mapping
/// is linear. From 100% up to `compressionThreshold`, boost is also fully linear
/// (uncompressed) — the boost should feel proportionate to the slider, not muted.
/// Only above that threshold, close to the top of the range, does a gentle
/// compression (ratio `compressionRatio`) kick in, keeping gain below the
/// unlimited linear equivalent to reduce (not eliminate) clipping risk at the
/// very top of the range, while still reaching a substantial fraction of the
/// theoretical maximum.
///
/// The ceiling is set far higher than a normal "louder" use case needs
/// (most apps sound very loud well under 500%) specifically to give enough
/// headroom to counteract macOS's own system-wide audio ducking during
/// FaceTime/phone calls, which reduces other apps' output by roughly 20dB
/// (~10x linear) with no user-facing way to disable — see ADR 0004.
public enum VolumeGainCalculator {
    public static let minPercent: Double = 0
    public static let unityPercent: Double = 100
    public static let maxPercent: Double = 3000

    /// Below this raw (unlimited) gain, boost is fully linear/uncompressed.
    private static let compressionThreshold: Double = 20.0
    /// Ratio applied to gain above the threshold (4:1 — every 4x of excess raw
    /// gain becomes 1x of actual additional gain).
    private static let compressionRatio: Double = 4.0

    public static func gain(forPercent percent: Double) -> Double {
        let clamped = min(max(percent, minPercent), maxPercent)
        let raw = clamped / unityPercent

        guard raw > compressionThreshold else { return raw }

        let excess = raw - compressionThreshold
        return compressionThreshold + excess / compressionRatio
    }
}
