import SwiftUI

struct MainWindowView: View {
    @Environment(CaptionViewModel.self) private var viewModel
    @Environment(CaptionSettings.self) private var settings

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            transcriptList
        }
        .frame(minWidth: 500, minHeight: 300)
        .preferredColorScheme(.dark)
    }

    private var toolbar: some View {
        HStack {
            if viewModel.isRecording {
                Button(action: { viewModel.stopCapture() }) {
                    Label(
                        viewModel.isTranslationOnlyActive
                            ? AppText.stopLiveTranslation(settings.uiLanguage)
                            : AppText.stopRecording(settings.uiLanguage),
                        systemImage: "stop.circle.fill"
                    )
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red.opacity(0.16))
                        )
                }
                .buttonStyle(.plain)
            } else {
                if settings.translationOnlyEnabled {
                    Button(action: startLiveTranslation) {
                        toolbarButtonContent(systemImage: "captions.bubble")
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoading)
                } else {
                    Menu {
                        Button(action: { startRecording(mode: .screenAndAudio) }) {
                            Label(AppText.screenPlusAudio(settings.uiLanguage), systemImage: "display.and.arrow.down")
                        }

                        Button(action: { startRecording(mode: .audioOnly) }) {
                            Label(AppText.audioOnly(settings.uiLanguage), systemImage: "waveform")
                        }
                    } label: {
                        toolbarButtonContent(systemImage: "record.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .disabled(viewModel.isLoading)
                }
            }

            if !viewModel.statusMessage.isEmpty {
                Text(viewModel.statusMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("Cmd+Shift+T")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var toolbarButtonLabel: String {
        if viewModel.isLoading { return AppText.loading(settings.uiLanguage) }
        return settings.translationOnlyEnabled
            ? AppText.startLiveTranslation(settings.uiLanguage)
            : AppText.record(settings.uiLanguage)
    }

    private func toolbarButtonContent(systemImage: String) -> some View {
        HStack(spacing: 6) {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: systemImage)
            }
            Text(toolbarButtonLabel)
                .font(.system(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.15))
        )
    }

    private func startRecording(mode: RecordingMode) {
        settings.recordingMode = mode
        Task { await viewModel.startCapture(mode: mode, translationOnly: false) }
    }

    private func startLiveTranslation() {
        Task {
            await viewModel.startCapture(
                mode: settings.recordingMode,
                translationOnly: true
            )
        }
    }

    private var transcriptList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.captionHistory) { entry in
                        CaptionRow(entry: entry)
                            .id(entry.id)
                    }

                    // Current streaming line (live)
                    if !viewModel.streamingEnglish.isEmpty {
                        StreamingRow(
                            english: viewModel.streamingEnglish,
                            chinese: viewModel.streamingChinese,
                            language: settings.uiLanguage
                        )
                        .id("streaming")
                    }
                }
                .padding(16)
            }
            .onChange(of: viewModel.captionHistory.count) {
                if let last = viewModel.captionHistory.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.streamingEnglish) {
                withAnimation {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }
        }
    }
}

private struct CaptionRow: View {
    let entry: CaptionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                .font(.system(size: 11))
                .foregroundStyle(.secondary.opacity(0.6))
            Text(entry.englishText)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
            Text(entry.chineseText)
                .font(.system(size: 13))
                .foregroundStyle(Color(red: 0.47, green: 0.78, blue: 1.0).opacity(0.8))
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.3)
        }
    }
}

private struct StreamingRow: View {
    let english: String
    let chinese: String
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                Text(AppText.live(language))
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green.opacity(0.8))
                }
            Text(english)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            if !chinese.isEmpty {
                Text(chinese)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 0.47, green: 0.78, blue: 1.0))
                    .contentTransition(.numericText())
            }
        }
        .padding(.vertical, 10)
        .animation(.easeInOut(duration: 0.15), value: english)
        .animation(.easeInOut(duration: 0.15), value: chinese)
    }
}
