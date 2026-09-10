import Testing
import Foundation
@testable import CapiX

private func resetCaptionSettingsDefaults() {
    let defaults = UserDefaults.standard
    for key in [
        "panelWidth",
        "fontSize",
        "selectedModelId",
        "translationTarget",
        "recordingOutputRootPath",
        "recordingMode",
        "transcriptExportEnabled",
        "translationOnlyEnabled",
        "uiLanguage",
    ] {
        defaults.removeObject(forKey: key)
    }
}

// MARK: - ASRModel

@Test func asrModelAvailableIsNotEmpty() {
    #expect(!ASRModel.available.isEmpty)
}

@Test func asrModelDefaultModelExistsInAvailable() {
    let defaultModel = ASRModel.defaultModel
    let found = ASRModel.available.contains { $0.id == defaultModel.id }
    #expect(found)
}

@Test func asrModelHasUniqueIds() {
    let ids = ASRModel.available.map { $0.id }
    #expect(Set(ids).count == ids.count)
}

@Test func asrModelDefaultIsMedium() {
    #expect(ASRModel.defaultModel.id == "medium-streaming-en")
}

// MARK: - CaptionSettings

@Test @MainActor func captionSettingsDefaultValues() {
    resetCaptionSettingsDefaults()

    let settings = CaptionSettings()
    #expect(settings.panelWidth == 620)
    #expect(settings.fontSize == 15)
    #expect(settings.selectedModelId == ASRModel.defaultModel.id)
    #expect(settings.uiLanguage == .english)
    #expect(settings.translationOnlyEnabled == false)
}

@Test @MainActor func captionSettingsSelectedModelProperty() {
    resetCaptionSettingsDefaults()

    let settings = CaptionSettings()
    #expect(settings.selectedModel.id == ASRModel.defaultModel.id)
    #expect(settings.selectedModel.name == ASRModel.defaultModel.name)
}

@Test @MainActor func captionSettingsPersistsPanelWidth() {
    resetCaptionSettingsDefaults()
    let defaults = UserDefaults.standard

    let settings = CaptionSettings()
    settings.panelWidth = 800
    #expect(defaults.double(forKey: "panelWidth") == 800)
}

@Test @MainActor func captionSettingsPersistsFontSize() {
    resetCaptionSettingsDefaults()
    let defaults = UserDefaults.standard

    let settings = CaptionSettings()
    settings.fontSize = 20
    #expect(defaults.double(forKey: "fontSize") == 20)
}

@Test @MainActor func captionSettingsPersistsModelId() {
    resetCaptionSettingsDefaults()
    let defaults = UserDefaults.standard

    let settings = CaptionSettings()
    settings.selectedModelId = "small-streaming-en"
    #expect(defaults.string(forKey: "selectedModelId") == "small-streaming-en")
}

@Test @MainActor func captionSettingsInvalidModelIdFallsBackToDefault() {
    resetCaptionSettingsDefaults()
    let defaults = UserDefaults.standard
    defaults.set("nonexistent-model", forKey: "selectedModelId")

    let settings = CaptionSettings()
    // Should fall back to default because "nonexistent-model" is not in available list
    #expect(settings.selectedModelId == ASRModel.defaultModel.id)
}

@Test @MainActor func captionSettingsSelectedModelFallbackForInvalidId() {
    resetCaptionSettingsDefaults()

    let settings = CaptionSettings()
    // Manually set an invalid id after init
    settings.selectedModelId = "invalid-model"
    // selectedModel should fall back to default
    #expect(settings.selectedModel.id == ASRModel.defaultModel.id)
}

@Test @MainActor func captionSettingsLoadsPersistedPanelWidth() {
    resetCaptionSettingsDefaults()
    let defaults = UserDefaults.standard
    defaults.set(750.0, forKey: "panelWidth")

    let settings = CaptionSettings()
    #expect(settings.panelWidth == 750)

    // Cleanup
    defaults.removeObject(forKey: "panelWidth")
}

@Test @MainActor func captionSettingsLoadsPersistedFontSize() {
    resetCaptionSettingsDefaults()
    let defaults = UserDefaults.standard
    defaults.set(18.0, forKey: "fontSize")

    let settings = CaptionSettings()
    #expect(settings.fontSize == 18)

    // Cleanup
    defaults.removeObject(forKey: "fontSize")
}

// MARK: - TranslationTarget

@Test func translationTargetRawValuesAreBCP47() {
    #expect(TranslationTarget.simplifiedChinese.rawValue == "zh-Hans")
    #expect(TranslationTarget.traditionalChineseTaiwan.rawValue == "zh-Hant-TW")
}

@Test func translationTargetAllCasesContainsBoth() {
    let ids = TranslationTarget.allCases.map(\.rawValue)
    #expect(ids.contains("zh-Hans"))
    #expect(ids.contains("zh-Hant-TW"))
}

@Test func translationTargetHasDisplayNames() {
    // Display names are for human readers; verify non-empty and distinct so
    // the Settings picker never shows two identical rows.
    let names = TranslationTarget.allCases.map(\.displayName)
    #expect(names.allSatisfy { !$0.isEmpty })
    #expect(Set(names).count == names.count)
}

@Test func translationTargetDisplayNamesAreLocalized() {
    #expect(TranslationTarget.simplifiedChinese.displayName(in: .english) == "Simplified Chinese")
    #expect(TranslationTarget.traditionalChineseTaiwan.displayName(in: .chinese) == "繁體中文（台灣）")
}

@Test func appLanguageDisplayNamesAreLocalized() {
    #expect(AppLanguage.english.displayName(in: .chinese) == "英文")
    #expect(AppLanguage.chinese.displayName(in: .english) == "Chinese")
}

@Test func recordingModeDisplayNamesAreLocalized() {
    #expect(RecordingMode.screenAndAudio.displayName(in: .chinese) == "屏幕 + 音频")
    #expect(RecordingMode.audioOnly.shortLabel(in: .english) == "Audio")
}

@Test @MainActor func captionSettingsDefaultTranslationTargetIsSimplified() {
    resetCaptionSettingsDefaults()
    let defaults = UserDefaults.standard

    let settings = CaptionSettings()
    #expect(settings.translationTarget == .simplifiedChinese)
}

@Test @MainActor func captionSettingsPersistsTranslationTarget() {
    resetCaptionSettingsDefaults()
    let defaults = UserDefaults.standard

    let settings = CaptionSettings()
    settings.translationTarget = .traditionalChineseTaiwan
    #expect(defaults.string(forKey: "translationTarget") == "zh-Hant-TW")

    // Cleanup
    defaults.removeObject(forKey: "translationTarget")
}

@Test @MainActor func captionSettingsPersistsUiLanguage() {
    resetCaptionSettingsDefaults()
    let defaults = UserDefaults.standard

    let settings = CaptionSettings()
    settings.uiLanguage = .chinese
    #expect(defaults.string(forKey: "uiLanguage") == AppLanguage.chinese.rawValue)
}

@Test @MainActor func captionSettingsLoadsPersistedTranslationTarget() {
    resetCaptionSettingsDefaults()
    let defaults = UserDefaults.standard
    defaults.set("zh-Hant-TW", forKey: "translationTarget")

    let settings = CaptionSettings()
    #expect(settings.translationTarget == .traditionalChineseTaiwan)

    // Cleanup
    defaults.removeObject(forKey: "translationTarget")
}

@Test @MainActor func captionSettingsInvalidTranslationTargetFallsBackToDefault() {
    resetCaptionSettingsDefaults()
    let defaults = UserDefaults.standard
    defaults.set("ja-JP", forKey: "translationTarget")

    let settings = CaptionSettings()
    #expect(settings.translationTarget == .simplifiedChinese)

    // Cleanup
    defaults.removeObject(forKey: "translationTarget")
}
