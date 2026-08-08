import Testing
@testable import SoundUpCore

@Suite("AppVolumeController")
struct AppVolumeControllerTests {
    @Test("starting begins monitoring")
    func startingBeginsMonitoring() {
        let monitor = FakeAudioActivityMonitor()
        let controller = AppVolumeController(
            monitor: monitor,
            gainController: FakeProcessGainController(),
            settingsStore: AppVolumeSettingsStore(storage: InMemorySettingsStorage())
        )

        controller.start()

        #expect(monitor.startCallCount == 1)
    }

    @Test("a newly active app with no saved setting defaults to 100% and applies unity gain")
    func newlyActiveAppDefaultsToUnityGain() {
        let monitor = FakeAudioActivityMonitor()
        let gainController = FakeProcessGainController()
        let controller = AppVolumeController(
            monitor: monitor,
            gainController: gainController,
            settingsStore: AppVolumeSettingsStore(storage: InMemorySettingsStorage())
        )
        controller.start()

        monitor.simulateActiveApps([AudioActiveApp(bundleID: "com.spotify.client", displayName: "Spotify")])

        #expect(controller.apps.map(\.bundleID) == ["com.spotify.client"])
        #expect(controller.state(forBundleID: "com.spotify.client").percent == 100)
        #expect(gainController.appliedGains["com.spotify.client"] == 1.0)
    }

    @Test("a newly active app with a saved setting restores it and applies the saved gain")
    func newlyActiveAppRestoresSavedSetting() {
        let storage = InMemorySettingsStorage()
        let settingsStore = AppVolumeSettingsStore(storage: storage)
        settingsStore.save(AppVolumeState(percent: 150, isMuted: false), forBundleID: "com.zoom.us")

        let monitor = FakeAudioActivityMonitor()
        let gainController = FakeProcessGainController()
        let controller = AppVolumeController(
            monitor: monitor, gainController: gainController, settingsStore: settingsStore
        )
        controller.start()

        monitor.simulateActiveApps([AudioActiveApp(bundleID: "com.zoom.us", displayName: "Zoom")])

        #expect(controller.state(forBundleID: "com.zoom.us").percent == 150)
        #expect(gainController.appliedGains["com.zoom.us"] == AppVolumeState(percent: 150).effectiveGain)
    }

    @Test("changing an app's percent applies live gain and persists the new setting")
    func changingPercentAppliesGainAndPersists() {
        let storage = InMemorySettingsStorage()
        let settingsStore = AppVolumeSettingsStore(storage: storage)
        let monitor = FakeAudioActivityMonitor()
        let gainController = FakeProcessGainController()
        let controller = AppVolumeController(
            monitor: monitor, gainController: gainController, settingsStore: settingsStore
        )
        controller.start()
        monitor.simulateActiveApps([AudioActiveApp(bundleID: "com.spotify.client", displayName: "Spotify")])

        controller.setPercent(180, forBundleID: "com.spotify.client")

        #expect(controller.state(forBundleID: "com.spotify.client").percent == 180)
        #expect(gainController.appliedGains["com.spotify.client"] == VolumeGainCalculator.gain(forPercent: 180))
        #expect(settingsStore.setting(forBundleID: "com.spotify.client")?.percent == 180)
    }

    @Test("muting an app applies zero gain without changing its stored percent")
    func mutingAppliesZeroGainWithoutChangingPercent() {
        let monitor = FakeAudioActivityMonitor()
        let gainController = FakeProcessGainController()
        let controller = AppVolumeController(
            monitor: monitor,
            gainController: gainController,
            settingsStore: AppVolumeSettingsStore(storage: InMemorySettingsStorage())
        )
        controller.start()
        monitor.simulateActiveApps([AudioActiveApp(bundleID: "com.tinyspeck.slackmacgap", displayName: "Slack")])
        controller.setPercent(160, forBundleID: "com.tinyspeck.slackmacgap")

        controller.setMuted(true, forBundleID: "com.tinyspeck.slackmacgap")

        #expect(gainController.appliedGains["com.tinyspeck.slackmacgap"] == 0.0)
        #expect(controller.state(forBundleID: "com.tinyspeck.slackmacgap").percent == 160)

        controller.setMuted(false, forBundleID: "com.tinyspeck.slackmacgap")

        #expect(gainController.appliedGains["com.tinyspeck.slackmacgap"] == VolumeGainCalculator.gain(forPercent: 160))
    }

    @Test("onAppsChanged fires with the updated active app list")
    func onAppsChangedFiresWithUpdatedList() {
        let monitor = FakeAudioActivityMonitor()
        let controller = AppVolumeController(
            monitor: monitor,
            gainController: FakeProcessGainController(),
            settingsStore: AppVolumeSettingsStore(storage: InMemorySettingsStorage())
        )
        var observedApps: [[AudioActiveApp]] = []
        controller.onAppsChanged = { observedApps.append($0) }
        controller.start()

        monitor.simulateActiveApps([AudioActiveApp(bundleID: "com.spotify.client", displayName: "Spotify")])

        #expect(observedApps.count == 1)
        #expect(observedApps.last?.map(\.bundleID) == ["com.spotify.client"])
    }

    @Test("an app that stops producing audio is removed from the active list and its gain control is released")
    func appThatStopsIsRemovedAndGainControlReleased() {
        let monitor = FakeAudioActivityMonitor()
        let gainController = FakeProcessGainController()
        let controller = AppVolumeController(
            monitor: monitor,
            gainController: gainController,
            settingsStore: AppVolumeSettingsStore(storage: InMemorySettingsStorage())
        )
        controller.start()
        monitor.simulateActiveApps([AudioActiveApp(bundleID: "com.spotify.client", displayName: "Spotify")])

        monitor.simulateActiveApps([])

        #expect(controller.apps.isEmpty)
        #expect(gainController.removedBundleIDs == ["com.spotify.client"])
    }
}
