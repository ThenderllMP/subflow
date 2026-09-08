import Foundation

/// BCP-47 targets that the Apple Translation framework understands for
/// English → Chinese. The raw value is what gets written to UserDefaults and
/// passed to `Locale.Language(identifier:)`, so it must round-trip cleanly.
enum TranslationTarget: String, CaseIterable, Identifiable {
    case simplifiedChinese = "zh-Hans"
    case traditionalChineseTaiwan = "zh-Hant-TW"

    var id: String { rawValue }

    func displayName(in language: AppLanguage) -> String {
        switch self {
        case .simplifiedChinese:
            return language == .chinese ? "简体中文" : "Simplified Chinese"
        case .traditionalChineseTaiwan:
            return language == .chinese ? "繁體中文（台灣）" : "Traditional Chinese (Taiwan)"
        }
    }

    var displayName: String {
        displayName(in: .english)
    }
}

struct ASRModel: Identifiable, Hashable {
    let id: String
    let name: String
    let size: String
    let speed: String
    let accuracy: String

    static let available: [ASRModel] = [
        ASRModel(
            id: "small-streaming-en",
            name: "Moonshine Small",
            size: "~157MB",
            speed: "~73ms",
            accuracy: "Good"
        ),
        ASRModel(
            id: "medium-streaming-en",
            name: "Moonshine Medium",
            size: "~303MB",
            speed: "~107ms",
            accuracy: "Great"
        ),
    ]

    static let defaultModel = available[1]

    func accuracyLabel(in language: AppLanguage) -> String {
        switch accuracy {
        case "Good":
            return language == .chinese ? "良好" : "Good"
        case "Great":
            return language == .chinese ? "优秀" : "Great"
        default:
            return accuracy
        }
    }
}

@MainActor
@Observable
final class CaptionSettings {
    static let defaultRecordingRootPath = RecordingWorkspace.defaultRootURL.path

    var panelWidth: CGFloat {
        didSet { UserDefaults.standard.set(Double(panelWidth), forKey: "panelWidth") }
    }

    var fontSize: CGFloat {
        didSet { UserDefaults.standard.set(Double(fontSize), forKey: "fontSize") }
    }

    var selectedModelId: String {
        didSet { UserDefaults.standard.set(selectedModelId, forKey: "selectedModelId") }
    }

    var translationTarget: TranslationTarget {
        didSet {
            UserDefaults.standard.set(translationTarget.rawValue, forKey: "translationTarget")
        }
    }

    var recordingOutputRootPath: String {
        didSet {
            UserDefaults.standard.set(recordingOutputRootPath, forKey: "recordingOutputRootPath")
        }
    }

    var recordingMode: RecordingMode {
        didSet {
            UserDefaults.standard.set(recordingMode.rawValue, forKey: "recordingMode")
        }
    }

    var uiLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(uiLanguage.rawValue, forKey: "uiLanguage")
        }
    }

    var transcriptExportEnabled: Bool {
        didSet {
            UserDefaults.standard.set(transcriptExportEnabled, forKey: "transcriptExportEnabled")
        }
    }

    var selectedModel: ASRModel {
        ASRModel.available.first { $0.id == selectedModelId } ?? ASRModel.defaultModel
    }

    init() {
        let defaults = UserDefaults.standard
        let savedWidth = defaults.double(forKey: "panelWidth")
        panelWidth = savedWidth > 0 ? CGFloat(savedWidth) : 620

        let savedFontSize = defaults.double(forKey: "fontSize")
        fontSize = savedFontSize > 0 ? CGFloat(savedFontSize) : 15

        let savedModelId = defaults.string(forKey: "selectedModelId")
        // Migrate from WhisperKit model IDs to Moonshine default
        if let saved = savedModelId, ASRModel.available.contains(where: { $0.id == saved }) {
            selectedModelId = saved
        } else {
            selectedModelId = ASRModel.defaultModel.id
        }

        let savedTarget = defaults.string(forKey: "translationTarget")
            .flatMap(TranslationTarget.init(rawValue:))
        translationTarget = savedTarget ?? .simplifiedChinese

        let savedRootPath = defaults.string(forKey: "recordingOutputRootPath")
        recordingOutputRootPath = savedRootPath ?? Self.defaultRecordingRootPath

        let savedMode = defaults.string(forKey: "recordingMode")
            .flatMap(RecordingMode.init(rawValue:))
        recordingMode = savedMode ?? .screenAndAudio

        let savedLanguage = defaults.string(forKey: "uiLanguage")
            .flatMap(AppLanguage.init(rawValue:))
        uiLanguage = savedLanguage ?? .english

        transcriptExportEnabled = defaults.object(forKey: "transcriptExportEnabled") as? Bool ?? false
    }
}
