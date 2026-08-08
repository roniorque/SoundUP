import Foundation

/// An app currently producing audio, as reported by an `AudioActivityMonitor`.
public struct AudioActiveApp: Identifiable, Equatable, Hashable {
    public let bundleID: String
    public let displayName: String

    public init(bundleID: String, displayName: String) {
        self.bundleID = bundleID
        self.displayName = displayName
    }

    public var id: String { bundleID }
}

/// Detects which apps are currently producing audio, notifying on change.
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
