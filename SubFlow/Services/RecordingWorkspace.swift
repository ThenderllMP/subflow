import Foundation

struct RecordingSessionPaths: Sendable {
    let rootURL: URL
    let sessionURL: URL
    let mediaURL: URL
    let transcriptURL: URL
}

enum RecordingWorkspaceError: LocalizedError {
    case rootUnavailable(URL)
    case rootNotWritable(URL)
    case sessionCreationFailed(URL)
    case transcriptCreationFailed(URL)

    var errorDescription: String? {
        switch self {
        case let .rootUnavailable(url):
            return "Recording folder is unavailable: \(url.path)"
        case let .rootNotWritable(url):
            return "Recording folder is not writable: \(url.path)"
        case let .sessionCreationFailed(url):
            return "Could not create recording session folder: \(url.path)"
        case let .transcriptCreationFailed(url):
            return "Could not create transcript document: \(url.path)"
        }
    }

    func localizedDescription(language: AppLanguage) -> String {
        switch self {
        case let .rootUnavailable(url):
            return AppText.recordingFolderUnavailable(url.path, language: language)
        case let .rootNotWritable(url):
            return AppText.recordingFolderNotWritable(url.path, language: language)
        case let .sessionCreationFailed(url):
            return AppText.couldNotCreateRecordingSessionFolder(url.path, language: language)
        case let .transcriptCreationFailed(url):
            return AppText.couldNotCreateTranscriptDocument(url.path, language: language)
        }
    }
}

enum RecordingWorkspace {
    static let defaultRootURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Movies", isDirectory: true)
            .appendingPathComponent("SubFlow Recordings", isDirectory: true)
    }()

    static func validateRoot(path: String) throws -> URL {
        let rootURL = URL(fileURLWithPath: path).standardizedFileURL
        var isDirectory: ObjCBool = false
        let fileExists = FileManager.default.fileExists(atPath: rootURL.path, isDirectory: &isDirectory)

        if fileExists {
            guard isDirectory.boolValue else { throw RecordingWorkspaceError.rootUnavailable(rootURL) }
        } else {
            do {
                try FileManager.default.createDirectory(
                    at: rootURL,
                    withIntermediateDirectories: true
                )
            } catch {
                throw RecordingWorkspaceError.rootUnavailable(rootURL)
            }
        }

        guard FileManager.default.isWritableFile(atPath: rootURL.path) else {
            throw RecordingWorkspaceError.rootNotWritable(rootURL)
        }

        let probeURL = rootURL.appendingPathComponent(
            ".subflow-write-check-\(UUID().uuidString)",
            isDirectory: false
        )
        do {
            try Data().write(to: probeURL, options: .atomic)
            try FileManager.default.removeItem(at: probeURL)
        } catch {
            throw RecordingWorkspaceError.rootNotWritable(rootURL)
        }

        return rootURL
    }

    static func prepareSession(
        rootPath: String,
        mode: RecordingMode,
        now: Date = .now
    ) throws -> RecordingSessionPaths {
        let rootURL = try validateRoot(path: rootPath)
        let sessionURL = rootURL.appendingPathComponent(sessionFolderName(mode: mode, now: now), isDirectory: true)

        do {
            try FileManager.default.createDirectory(
                at: sessionURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw RecordingWorkspaceError.sessionCreationFailed(sessionURL)
        }

        let mediaURL = sessionURL.appendingPathComponent("recording.\(mode.fileExtension)")
        let transcriptURL = sessionURL.appendingPathComponent("transcript.txt")
        return RecordingSessionPaths(
            rootURL: rootURL,
            sessionURL: sessionURL,
            mediaURL: mediaURL,
            transcriptURL: transcriptURL
        )
    }

    static func transcriptDocumentExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    private static func sessionFolderName(mode: RecordingMode, now: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: now)
        let suffix = UUID().uuidString.prefix(8).uppercased()
        return "recording-\(timestamp)-\(mode.fileNameComponent)-\(suffix)"
    }
}

final class TranscriptDocumentWriter {
    private let fileURL: URL
    private let handle: FileHandle
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    init(sessionURL: URL, transcriptURL: URL, mode: RecordingMode, startedAt: Date = .now) throws {
        self.fileURL = transcriptURL

        let initialText = """
        SubFlow Meeting Transcript
        Session Folder: \(sessionURL.lastPathComponent)
        Mode: \(mode.displayName)
        Started: \(formatter.string(from: startedAt))

        """

        do {
            guard let data = initialText.data(using: .utf8) else {
                throw RecordingWorkspaceError.transcriptCreationFailed(transcriptURL)
            }
            try data.write(to: transcriptURL, options: .atomic)
        } catch {
            throw RecordingWorkspaceError.transcriptCreationFailed(transcriptURL)
        }

        do {
            self.handle = try FileHandle(forWritingTo: transcriptURL)
            self.handle.seekToEndOfFile()
        } catch {
            throw RecordingWorkspaceError.transcriptCreationFailed(transcriptURL)
        }
    }

    func append(entry: CaptionEntry) throws {
        let block = """
        [\(formatter.string(from: entry.timestamp))]
        Original: \(normalized(entry.englishText))
        Translation: \(normalized(entry.chineseText))

        """

        guard let data = block.data(using: .utf8) else {
            throw RecordingWorkspaceError.transcriptCreationFailed(fileURL)
        }
        handle.seekToEndOfFile()
        handle.write(data)
    }

    func finish() {
        handle.closeFile()
    }

    private func normalized(_ text: String) -> String {
        text.isEmpty ? "(unavailable)" : text
    }
}
