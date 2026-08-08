import AppKit
import CoreAudio
import Darwin
import Foundation

/// Resolves the real, user-facing application that owns a given Core Audio
/// process object — walking up the parent-process chain when the audio
/// process is an internal helper (e.g. a browser's GPU/networking process)
/// rather than the app itself, so SoundUp can show and control "Safari"
/// instead of "com.apple.WebKit.GPU".
///
/// Some helpers (e.g. WebKit's GPU/networking processes) are spawned via XPC
/// directly by launchd rather than forked from their owning app, so there is
/// no real parent/child OS relationship to walk up. In that case this falls
/// back to the helper's own identity, which may be a generic/shared name
/// rather than the specific app using it — a known, accepted limitation.
enum AudioProcessOwnership {
    static func owningApplication(forProcessID processID: AudioObjectID) -> NSRunningApplication? {
        guard let pid = pid(forProcessID: processID) else { return nil }
        return owningApplication(forPID: pid)
    }

    private static func owningApplication(forPID pid: pid_t) -> NSRunningApplication? {
        var currentPID = pid
        var fallbackMatch: NSRunningApplication?

        for _ in 0..<10 {
            if let app = NSRunningApplication(processIdentifier: currentPID) {
                // Only `.regular` (a genuine, dock-visible app) is a confident match — stop
                // here. `.accessory` and `.prohibited` both include internal helpers (e.g. a
                // browser's GPU process reports `.accessory`, matching legitimate menu-bar-only
                // apps too) — remember the first one as a fallback, but keep walking up looking
                // for a real `.regular` ancestor app.
                if app.activationPolicy == .regular {
                    return app
                }
                fallbackMatch = fallbackMatch ?? app
            }
            guard let parent = parentPID(of: currentPID), parent > 1, parent != currentPID else {
                return fallbackMatch
            }
            currentPID = parent
        }
        return fallbackMatch
    }

    private static func parentPID(of pid: pid_t) -> pid_t? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        guard result == 0 else { return nil }
        return info.kp_eproc.e_ppid
    }

    static func pid(forProcessID processID: AudioObjectID) -> pid_t? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyPID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var pid: pid_t = 0
        var dataSize = UInt32(MemoryLayout<pid_t>.size)
        let status = AudioObjectGetPropertyData(processID, &address, 0, nil, &dataSize, &pid)
        return status == noErr ? pid : nil
    }
}
