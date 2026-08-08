import SwiftUI

@main
struct SoundUpApp: App {
    @StateObject private var viewModel = AppVolumeViewModel()

    var body: some Scene {
        MenuBarExtra("SoundUp", systemImage: "speaker.wave.2.fill") {
            SoundUpMenuView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
