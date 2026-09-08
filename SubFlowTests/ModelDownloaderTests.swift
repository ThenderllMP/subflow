import Testing
import Foundation
@testable import MeetingFlow

@Suite("ModelDownloader")
struct ModelDownloaderTests {

    // MARK: - isModelInstalled

    @Test("reports installed when all required files exist and are non-empty")
    func installedWhenAllFilesPresent() throws {
        let tempRoot = try makeTempRoot()
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let modelDir = tempRoot.appendingPathComponent("small-streaming-en")
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)
        for name in ModelDownloader.requiredFiles {
            try "dummy".data(using: .utf8)!
                .write(to: modelDir.appendingPathComponent(name))
        }

        #expect(ModelDownloader.isModelInstalled("small-streaming-en", inside: tempRoot))
    }

    @Test("reports not installed when directory is missing")
    func notInstalledWhenDirMissing() throws {
        let tempRoot = try makeTempRoot()
        defer { try? FileManager.default.removeItem(at: tempRoot) }
        #expect(!ModelDownloader.isModelInstalled("small-streaming-en", inside: tempRoot))
    }

    @Test("reports not installed when a required file is missing")
    func notInstalledWhenAFileMissing() throws {
        let tempRoot = try makeTempRoot()
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let modelDir = tempRoot.appendingPathComponent("small-streaming-en")
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)
        // Create all but the last required file.
        for name in ModelDownloader.requiredFiles.dropLast() {
            try "dummy".data(using: .utf8)!
                .write(to: modelDir.appendingPathComponent(name))
        }

        #expect(!ModelDownloader.isModelInstalled("small-streaming-en", inside: tempRoot))
    }

    @Test("reports not installed when a required file is zero bytes")
    func notInstalledWhenFileEmpty() throws {
        let tempRoot = try makeTempRoot()
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let modelDir = tempRoot.appendingPathComponent("small-streaming-en")
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)
        for name in ModelDownloader.requiredFiles {
            let file = modelDir.appendingPathComponent(name)
            if name == "encoder.ort" {
                // Simulate aborted download: file exists but is empty.
                FileManager.default.createFile(atPath: file.path, contents: nil)
            } else {
                try "dummy".data(using: .utf8)!.write(to: file)
            }
        }

        #expect(!ModelDownloader.isModelInstalled("small-streaming-en", inside: tempRoot))
    }

    // MARK: - ModelSource

    @Test("knows the two official model IDs")
    func sourceKnownIds() {
        #expect(ModelSource.source(for: "small-streaming-en") != nil)
        #expect(ModelSource.source(for: "medium-streaming-en") != nil)
    }

    @Test("returns nil for unknown model IDs")
    func sourceUnknownId() {
        #expect(ModelSource.source(for: "nonexistent-model") == nil)
        #expect(ModelSource.source(for: "") == nil)
    }

    @Test("source URLs are HTTPS on the official Moonshine CDN")
    func sourceURLsOnMoonshineCDN() {
        let small = ModelSource.source(for: "small-streaming-en")!
        let medium = ModelSource.source(for: "medium-streaming-en")!
        for source in [small, medium] {
            #expect(source.baseURL.scheme == "https")
            #expect(source.baseURL.host == "download.moonshine.ai")
        }
        #expect(small.baseURL.path.contains("small-streaming-en"))
        #expect(medium.baseURL.path.contains("medium-streaming-en"))
    }

    @Test("falls back to GET when HEAD omits Content-Length")
    func discoverSizesFallsBackToGet() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockMoonshineURLProtocol.self]

        MockMoonshineURLProtocol.handler = { request in
            let file = request.url!.lastPathComponent
            let method = request.httpMethod ?? "GET"

            if file == "streaming_config.json" && method == "HEAD" {
                return MockMoonshineURLProtocol.Response(
                    statusCode: 200,
                    headers: [:],
                    body: Data()
                )
            }

            if file == "streaming_config.json" && method == "GET" {
                return MockMoonshineURLProtocol.Response(
                    statusCode: 200,
                    headers: [:],
                    body: Data(#"{"streaming":true}"#.utf8)
                )
            }

            return MockMoonshineURLProtocol.Response(
                statusCode: 200,
                headers: ["Content-Length": "100"],
                body: Data()
            )
        }
        defer { MockMoonshineURLProtocol.handler = nil }

        let source = ModelSource(baseURL: URL(string: "https://download.moonshine.ai/model/small-streaming-en/quantized")!)
        let sizes = try await ModelDownloader.discoverSizes(source: source, config: config)
        let configIndex = ModelDownloader.requiredFiles.firstIndex(of: "streaming_config.json")!

        #expect(sizes.count == ModelDownloader.requiredFiles.count)
        #expect(sizes[configIndex] == Int64(#"{"streaming":true}"#.utf8.count))
    }

    // MARK: - ensureModel fast path

    @Test("ensureModel throws noSource for unknown IDs")
    func ensureModelUnknownId() async {
        await #expect(throws: ModelDownloadError.self) {
            _ = try await ModelDownloader.ensureModel("not-a-real-model")
        }
    }

    // MARK: - Helpers

    private func makeTempRoot() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("meetingflow-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private final class MockMoonshineURLProtocol: URLProtocol {
    struct Response {
        let statusCode: Int
        let headers: [String: String]
        let body: Data
    }

    nonisolated(unsafe) static var handler: ((URLRequest) -> Response)?

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "download.moonshine.ai"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let responseSpec = handler(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: responseSpec.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: responseSpec.headers
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if !responseSpec.body.isEmpty {
            client?.urlProtocol(self, didLoad: responseSpec.body)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
