@testable import SoundUpCore

final class FakeAudioActivityMonitor: AudioActivityMonitor {
    var onActiveAppsChanged: (([AudioActiveApp]) -> Void)?
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    func start() { startCallCount += 1 }
    func stop() { stopCallCount += 1 }

    func simulateActiveApps(_ apps: [AudioActiveApp]) {
        onActiveAppsChanged?(apps)
    }
}

final class FakeProcessGainController: ProcessGainController {
    private(set) var appliedGains: [String: Double] = [:]
    private(set) var removedBundleIDs: [String] = []

    func setGain(_ gain: Double, forBundleID bundleID: String) {
        appliedGains[bundleID] = gain
    }

    func removeControl(forBundleID bundleID: String) {
        removedBundleIDs.append(bundleID)
        appliedGains.removeValue(forKey: bundleID)
    }
}
