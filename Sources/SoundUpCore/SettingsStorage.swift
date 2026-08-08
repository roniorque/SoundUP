import Foundation

/// A minimal storage boundary so `AppVolumeSettingsStore` can be unit tested
/// without touching the real filesystem, per the dependency-injection pattern
/// for mockable system boundaries.
public protocol SettingsStorage: AnyObject {
    func load() -> Data?
    func save(_ data: Data)
}

/// Test/in-memory backing store — no disk access.
public final class InMemorySettingsStorage: SettingsStorage {
    private var data: Data?

    public init(data: Data? = nil) {
        self.data = data
    }

    public func load() -> Data? { data }

    public func save(_ data: Data) {
        self.data = data
    }
}

/// Real backing store — persists to a single JSON file on local disk.
public final class FileSettingsStorage: SettingsStorage {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    public func save(_ data: Data) {
        try? data.write(to: fileURL, options: .atomic)
    }
}
