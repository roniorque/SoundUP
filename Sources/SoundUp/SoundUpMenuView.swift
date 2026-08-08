import AppKit
import SoundUpCore
import SwiftUI

struct SoundUpMenuView: View {
    @ObservedObject var viewModel: AppVolumeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let message = viewModel.launchState.userMessage {
                Text(message)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(8)
            } else if viewModel.apps.isEmpty {
                Text("No apps are currently playing audio.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(8)
            } else {
                ForEach(viewModel.apps) { app in
                    AppVolumeRow(
                        app: app,
                        percent: viewModel.percent(forBundleID: app.bundleID),
                        isMuted: viewModel.isMuted(forBundleID: app.bundleID),
                        onPercentChange: { viewModel.setPercent($0, forBundleID: app.bundleID) },
                        onMuteToggle: { viewModel.setMuted($0, forBundleID: app.bundleID) }
                    )
                    Divider()
                }
            }

            Button("Quit SoundUp") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(minWidth: 260)
        .onAppear { viewModel.start() }
    }
}

private struct AppVolumeRow: View {
    let app: AudioActiveApp
    let percent: Double
    let isMuted: Bool
    let onPercentChange: (Double) -> Void
    let onMuteToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(app.displayName)
                    .font(.body)
                Spacer()
                Button {
                    onMuteToggle(!isMuted)
                } label: {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.fill")
                }
                .buttonStyle(.plain)
            }
            HStack {
                Slider(
                    value: Binding(get: { percent }, set: onPercentChange),
                    in: VolumeGainCalculator.minPercent...VolumeGainCalculator.maxPercent
                )
                Text("\(Int(percent))%")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }
}
