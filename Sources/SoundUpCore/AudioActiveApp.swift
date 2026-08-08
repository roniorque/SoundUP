import Foundation

/// An app SoundUp can show/control, as reported by an `AudioActivityMonitor`.
/// `isPlaying` indicates whether it is currently producing audio right now —
/// an app can be listed (e.g. a regular, dock-visible app that's running)
/// without currently playing anything.
public struct AudioActiveApp: Identifiable, Equatable, Hashable {
    public let bundleID: String
    public let displayName: String
    public let isPlaying: Bool

    public init(bundleID: String, displayName: String, isPlaying: Bool = true) {
        self.bundleID = bundleID
        self.displayName = displayName
        self.isPlaying = isPlaying
    }

    public var id: String { bundleID }
}

/// Detects which apps SoundUp can show/control, notifying on change.
/// The real implementation is backed by Core Audio; tests use a fake.
public protocol AudioActivityMonitor: AnyObject {
    var onActiveAppsChanged: (([AudioActiveApp]) -> Void)? { get set }
    func start()
    func stop()
}

/// Applies (or removes) live gain for a specific app's audio, identified by
/// bundle ID. The real implementation is backed by a Core Audio Process Tap;
/// tests use a fake.
public protocol ProcessGainController: AnyObject {
    func setGain(_ gain: Double, forBundleID bundleID: String)
    func removeControl(forBundleID bundleID: String)
}
