//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
@testable import StreamChat
@testable import StreamChatCommonUI
import XCTest

@available(iOS 14.0, *)
final class StreamAVPlayerLoader_Tests: XCTestCase {
    private var root: URL!
    private var cacheDirectory: URL!
    private var tempDirectory: URL!
    private let fileManager = FileManager.default

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = fileManager.temporaryDirectory
            .appendingPathComponent("StreamAVPlayerLoader_Tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        cacheDirectory = root.appendingPathComponent("cache", isDirectory: true)
        tempDirectory = root.appendingPathComponent("temps", isDirectory: true)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: root)
        root = nil
        cacheDirectory = nil
        tempDirectory = nil
        try super.tearDownWithError()
    }

    @MainActor
    func test_load_whenCacheDisabled_streamsRemoteAndSkipsFileRequest() async throws {
        let url = URL(string: "https://example.com/video.mp4")!
        let mediaLoader = MediaLoaderSpy(videoAssetResult: .success(MediaLoaderVideoAsset(asset: AVURLAsset(url: url))))
        let player = AVPlayer()
        let provider = AVPlayerProviderSpy(result: .success(player))
        let loader = makeLoader(url: url, mediaLoader: mediaLoader, avPlayerProvider: provider, policy: nil)

        let result = try await load(loader)

        XCTAssertTrue(result === player)
        XCTAssertEqual(mediaLoader.loadedVideoAssetURLs, [url])
        XCTAssertEqual(mediaLoader.loadedFileRequestURLs, [])
        XCTAssertEqual(provider.receivedAssets.count, 1)
    }

    @MainActor
    func test_load_whenURLIsNotCacheable_streamsRemoteAndSkipsFileRequest() async throws {
        let urls = [
            URL(fileURLWithPath: "/tmp/local-upload.mov"),
            URL(string: "https://example.com/video.m3u8")!
        ]

        for url in urls {
            let mediaLoader = MediaLoaderSpy(videoAssetResult: .success(MediaLoaderVideoAsset(asset: AVURLAsset(url: url))))
            let provider = AVPlayerProviderSpy(result: .success(AVPlayer()))
            let loader = makeLoader(url: url, mediaLoader: mediaLoader, avPlayerProvider: provider)

            _ = try await load(loader)

            XCTAssertEqual(mediaLoader.loadedVideoAssetURLs, [url])
            XCTAssertEqual(mediaLoader.loadedFileRequestURLs, [])
            XCTAssertEqual(provider.receivedAssets.count, 1)
        }
    }

    @MainActor
    func test_load_whenCachedFileIsPlayable_playsLocalFileAndSkipsRemoteLoading() async throws {
        let url = URL(string: "https://example.com/video.mp4")!
        let cache = makeCache()
        let localURL = try await storeCachedFile(in: cache, for: url)
        let mediaLoader = MediaLoaderSpy()
        let provider = AVPlayerProviderSpy(result: .success(AVPlayer()))
        let loader = makeLoader(
            url: url,
            mediaLoader: mediaLoader,
            avPlayerProvider: provider,
            cache: cache
        )

        _ = try await load(loader)

        XCTAssertEqual(mediaLoader.loadedVideoAssetURLs, [])
        XCTAssertEqual(mediaLoader.loadedFileRequestURLs, [])
        XCTAssertEqual(provider.receivedAssets.count, 1)
        XCTAssertEqual((provider.receivedAssets.first?.asset as? AVURLAsset)?.url, localURL)
    }

    @MainActor
    func test_load_whenCacheMiss_streamsThroughCachingAssetAndSkipsRemoteVideoAsset() async throws {
        let url = URL(string: "https://example.com/video.mp4")!
        let mediaLoader = MediaLoaderSpy(
            videoAssetResult: .success(MediaLoaderVideoAsset(asset: AVURLAsset(url: url))),
            fileRequestResult: .success(MediaLoaderFileRequest(urlRequest: URLRequest(url: url)))
        )
        let provider = AVPlayerProviderSpy(result: .success(AVPlayer()))
        let loader = makeLoader(url: url, mediaLoader: mediaLoader, avPlayerProvider: provider)

        _ = try await load(loader)

        XCTAssertEqual(mediaLoader.loadedVideoAssetURLs, [])
        XCTAssertEqual(mediaLoader.loadedFileRequestURLs, [url])
        XCTAssertEqual(provider.receivedAssets.count, 1)
        XCTAssertEqual((provider.receivedAssets.first?.asset as? AVURLAsset)?.url.scheme, StreamVideoAsset.scheme)
    }

    @MainActor
    func test_load_whenFileRequestFails_streamsRemoteWithoutCaching() async throws {
        let url = URL(string: "https://example.com/video.mp4")!
        let mediaLoader = MediaLoaderSpy(
            videoAssetResult: .success(MediaLoaderVideoAsset(asset: AVURLAsset(url: url))),
            fileRequestResult: .failure(LoaderTestError())
        )
        let provider = AVPlayerProviderSpy(result: .success(AVPlayer()))
        let loader = makeLoader(url: url, mediaLoader: mediaLoader, avPlayerProvider: provider)

        _ = try await load(loader)

        XCTAssertEqual(mediaLoader.loadedVideoAssetURLs, [url])
        XCTAssertEqual(mediaLoader.loadedFileRequestURLs, [url])
        XCTAssertEqual(provider.receivedAssets.count, 1)
        XCTAssertEqual((provider.receivedAssets.first?.asset as? AVURLAsset)?.url, url)
    }

    @MainActor
    func test_load_whenCachingAssetPlayerProviderFails_doesNotRetryRemotePlayback() async throws {
        let url = URL(string: "https://example.com/video.mp4")!
        let expectedError = LoaderTestError()
        let mediaLoader = MediaLoaderSpy(
            videoAssetResult: .success(MediaLoaderVideoAsset(asset: AVURLAsset(url: url))),
            fileRequestResult: .success(MediaLoaderFileRequest(urlRequest: URLRequest(url: url)))
        )
        let provider = AVPlayerProviderSpy(result: .failure(expectedError))
        let loader = makeLoader(url: url, mediaLoader: mediaLoader, avPlayerProvider: provider)

        do {
            _ = try await load(loader)
            XCTFail("Expected player provider to fail")
        } catch {
            XCTAssertTrue(error is LoaderTestError)
        }
        XCTAssertEqual(mediaLoader.loadedVideoAssetURLs, [])
        XCTAssertEqual(mediaLoader.loadedFileRequestURLs, [url])
        XCTAssertEqual(provider.receivedAssets.count, 1)
        XCTAssertEqual((provider.receivedAssets.first?.asset as? AVURLAsset)?.url.scheme, StreamVideoAsset.scheme)
    }

    @MainActor
    func test_load_whenCachedFileIsNotPlayable_evictsCacheAndStreamsThroughCachingAsset() async throws {
        let url = URL(string: "https://example.com/video.mp4")!
        let cache = makeCache()
        _ = try await storeCachedFile(in: cache, for: url)
        let storedURL = await cache.completedFileURL(forKey: url.path, fileExtension: "mp4")
        XCTAssertNotNil(storedURL)
        let mediaLoader = MediaLoaderSpy(
            videoAssetResult: .success(MediaLoaderVideoAsset(asset: AVURLAsset(url: url))),
            fileRequestResult: .success(MediaLoaderFileRequest(urlRequest: URLRequest(url: url)))
        )
        let provider = AVPlayerProviderSpy(result: .success(AVPlayer()))
        let loader = makeLoader(
            url: url,
            mediaLoader: mediaLoader,
            avPlayerProvider: provider,
            cache: cache,
            isPlayable: false
        )

        _ = try await load(loader)

        let evictedURL = await cache.completedFileURL(forKey: url.path, fileExtension: "mp4")
        XCTAssertNil(evictedURL)
        XCTAssertEqual(mediaLoader.loadedVideoAssetURLs, [])
        XCTAssertEqual(mediaLoader.loadedFileRequestURLs, [url])
        XCTAssertEqual(provider.receivedAssets.count, 1)
        XCTAssertEqual((provider.receivedAssets.first?.asset as? AVURLAsset)?.url.scheme, StreamVideoAsset.scheme)
    }

    @MainActor
    func test_load_whenPlayerProviderFails_completesWithError() async throws {
        let url = URL(string: "https://example.com/video.mp4")!
        let expectedError = LoaderTestError()
        let mediaLoader = MediaLoaderSpy(videoAssetResult: .success(MediaLoaderVideoAsset(asset: AVURLAsset(url: url))))
        let provider = AVPlayerProviderSpy(result: .failure(expectedError))
        let loader = makeLoader(url: url, mediaLoader: mediaLoader, avPlayerProvider: provider, policy: nil)

        do {
            _ = try await load(loader)
            XCTFail("Expected player provider to fail")
        } catch {
            XCTAssertTrue(error is LoaderTestError)
        }
        XCTAssertEqual(provider.receivedAssets.count, 1)
    }

    @MainActor
    private func makeLoader(
        url: URL,
        mediaLoader: MediaLoaderSpy = MediaLoaderSpy(),
        avPlayerProvider: AVPlayerProviderSpy = AVPlayerProviderSpy(),
        cache: StreamVideoCache? = nil,
        policy: VideoAttachmentCachingPolicy? = VideoAttachmentCachingPolicy(maxCacheSize: 1_000_000),
        isPlayable: Bool = true
    ) -> StreamAVPlayerLoader {
        let loader = MockStreamAVPlayerLoader(
            url: url,
            mediaLoader: mediaLoader,
            avPlayerProvider: avPlayerProvider,
            cache: cache ?? makeCache(),
            policy: policy
        )
        loader.mockIsPlayable = isPlayable
        return loader
    }

    @MainActor private func load(_ loader: StreamAVPlayerLoader) async throws -> AVPlayer {
        try await loader.load()
    }

    private func makeCache() -> StreamVideoCache {
        StreamVideoCache(directory: cacheDirectory, maxSizeInBytes: 1_000_000)
    }

    private func storeCachedFile(in cache: StreamVideoCache, for url: URL) async throws -> URL {
        let storedURL = await cache.storeCompletedFile(
            at: try makeTempFile(byteCount: 100),
            forKey: url.path,
            fileExtension: "mp4"
        )
        return try XCTUnwrap(storedURL)
    }

    private func makeTempFile(byteCount: Int) throws -> URL {
        let url = tempDirectory.appendingPathComponent(UUID().uuidString)
        try Data(repeating: 0xab, count: byteCount).write(to: url)
        return url
    }
}

@available(iOS 14.0, *)
private final class MockStreamAVPlayerLoader: StreamAVPlayerLoader {
    var mockIsPlayable = true

    override func isPlayable(_ url: URL) async -> Bool {
        mockIsPlayable
    }
}

private final class MediaLoaderSpy: MediaLoader, @unchecked Sendable {
    var loadedVideoAssetURLs: [URL] = []
    var loadedFileRequestURLs: [URL] = []
    private let videoAssetResult: Result<MediaLoaderVideoAsset, Error>
    private let fileRequestResult: Result<MediaLoaderFileRequest, Error>

    init(
        videoAssetResult: Result<MediaLoaderVideoAsset, Error> = .success(MediaLoaderVideoAsset(asset: AVURLAsset(url: URL(string: "https://example.com/default.mp4")!))),
        fileRequestResult: Result<MediaLoaderFileRequest, Error> = .failure(LoaderTestError())
    ) {
        self.videoAssetResult = videoAssetResult
        self.fileRequestResult = fileRequestResult
    }

    func loadImage(
        url: URL?,
        options: ImageLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderImage, Error>) -> Void
    ) {
        Task { @MainActor in completion(.failure(LoaderTestError())) }
    }

    func loadVideoAsset(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoAsset, Error>) -> Void
    ) {
        loadedVideoAssetURLs.append(url)
        let videoAssetResult = self.videoAssetResult
        Task { @MainActor in completion(videoAssetResult) }
    }

    func loadVideoPreview(
        with attachment: ChatMessageVideoAttachment,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        Task { @MainActor in completion(.failure(LoaderTestError())) }
    }

    func loadVideoPreview(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        Task { @MainActor in completion(.failure(LoaderTestError())) }
    }

    func loadFileRequest(
        for url: URL,
        options: DownloadFileRequestOptions,
        completion: @escaping @MainActor (Result<MediaLoaderFileRequest, Error>) -> Void
    ) {
        loadedFileRequestURLs.append(url)
        let fileRequestResult = self.fileRequestResult
        Task { @MainActor in completion(fileRequestResult) }
    }
}

private final class AVPlayerProviderSpy: AVPlayerProvider {
    var receivedAssets: [MediaLoaderVideoAsset] = []
    private let result: Result<AVPlayer, Error>

    init(result: Result<AVPlayer, Error> = .success(AVPlayer())) {
        self.result = result
    }

    func player(
        from videoAsset: MediaLoaderVideoAsset,
        completion: @escaping (Result<AVPlayer, Error>) -> Void
    ) {
        receivedAssets.append(videoAsset)
        completion(result)
    }
}

private struct LoaderTestError: Error {}
