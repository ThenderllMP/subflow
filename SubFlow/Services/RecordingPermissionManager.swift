import CoreGraphics
import Foundation

enum RecordingPermissionManager {
    static func ensureScreenRecordingAccess() throws {
        if CGPreflightScreenCaptureAccess() {
            return
        }

        _ = CGRequestScreenCaptureAccess()

        guard CGPreflightScreenCaptureAccess() else {
            throw RecordingPermissionError.screenRecordingDenied
        }
    }
}

enum RecordingPermissionError: LocalizedError {
    case screenRecordingDenied

    var errorDescription: String? {
        switch self {
        case .screenRecordingDenied:
            return "Screen recording permission is still not active. Open System Settings > Privacy & Security > Screen Recording, enable MeetingFlow, then quit and reopen the app."
        }
    }

    func localizedDescription(language: AppLanguage) -> String {
        AppText.screenRecordingPermissionDenied(language)
    }
}
