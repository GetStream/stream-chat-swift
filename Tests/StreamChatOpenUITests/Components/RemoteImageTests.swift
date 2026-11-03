//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import Foundation
import ImageIO
import os
@testable import StreamChatOpenUI
import Testing
import UniformTypeIdentifiers

// Serves the same body for every image, saying its length only for the path `/declared`.
private final class StubImageProtocol: URLProtocol {
    static let body = Data(repeating: 7, count: 1000)

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        var headers = ["Content-Type": "image/png"]
        if request.url?.path == "/declared" {
            headers["Content-Length"] = "\(Self.body.count)"
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
}

@MainActor
@Suite("Remote images")
struct RemoteImageTests {
    final class FetchLog: Sendable {
        private let urls = OSAllocatedUnfairLock<[URL]>(initialState: [])

        var count: Int { urls.withLock { $0.count } }

        func record(_ url: URL) {
            urls.withLock { $0.append(url) }
        }
    }

    // How many fetches run at once, and the most that ever did.
    final class InFlight: Sendable {
        private let counts = OSAllocatedUnfairLock(initialState: (current: 0, most: 0))

        var most: Int { counts.withLock { $0.most } }

        func start() {
            counts.withLock { state in
                state.current += 1
                state.most = max(state.most, state.current)
            }
        }

        func end() {
            counts.withLock { $0.current -= 1 }
        }
    }

    // Holds fetches until the test opens it.
    final class Gate: Sendable {
        private let state = OSAllocatedUnfairLock(initialState: (isOpen: false, waiting: [CheckedContinuation<Void, Never>]()))

        func pass() async {
            await withCheckedContinuation { continuation in
                let isOpen = state.withLock { state in
                    if !state.isOpen { state.waiting.append(continuation) }
                    return state.isOpen
                }
                if isOpen { continuation.resume() }
            }
        }

        func open() {
            let waiting = state.withLock { state in
                state.isOpen = true
                let waiting = state.waiting
                state.waiting = []
                return waiting
            }
            for continuation in waiting {
                continuation.resume()
            }
        }
    }

    static func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<500 where !condition() {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    static func png(width: Int, height: Int) throws -> Data {
        let context = try #require(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }

    static func loader(data: Data, log: FetchLog, maxPixelSize: Int = 400, costLimit: Int = 64 * 1024 * 1024, delay: UInt64 = 0) -> RemoteImageLoader {
        RemoteImageLoader(maxPixelSize: maxPixelSize, costLimit: costLimit) { url, _ in
            log.record(url)
            if delay > 0 { try await Task.sleep(nanoseconds: delay) }
            return data
        }
    }

    @Test func largeImagesAreDownsampled() async throws {
        let loader = Self.loader(data: try Self.png(width: 3000, height: 1500), log: FetchLog())
        let url = try #require(URL(string: "https://example.com/large.png"))
        let image = try #require(await loader.image(for: url))

        #expect(max(image.width, image.height) == 400)
        #expect(image.width == 2 * image.height)
    }

    @Test func smallImagesKeepTheirSize() async throws {
        let loader = Self.loader(data: try Self.png(width: 120, height: 80), log: FetchLog())
        let url = try #require(URL(string: "https://example.com/small.png"))
        let image = try #require(await loader.image(for: url))

        #expect(image.width == 120)
        #expect(image.height == 80)
    }

    @Test func imagesAreDownloadedOnce() async throws {
        let log = FetchLog()
        let loader = Self.loader(data: try Self.png(width: 100, height: 100), log: log, delay: 50_000_000)
        let url = try #require(URL(string: "https://example.com/a.png"))

        async let first = loader.image(for: url)
        async let second = loader.image(for: url)
        let images = await [first, second]
        let third = await loader.image(for: url)

        #expect(images.allSatisfy { $0 != nil })
        #expect(third != nil)
        #expect(loader.cachedImage(for: url) != nil)
        #expect(log.count == 1)
    }

    @Test func failedLoadsAreNotDownloadedAgainForAWhile() async throws {
        let log = FetchLog()
        let loader = Self.loader(data: Data("not an image".utf8), log: log)
        let url = try #require(URL(string: "https://example.com/broken.png"))

        #expect(await loader.image(for: url) == nil)
        #expect(await loader.image(for: url) == nil)
        #expect(loader.cachedImage(for: url) == nil)
        #expect(loader.hasFailed(url))
        #expect(log.count == 1)
    }

    @Test func failedLoadsAreTriedAgainOnceTheyExpire() async throws {
        let log = FetchLog()
        let loader = RemoteImageLoader(failureLifetime: .zero) { url, _ in
            log.record(url)
            return Data("not an image".utf8)
        }
        let url = try #require(URL(string: "https://example.com/broken.png"))

        #expect(await loader.image(for: url) == nil)
        #expect(await loader.image(for: url) == nil)
        #expect(log.count == 2)
    }

    @Test func onlyAFewImagesDownloadAtOnce() async throws {
        let data = try Self.png(width: 10, height: 10)
        let inFlight = InFlight()
        let loader = RemoteImageLoader(maxDownloads: 2) { _, _ in
            inFlight.start()
            defer { inFlight.end() }
            try await Task.sleep(nanoseconds: 20_000_000)
            return data
        }
        let urls = try (1...8).map { try #require(URL(string: "https://example.com/\($0).png")) }

        let loaded = await withTaskGroup(of: Bool.self) { group in
            for url in urls {
                group.addTask { await loader.image(for: url) != nil }
            }
            var count = 0
            for await image in group where image {
                count += 1
            }
            return count
        }

        #expect(loaded == urls.count)
        #expect(inFlight.most <= 2)
    }

    @Test func downloadsStopWhenNoViewWaits() async throws {
        let data = try Self.png(width: 10, height: 10)
        let log = FetchLog()
        let stopped = FetchLog()
        let loader = RemoteImageLoader { url, _ in
            log.record(url)
            if log.count == 1 {
                do {
                    try await Task.sleep(nanoseconds: 60_000_000_000)
                } catch {
                    stopped.record(url)
                    throw error
                }
            }
            return data
        }
        let url = try #require(URL(string: "https://example.com/slow.png"))

        let waiting = Task { await loader.image(for: url) }
        await Self.waitUntil { log.count == 1 }
        waiting.cancel()

        #expect(await waiting.value == nil)
        await Self.waitUntil { stopped.count == 1 }
        #expect(stopped.count == 1)
        #expect(!loader.hasFailed(url), "a cancelled download is no failure")
        #expect(await loader.image(for: url) != nil)
    }

    @Test func aDownloadContinuesForTheViewsStillWaiting() async throws {
        let data = try Self.png(width: 10, height: 10)
        let log = FetchLog()
        let gate = Gate()
        let loader = RemoteImageLoader { url, _ in
            log.record(url)
            await gate.pass()
            return data
        }
        let url = try #require(URL(string: "https://example.com/shared.png"))

        let leaving = Task { await loader.image(for: url) }
        let staying = Task { await loader.image(for: url) }
        await Self.waitUntil { log.count == 1 }
        leaving.cancel()

        #expect(await leaving.value == nil)
        gate.open()
        #expect(await staying.value != nil)
        #expect(log.count == 1)
    }

    @Test func tooLargeDownloadsAreRejected() async throws {
        let data = try Self.png(width: 100, height: 100)
        let loader = RemoteImageLoader(maxBytes: data.count - 1) { _, _ in data }
        let url = try #require(URL(string: "https://example.com/a.png"))

        #expect(await loader.image(for: url) == nil)
    }

    @Test func downloadsStopAtTheLimitWhetherOrNotTheServerSaysTheLength() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubImageProtocol.self]
        let session = URLSession(configuration: configuration)

        for path in ["declared", "undeclared"] {
            let url = try #require(URL(string: "https://example.com/\(path)"))
            await #expect(throws: URLError.self, "\(path)") {
                try await RemoteImageLoader.download(url, maxBytes: StubImageProtocol.body.count - 1, session: session)
            }
            #expect(try await RemoteImageLoader.download(url, maxBytes: StubImageProtocol.body.count, session: session) == StubImageProtocol.body)
        }
    }

    @Test func leastRecentlyShownImagesAreDroppedFirst() async throws {
        let data = try Self.png(width: 100, height: 100)
        let cost = try #require(RemoteImageLoader.downsample(data, maxPixelSize: 400)).bytesPerRow * 100
        let loader = Self.loader(data: data, log: FetchLog(), costLimit: cost * 2)
        let urls = try (1...3).map { try #require(URL(string: "https://example.com/\($0).png")) }

        _ = await loader.image(for: urls[0])
        _ = await loader.image(for: urls[1])
        _ = loader.cachedImage(for: urls[0])
        _ = await loader.image(for: urls[2])

        #expect(loader.cachedImage(for: urls[0]) != nil)
        #expect(loader.cachedImage(for: urls[1]) == nil)
        #expect(loader.cachedImage(for: urls[2]) != nil)
    }

    @Test func onlyWebURLsAreLoaded() {
        #expect(RemoteImageLoader.url(from: "https://example.com/a.png") != nil)
        #expect(RemoteImageLoader.url(from: "HTTP://example.com/a.png") != nil)
        #expect(RemoteImageLoader.url(from: "file:///etc/hosts") == nil)
        #expect(RemoteImageLoader.url(from: "data:image/png;base64,AAAA") == nil)
        #expect(RemoteImageLoader.url(from: nil) == nil)
    }
}
