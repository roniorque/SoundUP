import Foundation
import SoundUpCore

/// No-op fallbacks used when the platform check (Issue 0006) fails, so the
/// app can still launch and show a clear message instead of touching Core
/// Audio APIs that require macOS 14.4+.
private final class NullAudioActivityMonitor: AudioActivityMonitor {
    var onActiveAppsChanged: (([AudioActiveApp]) -> Void)?
    func start() {}
    func stop() {}
}

private final class NullProcessGainController: ProcessGainController {
    func setGain(_ gain: Double, forBundleID bundleID: String) {}
    func removeControl(forBundleID bundleID: String) {}
}

/// SwiftUI-facing view model wrapping `AppVolumeController` (Issue
/// 0001/0002/0003/0005 coordination logic) and `AppLaunchState` (Issue 0006).
@MainActor
final class AppVolumeViewModel: ObservableObject {
    @Published private(set) var apps: [AudioActiveApp] = []
    @Published private(set) var launchState: AppLaunchState
    @Published private(set) var volumeStates: [String: AppVolumeState] = [:]

    private let controller: AppVolumeController

    init() {
        let state = AppLaunchState.resolve(
            osVersion: ProcessInfo.processInfo.operatingSystemVersion,
            isPermissionDenied: false
        )
        launchState = state

        let monitor: AudioActivityMonitor
        let gainController: ProcessGainController
        if state == .ready, #available(macOS 14.4, *) {
            monitor = CoreAudioProcessMonitor()
            gainController = CoreAudioGainController()
        } else {
            monitor = NullAudioActivityMonitor()
            gainController = NullProcessGainController()
        }

        let settingsStore = AppVolumeSettingsStore(
            storage: FileSettingsStorage(fileURL: Self.settingsFileURL())
        )
        controller = AppVolumeController(
            monitor: monitor, gainController: gainController, settingsStore: settingsStore
        )
    }

    func start() {
        guard launchState == .ready else { return }
        controller.onAppsChanged = { [weak self] apps in
            guard let self else { return }
            Task { @MainActor in
                self.apps = apps
                self.refreshVolumeStates()
            }
        }
        controller.start()
    }

    func percent(forBundleID bundleID: String) -> Double {
        volumeStates[bundleID]?.percent ?? VolumeGainCalculator.unityPercent
    }

    func isMuted(forBundleID bundleID: String) -> Bool {
        volumeStates[bundleID]?.isMuted ?? false
    }

    func setPercent(_ percent: Double, forBundleID bundleID: String) {
        controller.setPercent(percent, forBundleID: bundleID)
        refreshVolumeStates()
    }

    func setMuted(_ muted: Bool, forBundleID bundleID: String) {
        controller.setMuted(muted, forBundleID: bundleID)
        refreshVolumeStates()
    }

    private func refreshVolumeStates() {
        var updated: [String: AppVolumeState] = [:]
        for app in apps {
            updated[app.bundleID] = controller.state(forBundleID: app.bundleID)
        }
        volumeStates = updated
    }

    private static func settingsFileURL() -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SoundUp", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("app-volume-settings.json")
    }
}
