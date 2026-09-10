import Foundation
import SwiftUI
import Translation

@MainActor
@Observable
final class CaptionViewModel {
    var isRecording = false
    var isLoading = false
    var isModelReady = false
    var preferredUILanguage: AppLanguage = .english
    var preferredRecordingMode: RecordingMode = .screenAndAudio
    var preferredRecordingRootPath: String = CaptionSettings.defaultRecordingRootPath
    var transcriptExportEnabled = false
    var preferredTranslationOnly = false
    var currentRecordingMode: RecordingMode?
    var isTranslationOnlyActive = false
    /// In-flight model download progress in `[0, 1]`. `nil` when no download is
    /// running (either already on disk or not yet started).
    var downloadProgress: Double?

    /// Current streaming English (live preview while speaker talks)
    var streamingEnglish = ""
    /// Current completed Chinese translation (appears when sentence finishes)
    var streamingChinese = ""
    var streamingWords: [WordTimestamp] = []

    var captionHistory: [CaptionEntry] = []
    var recentCaptions: [CaptionEntry] = []

    let translationService = TranslationService()

    private let maxRecentCaptions = 2
    private var statusState: AppMessage?
    /// Last user-facing model-loading error. The download progress window keeps
    /// itself on screen until this is cleared so the error is never silently
    /// swallowed by window auto-dismiss.
    private var downloadErrorState: AppMessage?
    private var audioCaptureService: AudioCaptureService?
    private var moonshineService: MoonshineTranscriptionService?
    private var activeRecordingSession: ActiveRecordingSession?
    private var accumulatorTask: Task<Void, Never>?
    private var completionDisplayTask: Task<Void, Never>?
    private var cleanupTask: Task<Void, Never>?
    /// Increments on every onTextChanged. Used to detect if new streaming
    /// started while a translation was in-flight.
    private var streamingGeneration = 0

    var statusMessage: String {
        statusState?.text(language: preferredUILanguage) ?? ""
    }

    var downloadError: String? {
        downloadErrorState?.text(language: preferredUILanguage)
    }

    private func setStatus(_ message: AppMessage?) {
        statusState = message
    }

    private func setDownloadError(_ message: AppMessage?) {
        downloadErrorState = message
    }

    // MARK: - Lifecycle

    private final class ActiveRecordingSession {
        let mode: RecordingMode
        let paths: RecordingSessionPaths
        var transcriptWriter: TranscriptDocumentWriter?

        init(
            mode: RecordingMode,
            paths: RecordingSessionPaths,
            transcriptWriter: TranscriptDocumentWriter?
        ) {
            self.mode = mode
            self.paths = paths
            self.transcriptWriter = transcriptWriter
        }
    }

    func preloadModel(modelId: String = ASRModel.defaultModel.id) {
        guard !isModelReady, !isLoading else { return }
        let modelName = ASRModel.available.first { $0.id == modelId }?.name ?? "model"
        isLoading = true
        setStatus(.loadingModel(modelName))
        downloadProgress = nil
        setDownloadError(nil)

        Task {
            do {
                AppLogger.log("Loading Moonshine model: \(modelId)")
                let service = try await MoonshineTranscriptionService.load(
                    modelId: modelId,
                    onDownloadProgress: { [weak self] p in
                        Task { @MainActor [weak self] in
                            self?.downloadProgress = p
                            if let self, self.statusState == nil || self.statusState?.text(language: self.preferredUILanguage).hasPrefix(AppText.downloadingStatus(self.preferredUILanguage)) == false {
                                self.setStatus(.downloadingModel(modelName))
                            }
                        }
                    }
                )
                self.moonshineService = service
                self.isModelReady = true
                self.setStatus(nil)
                self.downloadProgress = nil
                self.setDownloadError(nil)
                AppLogger.log("Model loaded successfully: \(modelId)")
            } catch {
                AppLogger.log("Model load failed: \(Self.describe(error))")
                self.setStatus(.modelLoadFailed(error.localizedDescription))
                // Set error BEFORE clearing progress so the progress window
                // observer sees (downloadError != nil) and keeps the window up
                // with an error state for the user to dismiss.
                self.setDownloadError(.modelLoadFailed(error.localizedDescription))
                self.downloadProgress = nil
            }
            self.isLoading = false
        }
    }

    /// Produce a detailed log line for an error, walking the `NSError` chain so
    /// URLSession's `-1200 NSURLErrorSecureConnectionFailed` / etc. surface
    /// their underlying CFStream/OSStatus codes instead of the friendly string
    /// alone.
    private nonisolated static func describe(_ error: Error) -> String {
        var parts: [String] = []
        var current: NSError? = error as NSError
        var depth = 0
        while let err = current, depth < 4 {
            parts.append("\(err.domain) code=\(err.code) \"\(err.localizedDescription)\"")
            current = err.userInfo[NSUnderlyingErrorKey] as? NSError
            depth += 1
        }
        return parts.joined(separator: " → ")
    }

    /// Dismiss the last `downloadError`, e.g. after the user clicks the
    /// "Dismiss" button in `ModelDownloadProgressView`.
    func clearDownloadError() {
        setDownloadError(nil)
    }

    func switchModel(to modelId: String) {
        guard !isLoading else { return }

        if isRecording {
            stopCapture()
        }

        moonshineService?.close()
        moonshineService = nil
        isModelReady = false
        isLoading = true
        let modelName = ASRModel.available.first { $0.id == modelId }?.name ?? "model"
        setStatus(.loadingModel(modelName))
        downloadProgress = nil
        setDownloadError(nil)

        Task {
            do {
                AppLogger.log("Switching to model: \(modelId)")
                let service = try await MoonshineTranscriptionService.load(
                    modelId: modelId,
                    onDownloadProgress: { [weak self] p in
                        Task { @MainActor [weak self] in
                            self?.downloadProgress = p
                            if let self, self.statusState == nil || self.statusState?.text(language: self.preferredUILanguage).hasPrefix(AppText.downloadingStatus(self.preferredUILanguage)) == false {
                                self.setStatus(.downloadingModel(modelName))
                            }
                        }
                    }
                )
                self.moonshineService = service
                self.isModelReady = true
                self.setStatus(nil)
                self.downloadProgress = nil
                self.setDownloadError(nil)
                AppLogger.log("Model switched successfully: \(modelId)")
            } catch {
                AppLogger.log("Model switch failed: \(error.localizedDescription)")
                self.setStatus(.modelSwitchFailed(error.localizedDescription))
                self.setDownloadError(.modelSwitchFailed(error.localizedDescription))
                self.downloadProgress = nil
            }
            self.isLoading = false
        }
    }

    func setTranslationSession(_ session: TranslationSession) {
        translationService.setSession(session)
    }

    func addCaption(english: String, chinese: String) {
        appendCaption(english: english, chinese: chinese, timestamp: .now)
    }

    private func appendCaption(
        english: String,
        chinese: String,
        timestamp: Date,
        transcriptWriter: TranscriptDocumentWriter? = nil
    ) {
        let entry = CaptionEntry(
            timestamp: timestamp,
            englishText: english,
            chineseText: chinese
        )
        captionHistory.append(entry)
        recentCaptions.append(entry)
        while recentCaptions.count > maxRecentCaptions {
            recentCaptions.removeFirst()
        }
        let writer = transcriptWriter ?? activeRecordingSession?.transcriptWriter
        if let writer {
            do {
                try writer.append(entry: entry)
            } catch {
                AppLogger.log("Transcript append failed: \(error.localizedDescription)")
            }
        }
        scheduleCleanup()
    }

    func clearHistory() {
        captionHistory = []
        recentCaptions = []
        streamingEnglish = ""
        streamingChinese = ""
        streamingWords = []
        completionDisplayTask?.cancel()
        completionDisplayTask = nil
        cleanupTask?.cancel()
        cleanupTask = nil
    }

    // MARK: - Capture Control

    func toggleCapture(
        mode: RecordingMode? = nil,
        translationOnly: Bool? = nil
    ) {
        AppLogger.log("toggleCapture called, isRecording=\(isRecording), isModelReady=\(isModelReady)")
        if isRecording {
            stopCapture()
        } else {
            Task {
                await startCapture(
                    mode: mode ?? preferredRecordingMode,
                    translationOnly: translationOnly
                )
            }
        }
    }

    func startCapture(
        mode: RecordingMode = .screenAndAudio,
        translationOnly: Bool? = nil
    ) async {
        guard !isRecording else { return }
        let translationOnly = translationOnly ?? preferredTranslationOnly

        if !isModelReady {
            preloadModel()
            while isLoading { try? await Task.sleep(for: .milliseconds(100)) }
            guard isModelReady else { return }
        }

        guard moonshineService != nil else {
            setStatus(.modelNotAvailable)
            return
        }

        do {
            try RecordingPermissionManager.ensureScreenRecordingAccess()

            let plan = try CaptureSessionPlan.prepare(
                translationOnly: translationOnly,
                rootPath: preferredRecordingRootPath,
                mode: mode,
                transcriptExportEnabled: transcriptExportEnabled
            )
            let audioService = RecordingCaptureService(output: plan.output)
            let audioStream = audioService.makeAudioStream()

            let recordingTranscriptWriter: TranscriptDocumentWriter?
            if plan.shouldExportTranscript, let sessionPaths = plan.paths {
                recordingTranscriptWriter = try TranscriptDocumentWriter(
                    sessionURL: sessionPaths.sessionURL,
                    transcriptURL: sessionPaths.transcriptURL,
                    mode: mode
                )
            } else {
                recordingTranscriptWriter = nil
            }

            let session = plan.paths.map { sessionPaths in
                ActiveRecordingSession(
                    mode: mode,
                    paths: sessionPaths,
                    transcriptWriter: recordingTranscriptWriter
                )
            }

            self.activeRecordingSession = session
            self.currentRecordingMode = plan.recordingMode
            self.isTranslationOnlyActive = plan.isTranslationOnly
            self.audioCaptureService = audioService
            self.isRecording = true
            self.setStatus(nil)
            self.preferredRecordingMode = mode

            runPipeline(audioStream: audioStream)
            try await audioService.start()
            let activity = translationOnly ? "live translation" : mode.displayName
            AppLogger.log("Capture started: \(activity)")
        } catch {
            AppLogger.log("Failed to start capture: \(error.localizedDescription)")
            setStatus(Self.captureFailureState(for: error))
            accumulatorTask?.cancel()
            accumulatorTask = nil
            completionDisplayTask?.cancel()
            completionDisplayTask = nil
            try? moonshineService?.stopStream()
            Task { await audioCaptureService?.stop() }
            activeRecordingSession?.transcriptWriter?.finish()
            activeRecordingSession = nil
            audioCaptureService = nil
            isRecording = false
            currentRecordingMode = nil
            isTranslationOnlyActive = false
        }
    }

    func stopCapture() {
        let finalTranscriptWriter = activeRecordingSession?.transcriptWriter
        let remainingEnglish = streamingEnglish
        let remainingChinese = streamingChinese

        isRecording = false
        currentRecordingMode = nil
        isTranslationOnlyActive = false
        activeRecordingSession = nil
        accumulatorTask?.cancel()
        accumulatorTask = nil
        completionDisplayTask?.cancel()
        completionDisplayTask = nil

        try? moonshineService?.stopStream()

        let service = audioCaptureService
        audioCaptureService = nil
        Task { await service?.stop() }

        streamingEnglish = ""
        streamingChinese = ""
        streamingWords = []

        guard !remainingEnglish.isEmpty else {
            finalTranscriptWriter?.finish()
            return
        }

        Task {
            let chinese: String
            if !remainingChinese.isEmpty {
                chinese = remainingChinese
            } else {
                chinese = (try? await translationService.translate(remainingEnglish)) ?? ""
            }

            await MainActor.run {
                self.appendCaption(
                    english: remainingEnglish,
                    chinese: chinese,
                    timestamp: .now,
                    transcriptWriter: finalTranscriptWriter
                )
                finalTranscriptWriter?.finish()
            }
        }
    }

    // MARK: - Moonshine Streaming Pipeline
    //
    // YouTube-style logic:
    //   onTextChanged  → show English live preview (no Chinese)
    //   onLineCompleted → translate → show complete EN + ZH pair
    //   Next sentence arrives → old pair moves to history

    private func runPipeline(audioStream: AsyncStream<[Float]>) {
        guard let moonshine = moonshineService else { return }

        moonshine.onTextChanged = { [weak self] text, words in
            guard let self else { return }

            // Bump generation — any in-flight translation older than this
            // must go to history, not overwrite the display.
            self.streamingGeneration += 1

            // If a completed caption is being displayed, flush it to history
            if self.completionDisplayTask != nil {
                self.completionDisplayTask?.cancel()
                self.completionDisplayTask = nil
                if !self.streamingChinese.isEmpty {
                    self.addCaption(
                        english: self.streamingEnglish,
                        chinese: self.streamingChinese
                    )
                }
            }

            // Show live English preview — no Chinese until sentence completes
            self.streamingEnglish = text
            self.streamingChinese = ""
            self.streamingWords = words
        }

        moonshine.onLineCompleted = { [weak self] text, words in
            guard let self else { return }
            AppLogger.log("Completed EN: \(text)")

            // Snapshot the generation BEFORE awaiting translation.
            let genAtCompletion = self.streamingGeneration

            Task {
                let chinese = (try? await self.translationService.translate(text)) ?? ""
                AppLogger.log("Completed ZH: \(chinese)")

                // If generation changed, new streaming started while we were
                // translating → send this to history, don't touch the display.
                guard self.streamingGeneration == genAtCompletion else {
                    self.addCaption(english: text, chinese: chinese)
                    return
                }

                // No new streaming — safe to show the completed pair
                self.streamingEnglish = text
                self.streamingChinese = chinese
                self.streamingWords = []

                self.completionDisplayTask = Task {
                    let displayTime = Self.estimateReadingTime(
                        english: text, chinese: chinese
                    )
                    try? await Task.sleep(for: .seconds(displayTime))
                    guard !Task.isCancelled else { return }
                    self.addCaption(english: text, chinese: chinese)
                    self.streamingEnglish = ""
                    self.streamingChinese = ""
                }
            }
        }

        do {
            try moonshine.startStream(updateInterval: 0.5)
        } catch {
            AppLogger.log("Failed to start Moonshine stream: \(error.localizedDescription)")
            setStatus(.streamError(error.localizedDescription))
            return
        }

        accumulatorTask = Task {
            for await samples in audioStream {
                if Task.isCancelled { break }
                do {
                    try moonshine.addAudio(samples, sampleRate: 16000)
                } catch {
                    AppLogger.log("Moonshine addAudio error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Display Timing

    private func scheduleCleanup() {
        cleanupTask?.cancel()
        cleanupTask = Task {
            while !recentCaptions.isEmpty {
                guard let oldest = recentCaptions.first else { break }
                let readingTime = Self.estimateReadingTime(
                    english: oldest.englishText,
                    chinese: oldest.chineseText
                )
                let age = Date.now.timeIntervalSince(oldest.timestamp)
                let remaining = readingTime - age

                if remaining > 0 {
                    try? await Task.sleep(for: .seconds(remaining))
                    if Task.isCancelled { break }
                }

                if !recentCaptions.isEmpty {
                    recentCaptions.removeFirst()
                }
            }
        }
    }

    private nonisolated static func captureFailureState(for error: Error) -> AppMessage {
        let nsError = error as NSError
        let description = nsError.localizedDescription

        if error is RecordingPermissionError || description.localizedCaseInsensitiveContains("TCC") {
            return .screenRecordingDenied
        }

        if let workspaceError = error as? RecordingWorkspaceError {
            switch workspaceError {
            case let .rootUnavailable(url):
                return .recordingFolderUnavailable(url.path)
            case let .rootNotWritable(url):
                return .recordingFolderNotWritable(url.path)
            case let .sessionCreationFailed(url):
                return .sessionCreationFailed(url.path)
            case let .transcriptCreationFailed(url):
                return .transcriptCreationFailed(url.path)
            }
        }

        if let captureError = error as? RecordingCaptureError {
            switch captureError {
            case .noDisplayFound:
                return .noDisplayFound
            case .recordingOutputFailed:
                return .recordingOutputFailed
            case .audioFormatUnavailable:
                return .audioFormatUnavailable
            case let .audioFileFailed(url):
                return .audioFileFailed(url.path)
            }
        }

        return .captureError(description)
    }

    /// Estimate comfortable reading time for bilingual subtitles.
    ///
    /// - English: ~15 chars/sec (professional subtitle standard)
    /// - Chinese: ~8 chars/sec (each character carries more meaning)
    /// - Bilingual overhead: 1.3x (eye movement between two lines)
    /// - Clamped to 2.5–10 seconds
    nonisolated static func estimateReadingTime(english: String, chinese: String) -> TimeInterval {
        let englishTime = Double(english.count) / 15.0
        let chineseTime = Double(chinese.count) / 8.0
        let baseTime = max(englishTime, chineseTime)
        let bilingualTime = baseTime * 1.3
        return min(max(bilingualTime, 2.5), 10.0)
    }
}
