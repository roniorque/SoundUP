import Testing
import Foundation
@testable import SoundUpCore

@Suite("AppLaunchState")
struct AppLaunchStateTests {
    let supported = OperatingSystemVersion(majorVersion: 14, minorVersion: 4, patchVersion: 0)
    let unsupported = OperatingSystemVersion(majorVersion: 14, minorVersion: 3, patchVersion: 0)

    @Test("unsupported OS wins even if permission is also denied")
    func unsupportedOSTakesPrecedence() {
        let state = AppLaunchState.resolve(osVersion: unsupported, isPermissionDenied: true)
        #expect(state == .unsupportedOS)
        #expect(state.userMessage != nil)
    }

    @Test("supported OS with denied permission reports permissionDenied")
    func permissionDeniedOnSupportedOS() {
        let state = AppLaunchState.resolve(osVersion: supported, isPermissionDenied: true)
        #expect(state == .permissionDenied)
        #expect(state.userMessage != nil)
    }

    @Test("supported OS with granted permission is ready with no message")
    func readyStateHasNoMessage() {
        let state = AppLaunchState.resolve(osVersion: supported, isPermissionDenied: false)
        #expect(state == .ready)
        #expect(state.userMessage == nil)
    }
}
