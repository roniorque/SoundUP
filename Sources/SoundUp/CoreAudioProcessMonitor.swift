import AppKit
import CoreAudio
import Foundation
import SoundUpCore

/// Real Core Audio-backed implementation of `AudioActivityMonitor`.
///
/// Polls `kAudioHardwarePropertyProcessObjectList` for audio process objects
/// and filters to ones currently producing output audio
/// (`kAudioProcessPropertyIsRunningOutput`). Polling (rather than a property
/// listener) is used for simplicity in this first implementation; this is a
/// reasonable first target for tightening during manual verification if
/// activity detection feels too slow or too eager.
final class CoreAudioProcessMonitor: AudioActivityMonitor {
    var onActiveAppsChanged: (([AudioActiveApp]) -> Void)?

    private let pollInterval: TimeInterval
    private var timer: Timer?

    init(pollInterval: TimeInterval = 1.0) {
        self.pollInterval = pollInterval
    }

    func start() {
        poll()
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        onActiveAppsChanged?(Self.currentAudioActiveApps())
    }

    static func currentAudioActiveApps() -> [AudioActiveApp] {
        guard let processIDs = audioProcessObjectIDs() else { return [] }

        var apps: [AudioActiveApp] = []
        var seenBundleIDs = Set<String>()

        for processID in processIDs {
            guard isRunningOutput(processID), let bundleID = bundleID(for: processID) else { continue }
            guard seenBundleIDs.insert(bundleID).inserted else { continue }
            apps.append(AudioActiveApp(bundleID: bundleID, displayName: displayName(forBundleID: bundleID)))
        }
        return apps
    }

    private static func audioProcessObjectIDs() -> [AudioObjectID]? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize
        )
        guard status == noErr, dataSize > 0 else { return nil }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var processIDs = [AudioObjectID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &processIDs
        )
        return status == noErr ? processIDs : nil
    }

    private static func isRunningOutput(_ processID: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyIsRunningOutput,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var isRunning: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(processID, &address, 0, nil, &dataSize, &isRunning)
        return status == noErr && isRunning != 0
    }

    private static func bundleID(for processID: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyBundleID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(processID, &address, 0, nil, &dataSize)
        guard status == noErr, dataSize > 0 else { return nil }

        var cfStringRef: CFString? = nil
        status = withUnsafeMutablePointer(to: &cfStringRef) { pointer -> OSStatus in
            AudioObjectGetPropertyData(processID, &address, 0, nil, &dataSize, pointer)
        }
        guard status == noErr, let cfStringRef else { return nil }
        return cfStringRef as String
    }

    private static func displayName(forBundleID bundleID: String) -> String {
        guard
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
            let bundle = Bundle(url: url)
        else {
            return bundleID
        }
        return (bundle.infoDictionary?["CFBundleName"] as? String)
            ?? (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? bundleID
    }
}
