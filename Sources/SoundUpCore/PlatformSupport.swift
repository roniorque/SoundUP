import Foundation

/// SoundUp depends on the Core Audio Process Tap API family, available starting
/// macOS 14.4 (Sonoma). Earlier versions must be detected and clearly messaged
/// rather than allowed to fail unpredictably.
public enum PlatformSupport {
    public static let minimumSupportedVersion = OperatingSystemVersion(
        majorVersion: 14, minorVersion: 4, patchVersion: 0
    )

    public static func isSupported(_ version: OperatingSystemVersion) -> Bool {
        if version.majorVersion != minimumSupportedVersion.majorVersion {
            return version.majorVersion > minimumSupportedVersion.majorVersion
        }
        return version.minorVersion >= minimumSupportedVersion.minorVersion
    }
}
