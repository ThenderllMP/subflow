import AppKit
import SwiftUI

struct SettingsView: View {
    @Environment(CaptionSettings.self) private var settings
    @Environment(CaptionViewModel.self) private var viewModel

    var body: some View {
        @Bindable var settings = settings
        let language = settings.uiLanguage

        Form {
            Section {
                Picker(AppText.interfaceLanguage(language), selection: $settings.uiLanguage) {
                    ForEach(AppLanguage.allCases) { appLanguage in
                        Text(appLanguage.displayName(in: language)).tag(appLanguage)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text(AppText.interfaceLanguage(language))
            }

            Section {
                Picker(AppText.captureMode(language), selection: $settings.recordingMode) {
                    ForEach(RecordingMode.allCases) { mode in
                        Text(mode.shortLabel(in: language)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(viewModel.isRecording)

                Toggle(AppText.exportSubtitles(language), isOn: $settings.transcriptExportEnabled)
                    .disabled(viewModel.isRecording)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        TextField(AppText.recordingOutputFolder(language), text: $settings.recordingOutputRootPath)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                            .frame(minWidth: 240)

                        Button(action: chooseRecordingFolder) {
                            Label(AppText.chooseFolder(language), systemImage: "folder")
                        }
                        .disabled(viewModel.isRecording)
                    }

                    Text(AppText.recordingFolderHint(language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if viewModel.isRecording {
                    Text(AppText.stopBeforeChangingRecordingSettings(language))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text(AppText.recording(language))
            }

            Section {
                LabeledContent(AppText.panelWidth(language)) {
                    HStack {
                        Slider(value: $settings.panelWidth, in: 400...1000, step: 20)
                        Text("\(Int(settings.panelWidth))pt")
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                    }
                }

                LabeledContent(AppText.fontSize(language)) {
                    HStack {
                        Slider(value: $settings.fontSize, in: 10...24, step: 1)
                        Text("\(Int(settings.fontSize))pt")
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            } header: {
                Text(AppText.display(language))
            }

            Section {
                Picker(AppText.model(language), selection: $settings.selectedModelId) {
                    ForEach(ASRModel.available) { model in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.name)
                            Text("\(model.size) · \(model.speed) · \(model.accuracyLabel(in: language))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(model.id)
                    }
                }
                .pickerStyle(.radioGroup)

                if viewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(viewModel.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if viewModel.isRecording {
                    Text(AppText.stopBeforeSwitchingModels(language))
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            } header: {
                Text(AppText.asrModel(language))
            }

            Section {
                Picker(AppText.chineseVariant(language), selection: $settings.translationTarget) {
                    ForEach(TranslationTarget.allCases) { target in
                        Text(target.displayName(in: language)).tag(target)
                    }
                }
                .pickerStyle(.radioGroup)
                .disabled(viewModel.isRecording)

                if viewModel.isRecording {
                    Text(AppText.stopBeforeSwitchingLanguages(language))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text(AppText.translationLanguage(language))
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 580)
        .onChange(of: settings.selectedModelId) { _, newModelId in
            guard !viewModel.isRecording, !viewModel.isLoading else { return }
            viewModel.switchModel(to: newModelId)
        }
    }

    private func chooseRecordingFolder() {
        let panel = NSOpenPanel()
        panel.title = AppText.chooseRecordingFolderTitle(settings.uiLanguage)
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = URL(fileURLWithPath: settings.recordingOutputRootPath)

        if panel.runModal() == .OK, let url = panel.url {
            settings.recordingOutputRootPath = url.path
        }
    }
}
