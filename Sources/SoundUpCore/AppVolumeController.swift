import Foundation

/// Coordinates audio-activity detection, per-app volume/boost/mute state,
/// live gain application, and persistence — the glue behind Issues 0001,
/// 0002, 0003, and 0005. Depends only on the `AudioActivityMonitor` and
/// `ProcessGainController` protocols, so it is fully unit-testable with
/// fakes standing in for the real Core Audio integration.
public final class AppVolumeController {
    public private(set) var apps: [AudioActiveApp] = []
    public var onAppsChanged: (([AudioActiveApp]) -> Void)?

    private var states: [String: AppVolumeState] = [:]
    private let monitor: AudioActivityMonitor
    private let gainController: ProcessGainController
    private let settingsStore: AppVolumeSettingsStore

    public init(
        monitor: AudioActivityMonitor,
        gainController: ProcessGainController,
        settingsStore: AppVolumeSettingsStore
    ) {
        self.monitor = monitor
        self.gainController = gainController
        self.settingsStore = settingsStore
    }

    public func start() {
        monitor.onActiveAppsChanged = { [weak self] activeApps in
            self?.handleActiveAppsChanged(activeApps)
        }
        monitor.start()
    }

    public func stop() {
        monitor.stop()
    }

    public func state(forBundleID bundleID: String) -> AppVolumeState {
        states[bundleID] ?? AppVolumeState(percent: VolumeGainCalculator.unityPercent)
    }

    public func setPercent(_ percent: Double, forBundleID bundleID: String) {
        var state = state(forBundleID: bundleID)
        state.percent = percent
        applyAndPersist(state, forBundleID: bundleID)
    }

    public func setMuted(_ muted: Bool, forBundleID bundleID: String) {
        var state = state(forBundleID: bundleID)
        if muted {
            state.mute()
        } else {
            state.unmute()
        }
        applyAndPersist(state, forBundleID: bundleID)
    }

    private func applyAndPersist(_ state: AppVolumeState, forBundleID bundleID: String) {
        states[bundleID] = state
        gainController.setGain(state.effectiveGain, forBundleID: bundleID)
        settingsStore.save(state, forBundleID: bundleID)
    }

    private func handleActiveAppsChanged(_ activeApps: [AudioActiveApp]) {
        apps = activeApps
        let activeBundleIDs = Set(activeApps.map(\.bundleID))

        for app in activeApps where states[app.bundleID] == nil {
            let restored = settingsStore.setting(forBundleID: app.bundleID)
                ?? AppVolumeState(percent: VolumeGainCalculator.unityPercent)
            states[app.bundleID] = restored
            gainController.setGain(restored.effectiveGain, forBundleID: app.bundleID)
        }

        for bundleID in states.keys where !activeBundleIDs.contains(bundleID) {
            gainController.removeControl(forBundleID: bundleID)
            states.removeValue(forKey: bundleID)
        }

        onAppsChanged?(apps)
    }
}
