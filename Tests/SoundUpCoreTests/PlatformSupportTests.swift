import Testing
import Foundation
@testable import SoundUpCore

@Suite("PlatformSupport")
struct PlatformSupportTests {
    @Test("macOS 14.4.0 exactly is supported")
    func exactMinimumVersionIsSupported() {
        let version = OperatingSystemVersion(majorVersion: 14, minorVersion: 4, patchVersion: 0)
        #expect(PlatformSupport.isSupported(version))
    }

    @Test("macOS 15.0 is supported")
    func laterMajorVersionIsSupported() {
        let version = OperatingSystemVersion(majorVersion: 15, minorVersion: 0, patchVersion: 0)
        #expect(PlatformSupport.isSupported(version))
    }

    @Test("macOS 14.5 is supported")
    func laterMinorVersionIsSupported() {
        let version = OperatingSystemVersion(majorVersion: 14, minorVersion: 5, patchVersion: 0)
        #expect(PlatformSupport.isSupported(version))
    }

    @Test("macOS 14.3 is not supported")
    func earlierMinorVersionIsNotSupported() {
        let version = OperatingSystemVersion(majorVersion: 14, minorVersion: 3, patchVersion: 9)
        #expect(!PlatformSupport.isSupported(version))
    }

    @Test("macOS 13.x is not supported")
    func earlierMajorVersionIsNotSupported() {
        let version = OperatingSystemVersion(majorVersion: 13, minorVersion: 9, patchVersion: 0)
        #expect(!PlatformSupport.isSupported(version))
    }
}
