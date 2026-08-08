import Foundation

/// The overall state SoundUp presents to the user at launch / on permission
/// changes, covering the two failure paths from Issue 0006: an unsupported
/// macOS version, and a denied audio-capture permission.
public enum AppLaunchState: Equatable {
    case unsupportedOS
    case permissionDenied
    case ready

    public var userMessage: String? {
        switch self {
        case .unsupportedOS:
            return "SoundUp requires macOS 14.4 or later. Please update macOS to use this app."
        case .permissionDenied:
            return "SoundUp needs permission to adjust other apps' audio. " +
                "You can grant it in System Settings → Privacy & Security → Audio Recording, " +
                "then relaunch SoundUp."
        case .ready:
            return nil
        }
    }

    public static func resolve(osVersion: OperatingSystemVersion, isPermissionDenied: Bool) -> AppLaunchState {
        guard PlatformSupport.isSupported(osVersion) else { return .unsupportedOS }
        guard !isPermissionDenied else { return .permissionDenied }
        return .ready
    }
}
