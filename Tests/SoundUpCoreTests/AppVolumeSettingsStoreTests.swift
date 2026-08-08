import Testing
@testable import SoundUpCore

@Suite("AppVolumeSettingsStore")
struct AppVolumeSettingsStoreTests {
    @Test("unknown bundle ID has no saved setting")
    func unknownBundleIDHasNoSavedSetting() {
        let store = AppVolumeSettingsStore(storage: InMemorySettingsStorage())
        #expect(store.setting(forBundleID: "com.example.unknown") == nil)
    }

    @Test("a saved setting round-trips through the same storage")
    func savedSettingRoundTrips() {
        let storage = InMemorySettingsStorage()
        let store = AppVolumeSettingsStore(storage: storage)
        let state = AppVolumeState(percent: 175, isMuted: false)

        store.save(state, forBundleID: "com.spotify.client")

        #expect(store.setting(forBundleID: "com.spotify.client") == state)
    }

    @Test("a setting persists across separate store instances sharing storage")
    func settingPersistsAcrossStoreInstances() {
        let storage = InMemorySettingsStorage()
        let firstStore = AppVolumeSettingsStore(storage: storage)
        let state = AppVolumeState(percent: 60, isMuted: true)
        firstStore.save(state, forBundleID: "com.zoom.us")

        let secondStore = AppVolumeSettingsStore(storage: storage)

        #expect(secondStore.setting(forBundleID: "com.zoom.us") == state)
    }

    @Test("settings for different bundle IDs do not overwrite each other")
    func settingsForDifferentBundleIDsDoNotCollide() {
        let store = AppVolumeSettingsStore(storage: InMemorySettingsStorage())
        let spotifyState = AppVolumeState(percent: 120, isMuted: false)
        let slackState = AppVolumeState(percent: 40, isMuted: true)

        store.save(spotifyState, forBundleID: "com.spotify.client")
        store.save(slackState, forBundleID: "com.tinyspeck.slackmacgap")

        #expect(store.setting(forBundleID: "com.spotify.client") == spotifyState)
        #expect(store.setting(forBundleID: "com.tinyspeck.slackmacgap") == slackState)
    }
}
