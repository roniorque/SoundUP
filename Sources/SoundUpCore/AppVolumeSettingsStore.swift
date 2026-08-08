import Foundation

/// Persists per-app volume/boost/mute settings keyed by bundle identifier, so a
/// setting made for one app is automatically restored the next time that same
/// app (identified by bundle ID) produces audio — including after the app is
/// relaunched or the system is rebooted.
public final class AppVolumeSettingsStore {
    private struct PersistedState: Codable, Equatable {
        var percent: Double
        var isMuted: Bool
    }

    private let storage: SettingsStorage

    public init(storage: SettingsStorage) {
        self.storage = storage
    }

    public func setting(forBundleID bundleID: String) -> AppVolumeState? {
        guard let persisted = readAll()[bundleID] else { return nil }
        return AppVolumeState(percent: persisted.percent, isMuted: persisted.isMuted)
    }

    public func save(_ state: AppVolumeState, forBundleID bundleID: String) {
        var all = readAll()
        all[bundleID] = PersistedState(percent: state.percent, isMuted: state.isMuted)
        writeAll(all)
    }

    private func readAll() -> [String: PersistedState] {
        guard let data = storage.load() else { return [:] }
        return (try? JSONDecoder().decode([String: PersistedState].self, from: data)) ?? [:]
    }

    private func writeAll(_ all: [String: PersistedState]) {
        guard let data = try? JSONEncoder().encode(all) else { return }
        storage.save(data)
    }
}
