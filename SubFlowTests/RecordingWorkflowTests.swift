import Foundation
import Testing
@testable import CapiX

@Test @MainActor func recordingSettingsPersistAcrossRelaunch() {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: "recordingOutputRootPath")
    defaults.removeObject(forKey: "recordingMode")
    defaults.removeObject(forKey: "transcriptExportEnabled")
    defaults.removeObject(forKey: "translationOnlyEnabled")

    let settings = CaptionSettings()
    settings.recordingOutputRootPath = "/tmp/capix-recordings"
    settings.recordingMode = .audioOnly
    settings.transcriptExportEnabled = true
    settings.translationOnlyEnabled = true

    #expect(defaults.string(forKey: "recordingOutputRootPath") == "/tmp/capix-recordings")
    #expect(defaults.string(forKey: "recordingMode") == RecordingMode.audioOnly.rawValue)
    #expect(defaults.bool(forKey: "transcriptExportEnabled") == true)
    #expect(defaults.bool(forKey: "translationOnlyEnabled") == true)

    let reloaded = CaptionSettings()
    #expect(reloaded.recordingOutputRootPath == "/tmp/capix-recordings")
    #expect(reloaded.recordingMode == .audioOnly)
    #expect(reloaded.transcriptExportEnabled == true)
    #expect(reloaded.translationOnlyEnabled == true)
}

@Test func translationOnlyPlanBypassesWorkspaceAndTranscriptExport() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("capix-translation-only-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let plan = try CaptureSessionPlan.prepare(
        translationOnly: true,
        rootPath: root.path,
        mode: .screenAndAudio,
        transcriptExportEnabled: true
    )

    #expect(plan.output == .none)
    #expect(plan.paths == nil)
    #expect(plan.recordingMode == nil)
    #expect(plan.isTranslationOnly)
    #expect(plan.shouldExportTranscript == false)
    #expect(!FileManager.default.fileExists(atPath: root.path))
}

@Test func persistentCapturePlanUsesSelectedModeAndWorkspace() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("capix-capture-plan-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let plan = try CaptureSessionPlan.prepare(
        translationOnly: false,
        rootPath: root.path,
        mode: .audioOnly,
        transcriptExportEnabled: true
    )

    #expect(plan.recordingMode == .audioOnly)
    #expect(!plan.isTranslationOnly)
    #expect(plan.shouldExportTranscript)
    #expect(plan.paths != nil)
    guard case .audioOnly(let mediaURL) = plan.output else {
        Issue.record("Expected an audio-only recording output")
        return
    }
    #expect(mediaURL.pathExtension == "caf")
    #expect(FileManager.default.fileExists(atPath: plan.paths?.sessionURL.path ?? ""))
}

@Test func recordingWorkspaceCreatesPerSessionFolders() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("capix-workspace-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let screenSession = try RecordingWorkspace.prepareSession(
        rootPath: root.path,
        mode: .screenAndAudio,
        now: Date(timeIntervalSince1970: 1_700_000_000)
    )
    let audioSession = try RecordingWorkspace.prepareSession(
        rootPath: root.path,
        mode: .audioOnly,
        now: Date(timeIntervalSince1970: 1_700_000_001)
    )

    #expect(FileManager.default.fileExists(atPath: screenSession.sessionURL.path))
    #expect(FileManager.default.fileExists(atPath: audioSession.sessionURL.path))
    #expect(screenSession.mediaURL.pathExtension == "mp4")
    #expect(audioSession.mediaURL.pathExtension == "caf")
    #expect(screenSession.transcriptURL.lastPathComponent == "transcript.txt")
    #expect(screenSession.mediaURL.deletingLastPathComponent() == screenSession.sessionURL)
    #expect(audioSession.mediaURL.deletingLastPathComponent() == audioSession.sessionURL)
}

@Test func recordingWorkspaceRejectsNonDirectoryRoots() throws {
    let rootFile = FileManager.default.temporaryDirectory
        .appendingPathComponent("capix-root-\(UUID().uuidString).txt")
    try "not a folder".write(to: rootFile, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: rootFile) }

    do {
        _ = try RecordingWorkspace.prepareSession(
            rootPath: rootFile.path,
            mode: .audioOnly
        )
        Issue.record("Expected prepareSession to fail for a non-directory root")
    } catch {
        #expect(error is RecordingWorkspaceError)
    }
}

@Test func transcriptDocumentWriterWritesBilingualEntries() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("capix-transcript-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let session = try RecordingWorkspace.prepareSession(rootPath: root.path, mode: .audioOnly)
    let startedAt = Date(timeIntervalSince1970: 1_700_000_123)
    let entryTime = Date(timeIntervalSince1970: 1_700_000_456)

    let writer = try TranscriptDocumentWriter(
        sessionURL: session.sessionURL,
        transcriptURL: session.transcriptURL,
        mode: .audioOnly,
        startedAt: startedAt
    )
    try writer.append(
        entry: CaptionEntry(
            timestamp: entryTime,
            englishText: "Hello everyone",
            chineseText: "大家好"
        )
    )
    writer.finish()

    let contents = try String(contentsOf: session.transcriptURL, encoding: .utf8)
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    #expect(contents.contains("CapiX Meeting Transcript"))
    #expect(contents.contains("Mode: Audio Only"))
    #expect(contents.contains(formatter.string(from: startedAt)))
    #expect(contents.contains(formatter.string(from: entryTime)))
    #expect(contents.contains("Original: Hello everyone"))
    #expect(contents.contains("Translation: 大家好"))
}

@Test func screenRecordingPermissionMessageExplainsRelaunch() {
    let message = RecordingPermissionError.screenRecordingDenied.localizedDescription

    #expect(message.contains("quit and reopen"))
    #expect(message.contains("Screen Recording"))
}
