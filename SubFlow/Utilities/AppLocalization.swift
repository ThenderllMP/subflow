import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case chinese = "zh-Hans"

    var id: String { rawValue }

    var localeIdentifier: String { rawValue }

    func displayName(in language: AppLanguage) -> String {
        switch self {
        case .english:
            return localized("English", "英文", language: language)
        case .chinese:
            return localized("Chinese", "中文", language: language)
        }
    }
}

enum AppText {
    static func settings(_ language: AppLanguage) -> String { localized("Settings", "设置", language: language) }
    static func recording(_ language: AppLanguage) -> String { localized("Recording", "录制", language: language) }
    static func captureMode(_ language: AppLanguage) -> String { localized("Capture Mode", "录制方式", language: language) }
    static func exportSubtitles(_ language: AppLanguage) -> String { localized("Export subtitles to transcript", "将字幕导出为会议对话", language: language) }
    static func recordingOutputFolder(_ language: AppLanguage) -> String { localized("Recording output folder", "录制输出路径", language: language) }
    static func chooseFolder(_ language: AppLanguage) -> String { localized("Choose Folder", "选择文件夹", language: language) }
    static func recordingFolderHint(_ language: AppLanguage) -> String { localized("All recording files for each session are stored in a new folder under this location.", "每次录制都会在此路径下新建一个会话文件夹，所有文件都保存在其中。", language: language) }
    static func stopBeforeChangingRecordingSettings(_ language: AppLanguage) -> String { localized("Stop recording before changing recording settings", "请先停止录制，再修改录制设置", language: language) }
    static func display(_ language: AppLanguage) -> String { localized("Display", "显示", language: language) }
    static func panelWidth(_ language: AppLanguage) -> String { localized("Panel Width", "面板宽度", language: language) }
    static func fontSize(_ language: AppLanguage) -> String { localized("Font Size", "字号", language: language) }
    static func asrModel(_ language: AppLanguage) -> String { localized("ASR Model", "识别模型", language: language) }
    static func model(_ language: AppLanguage) -> String { localized("Model", "模型", language: language) }
    static func stopBeforeSwitchingModels(_ language: AppLanguage) -> String { localized("Stop recording before switching models", "请先停止录制，再切换模型", language: language) }
    static func translationLanguage(_ language: AppLanguage) -> String { localized("Translation Language", "翻译语言", language: language) }
    static func chineseVariant(_ language: AppLanguage) -> String { localized("Chinese variant", "中文版本", language: language) }
    static func stopBeforeSwitchingLanguages(_ language: AppLanguage) -> String { localized("Stop recording before switching languages", "请先停止录制，再切换语言", language: language) }
    static func interfaceLanguage(_ language: AppLanguage) -> String { localized("UI Language", "界面语言", language: language) }
    static func openTranscript(_ language: AppLanguage) -> String { localized("Open Transcript", "打开字幕文档", language: language) }
    static func quit(_ language: AppLanguage) -> String { localized("Quit", "退出", language: language) }
    static func record(_ language: AppLanguage) -> String { localized("Record", "录制", language: language) }
    static func stopRecording(_ language: AppLanguage) -> String { localized("Stop Recording", "停止录制", language: language) }
    static func screenPlusAudio(_ language: AppLanguage) -> String { localized("Screen + Audio", "屏幕 + 音频", language: language) }
    static func audioOnly(_ language: AppLanguage) -> String { localized("Audio Only", "仅音频", language: language) }
    static func loading(_ language: AppLanguage) -> String { localized("Loading…", "加载中…", language: language) }
    static func ready(_ language: AppLanguage) -> String { localized("Ready", "就绪", language: language) }
    static func idle(_ language: AppLanguage) -> String { localized("Idle", "空闲", language: language) }
    static func live(_ language: AppLanguage) -> String { localized("LIVE", "实时", language: language) }
    static func recordingStatus(mode: RecordingMode, language: AppLanguage) -> String { localized("Recording · \(mode.displayName(in: .english))", "录制 · \(mode.displayName(in: .chinese))", language: language) }
    static func loadingModel(_ modelName: String, language: AppLanguage) -> String { localized("Loading \(modelName)...", "正在加载 \(modelName)...", language: language) }
    static func downloadingModel(_ modelName: String, language: AppLanguage) -> String { localized("Downloading \(modelName)...", "正在下载 \(modelName)...", language: language) }
    static func modelLoadFailed(_ detail: String, language: AppLanguage) -> String { localized("Model load failed: \(detail)", "模型加载失败：\(detail)", language: language) }
    static func modelSwitchFailed(_ detail: String, language: AppLanguage) -> String { localized("Failed: \(detail)", "失败：\(detail)", language: language) }
    static func modelNotAvailable(_ language: AppLanguage) -> String { localized("Model not available", "模型不可用", language: language) }
    static func streamError(_ detail: String, language: AppLanguage) -> String { localized("Stream error: \(detail)", "流错误：\(detail)", language: language) }
    static func errorPrefix(_ language: AppLanguage) -> String { localized("Error: ", "错误：", language: language) }
    static func firstLaunchOnly(_ language: AppLanguage) -> String { localized("First launch only. The model will be cached for next time.", "首次启动时下载一次，之后会缓存到本机。", language: language) }
    static func modelDownloadFailed(_ language: AppLanguage) -> String { localized("Model download failed", "模型下载失败", language: language) }
    static func dismiss(_ language: AppLanguage) -> String { localized("Dismiss", "关闭", language: language) }
    static func retry(_ language: AppLanguage) -> String { localized("Retry", "重试", language: language) }
    static func extracting(_ language: AppLanguage) -> String { localized("Extracting…", "正在解压中…", language: language) }
    static func chooseRecordingFolderTitle(_ language: AppLanguage) -> String { localized("Choose Recording Folder", "选择录制文件夹", language: language) }
    static func firstTimeSetupTitle(_ language: AppLanguage) -> String { localized("CapiX — First-time Setup", "CapiX — 首次设置", language: language) }
    static func settingsWindowTitle(_ language: AppLanguage) -> String { localized("Settings", "设置", language: language) }
    static func transcriptWindowTitle(_ language: AppLanguage) -> String { localized("CapiX", "CapiX", language: language) }
    static func downloadingStatus(_ language: AppLanguage) -> String { localized("Downloading", "正在下载", language: language) }
    static func screenRecordingPermissionDenied(_ language: AppLanguage) -> String { localized("Screen recording permission is still not active. Open System Settings > Privacy & Security > Screen Recording, enable CapiX, then quit and reopen the app.", "屏幕录制权限仍未生效。请前往系统设置 > 隐私与安全性 > 屏幕录制，开启 CapiX，然后退出并重新打开应用。", language: language) }
    static func noDisplayFound(_ language: AppLanguage) -> String { localized("No display found for screen capture", "未找到可用于屏幕捕获的显示器", language: language) }
    static func couldNotStartScreenRecording(_ language: AppLanguage) -> String { localized("Could not start screen recording", "无法开始屏幕录制", language: language) }
    static func audioFormatUnavailable(_ language: AppLanguage) -> String { localized("Audio format is unavailable", "音频格式不可用", language: language) }
    static func couldNotCreateAudioRecordingFile(_ path: String, language: AppLanguage) -> String { localized("Could not create audio recording file: \(path)", "无法创建音频录制文件：\(path)", language: language) }
    static func recordingFolderUnavailable(_ path: String, language: AppLanguage) -> String { localized("Recording folder is unavailable: \(path)", "录制文件夹不可用：\(path)", language: language) }
    static func recordingFolderNotWritable(_ path: String, language: AppLanguage) -> String { localized("Recording folder is not writable: \(path)", "录制文件夹不可写：\(path)", language: language) }
    static func couldNotCreateRecordingSessionFolder(_ path: String, language: AppLanguage) -> String { localized("Could not create recording session folder: \(path)", "无法创建录制会话文件夹：\(path)", language: language) }
    static func couldNotCreateTranscriptDocument(_ path: String, language: AppLanguage) -> String { localized("Could not create transcript document: \(path)", "无法创建字幕文档：\(path)", language: language) }
}

enum AppMessage {
    case loadingModel(String)
    case downloadingModel(String)
    case modelLoadFailed(String)
    case modelSwitchFailed(String)
    case modelNotAvailable
    case streamError(String)
    case captureError(String)
    case screenRecordingDenied
    case noDisplayFound
    case recordingOutputFailed
    case audioFormatUnavailable
    case audioFileFailed(String)
    case recordingFolderUnavailable(String)
    case recordingFolderNotWritable(String)
    case sessionCreationFailed(String)
    case transcriptCreationFailed(String)

    func text(language: AppLanguage) -> String {
        switch self {
        case let .loadingModel(modelName):
            return AppText.loadingModel(modelName, language: language)
        case let .downloadingModel(modelName):
            return AppText.downloadingModel(modelName, language: language)
        case let .modelLoadFailed(detail):
            return AppText.modelLoadFailed(detail, language: language)
        case let .modelSwitchFailed(detail):
            return AppText.modelSwitchFailed(detail, language: language)
        case .modelNotAvailable:
            return AppText.modelNotAvailable(language)
        case let .streamError(detail):
            return AppText.streamError(detail, language: language)
        case let .captureError(detail):
            return AppText.errorPrefix(language) + detail
        case .screenRecordingDenied:
            return AppText.screenRecordingPermissionDenied(language)
        case .noDisplayFound:
            return AppText.noDisplayFound(language)
        case .recordingOutputFailed:
            return AppText.couldNotStartScreenRecording(language)
        case .audioFormatUnavailable:
            return AppText.audioFormatUnavailable(language)
        case let .audioFileFailed(path):
            return AppText.couldNotCreateAudioRecordingFile(path, language: language)
        case let .recordingFolderUnavailable(path):
            return AppText.recordingFolderUnavailable(path, language: language)
        case let .recordingFolderNotWritable(path):
            return AppText.recordingFolderNotWritable(path, language: language)
        case let .sessionCreationFailed(path):
            return AppText.couldNotCreateRecordingSessionFolder(path, language: language)
        case let .transcriptCreationFailed(path):
            return AppText.couldNotCreateTranscriptDocument(path, language: language)
        }
    }
}

private func localized(_ english: String, _ chinese: String, language: AppLanguage) -> String {
    switch language {
    case .english:
        return english
    case .chinese:
        return chinese
    }
}
