import CoreAudio
import Foundation
import SoundUpCore

/// Real Core Audio-backed implementation of `AudioActivityMonitor`.
///
/// Polls `kAudioHardwarePropertyProcessObjectList` for every process Core Audio
/// knows has audio capability. Genuine, dock-visible apps (`.regular` activation
/// policy — e.g. Music) are always listed once running, regardless of whether
/// they're currently playing, since Core Audio's per-process "is running" flag
/// is edge-triggered on play/pause and does not reliably reflect audio that was
/// already playing before SoundUp started observing it. Background helpers and
/// daemons (`.accessory`/`.prohibited`, e.g. loginwindow, or shared helpers like
/// a browser's GPU process) are only listed while actually producing output, to
/// avoid cluttering the list with system noise. `AudioActiveApp.isPlaying`
/// reflects the live flag either way, so `AppVolumeController` can defer
/// creating the real (resource-costly) gain control until an app is actually
/// confirmed playing or the user explicitly interacts with it.
final class CoreAudioProcessMonitor: AudioActivityMonitor {
    var onActiveAppsChanged: (([AudioActiveApp]) -> Void)?

    private let pollInterval: TimeInterval
    private var timer: Timer?

    init(pollInterval: TimeInterval = 1.0) {
        self.pollInterval = pollInterval
    }

    func start() {
        poll()
        // Apps already playing audio before SoundUp launched should appear immediately,
        // not just apps that start afterward. A single poll at launch can occasionally
        // miss this if Core Audio hasn't yet settled kAudioProcessPropertyIsRunningOutput
        // for already-running processes, so a couple of quick follow-up polls right after
        // launch make first-detection reliable without waiting for the next full-interval tick.
        for delay in [0.3, 0.8, 1.5] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.poll()
            }
        }

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

        let ownPID = ProcessInfo.processInfo.processIdentifier

        for processID in processIDs {
            // SoundUp's own process starts reporting itself as "producing output audio" the
            // moment it drives an aggregate device's IOProc for another app — it must never
            // treat itself as a controllable app, or it ends up creating a second, conflicting
            // tap/aggregate device targeting its own audio (via whatever app launched it, e.g.
            // Terminal), silently breaking the legitimate control.
            guard AudioProcessOwnership.pid(forProcessID: processID) != ownPID else { continue }
            guard let owningApp = AudioProcessOwnership.owningApplication(forProcessID: processID) else { continue }
            guard let bundleID = owningApp.bundleIdentifier, !bundleID.isEmpty else { continue }

            let playing = isRunningOutput(processID)
            guard owningApp.activationPolicy == .regular || playing else { continue }
            guard seenBundleIDs.insert(bundleID).inserted else { continue }

            let displayName = owningApp.localizedName ?? bundleID
            apps.append(AudioActiveApp(bundleID: bundleID, displayName: displayName, isPlaying: playing))
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

}
