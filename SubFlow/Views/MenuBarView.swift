import SwiftUI

struct MenuBarView: View {
    @Environment(CaptionViewModel.self) private var viewModel
    @Environment(CaptionSettings.self) private var settings
    var onOpenTranscript: () -> Void
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(viewModel.isRecording ? .green : .gray)
                    .frame(width: 8, height: 8)
                Text(statusLabel)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text("Cmd+Shift+T")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if viewModel.isRecording {
                Button(action: { viewModel.stopCapture() }) {
                    Label(AppText.stopRecording(settings.uiLanguage), systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .disabled(viewModel.isLoading && !viewModel.isModelReady)
            } else {
                Menu {
                    Button(action: { startRecording(mode: .screenAndAudio) }) {
                        Label(AppText.screenPlusAudio(settings.uiLanguage), systemImage: "display.and.arrow.down")
                    }

                    Button(action: { startRecording(mode: .audioOnly) }) {
                        Label(AppText.audioOnly(settings.uiLanguage), systemImage: "waveform")
                    }
                } label: {
                    Label(AppText.record(settings.uiLanguage), systemImage: "record.circle")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .disabled(viewModel.isLoading && !viewModel.isModelReady)
            }

            Divider()

            Button(AppText.openTranscript(settings.uiLanguage), action: onOpenTranscript)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(AppText.settings(settings.uiLanguage) + "...", action: onOpenSettings)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(AppText.quit(settings.uiLanguage), action: onQuit)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(width: 220)
    }

    private func startRecording(mode: RecordingMode) {
        settings.recordingMode = mode
        Task { await viewModel.startCapture(mode: mode) }
    }

    private var statusLabel: String {
        if !viewModel.statusMessage.isEmpty { return viewModel.statusMessage }
        if viewModel.isLoading { return viewModel.statusMessage.isEmpty ? AppText.loading(settings.uiLanguage) : viewModel.statusMessage }
        if viewModel.isRecording {
            if let mode = viewModel.currentRecordingMode {
                return AppText.recordingStatus(mode: mode, language: settings.uiLanguage)
            }
            return AppText.recording(settings.uiLanguage)
        }
        if viewModel.isModelReady { return AppText.ready(settings.uiLanguage) }
        return AppText.idle(settings.uiLanguage)
    }
}
