import AVFoundation
import ScreenCaptureKit

final class RecordingCaptureService: NSObject, @unchecked Sendable {
    private let mode: RecordingMode
    private let outputURL: URL
    private let audioQueue = DispatchQueue(label: "CapiX.RecordingCaptureService.audio")
    private var stream: SCStream?
    private var recordingOutput: SCRecordingOutput?
    private var audioFile: AVAudioFile?
    private var audioFormat: AVAudioFormat?
    private var continuation: AsyncStream<[Float]>.Continuation?
    private var _audioStream: AsyncStream<[Float]>?

    init(mode: RecordingMode, outputURL: URL) {
        self.mode = mode
        self.outputURL = outputURL
        super.init()
    }

    /// Must be called before `start()` so the stream has a continuation to
    /// feed the transcription pipeline.
    func makeAudioStream() -> AsyncStream<[Float]> {
        let stream = AsyncStream<[Float]> { continuation in
            self.continuation = continuation
        }
        _audioStream = stream
        return stream
    }

    func start() async throws {
        let content = try await SCShareableContent.current
        guard let display = content.displays.first else {
            throw RecordingCaptureError.noDisplayFound
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        configuration.channelCount = 1
        configuration.sampleRate = 16_000
        configuration.width = max(display.width, 2)
        configuration.height = max(display.height, 2)

        let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: audioQueue)

        if mode == .screenAndAudio {
            let recordingConfiguration = SCRecordingOutputConfiguration()
            recordingConfiguration.outputURL = outputURL
            recordingConfiguration.outputFileType = .mp4

            let recordingOutput = SCRecordingOutput(
                configuration: recordingConfiguration,
                delegate: self
            )

            try stream.addRecordingOutput(recordingOutput)
            self.recordingOutput = recordingOutput
        } else {
            let format = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 16_000,
                channels: 1,
                interleaved: false
            )
            guard let format else {
                throw RecordingCaptureError.audioFormatUnavailable
            }
            self.audioFormat = format
            do {
                self.audioFile = try AVAudioFile(
                    forWriting: outputURL,
                    settings: format.settings,
                    commonFormat: format.commonFormat,
                    interleaved: format.isInterleaved
                )
            } catch {
                throw RecordingCaptureError.audioFileFailed(outputURL)
            }
        }

        try await stream.startCapture()
        self.stream = stream
    }

    func stop() async {
        try? await stream?.stopCapture()
        stream = nil
        recordingOutput = nil
        audioFile = nil
        audioFormat = nil
        continuation?.finish()
        continuation = nil
    }
}

extension RecordingCaptureService: SCStreamOutput {
    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .audio else { return }
        guard let blockBuffer = sampleBuffer.dataBuffer else { return }

        let length = CMBlockBufferGetDataLength(blockBuffer)
        guard length > 0 else { return }

        var data = Data(count: length)
        data.withUnsafeMutableBytes { rawBuffer in
            guard let destination = rawBuffer.baseAddress else { return }
            CMBlockBufferCopyDataBytes(
                blockBuffer,
                atOffset: 0,
                dataLength: length,
                destination: destination
            )
        }

        let floatCount = length / MemoryLayout<Float>.size
        let floats = data.withUnsafeBytes { rawBuffer in
            Array(rawBuffer.bindMemory(to: Float.self).prefix(floatCount))
        }

        guard !floats.isEmpty else { return }

        continuation?.yield(floats)

        guard mode == .audioOnly, let audioFile, let audioFormat else { return }
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: AVAudioFrameCount(floats.count)
        ) else { return }

        buffer.frameLength = AVAudioFrameCount(floats.count)
        floats.withUnsafeBufferPointer { source in
            guard let sourceBase = source.baseAddress,
                  let destination = buffer.floatChannelData?[0] else { return }
            destination.initialize(from: sourceBase, count: floats.count)
        }

        try? audioFile.write(from: buffer)
    }
}

extension RecordingCaptureService: SCRecordingOutputDelegate {
    func recordingOutputDidStartRecording(_ recordingOutput: SCRecordingOutput) {
        AppLogger.log("Recording output started")
    }

    func recordingOutput(_ recordingOutput: SCRecordingOutput, didFailWithError error: Error) {
        AppLogger.log("Recording output failed: \(error.localizedDescription)")
    }

    func recordingOutputDidFinishRecording(_ recordingOutput: SCRecordingOutput) {
        AppLogger.log("Recording output finished")
    }
}

enum RecordingCaptureError: LocalizedError {
    case noDisplayFound
    case recordingOutputFailed
    case audioFormatUnavailable
    case audioFileFailed(URL)

    var errorDescription: String? {
        switch self {
        case .noDisplayFound:
            return "No display found for screen capture"
        case .recordingOutputFailed:
            return "Could not start screen recording"
        case .audioFormatUnavailable:
            return "Audio format is unavailable"
        case let .audioFileFailed(url):
            return "Could not create audio recording file: \(url.path)"
        }
    }

    func localizedDescription(language: AppLanguage) -> String {
        switch self {
        case .noDisplayFound:
            return AppText.noDisplayFound(language)
        case .recordingOutputFailed:
            return AppText.couldNotStartScreenRecording(language)
        case .audioFormatUnavailable:
            return AppText.audioFormatUnavailable(language)
        case let .audioFileFailed(url):
            return AppText.couldNotCreateAudioRecordingFile(url.path, language: language)
        }
    }
}
