import Foundation

enum RecordingMode: String, CaseIterable, Identifiable, Sendable {
    case screenAndAudio = "screenAndAudio"
    case audioOnly = "audioOnly"

    var id: String { rawValue }

    func displayName(in language: AppLanguage) -> String {
        switch self {
        case .screenAndAudio:
            return language == .chinese ? "屏幕 + 音频" : "Screen + Audio"
        case .audioOnly:
            return language == .chinese ? "仅音频" : "Audio Only"
        }
    }

    var displayName: String {
        displayName(in: .english)
    }

    func shortLabel(in language: AppLanguage) -> String {
        switch self {
        case .screenAndAudio:
            return language == .chinese ? "屏幕" : "Screen"
        case .audioOnly:
            return language == .chinese ? "音频" : "Audio"
        }
    }

    var shortLabel: String {
        shortLabel(in: .english)
    }

    var fileExtension: String {
        switch self {
        case .screenAndAudio:
            return "mp4"
        case .audioOnly:
            return "caf"
        }
    }

    var fileNameComponent: String {
        switch self {
        case .screenAndAudio:
            return "screen-audio"
        case .audioOnly:
            return "audio-only"
        }
    }
}
