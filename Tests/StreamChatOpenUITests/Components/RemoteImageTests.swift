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
        RemoteImageLoader(maxPixelSize: maxPixelSize, costLimit: costLimit) { url in
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

    @Test func failedLoadsAreNotCached() async throws {
        let log = FetchLog()
        let loader = Self.loader(data: Data("not an image".utf8), log: log)
        let url = try #require(URL(string: "https://example.com/broken.png"))

        #expect(await loader.image(for: url) == nil)
        #expect(await loader.image(for: url) == nil)
        #expect(loader.cachedImage(for: url) == nil)
        #expect(log.count == 2)
    }

    @Test func tooLargeDownloadsAreRejected() async throws {
        let data = try Self.png(width: 100, height: 100)
        let loader = RemoteImageLoader(maxBytes: data.count - 1) { _ in data }
        let url = try #require(URL(string: "https://example.com/a.png"))

        #expect(await loader.image(for: url) == nil)
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
