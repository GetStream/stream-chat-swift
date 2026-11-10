//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import ImageIO
import SwiftUI

// An image the agent linked to, loaded through the shared loader.
@available(iOS 15.0, macOS 12.0, *)
struct A2UIRemoteImage<Content: View, Placeholder: View>: View {
    let url: URL
    @ViewBuilder let content: (Image) -> Content
    // Shown while the image loads, and given `true` when it can't.
    @ViewBuilder let placeholder: (_ failed: Bool) -> Placeholder

    @State private var loaded: CGImage?
    @State private var loadedURL: URL?
    @State private var failed = false

    var body: some View {
        Group {
            if let image = loadedURL == url ? loaded : A2UIImageLoader.shared.cachedImage(for: url) {
                content(Image(decorative: image, scale: 1))
            } else {
                placeholder(failed && loadedURL == url)
            }
        }
        .task(id: url) {
            guard loadedURL != url || loaded == nil else { return }
            let image = await A2UIImageLoader.shared.image(for: url)
            guard !Task.isCancelled else { return }
            loaded = image
            loadedURL = url
            failed = image == nil
        }
    }
}

// Loads the images a reply links to: one download per URL, which stops once it would pass
// `maxBytes`, decoded off the main thread at no more than `maxPixelSize`, and kept in a cache
// that lets go of images under memory pressure.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class A2UIImageLoader {
    typealias Fetch = @Sendable (_ url: URL, _ maxBytes: Int) async throws -> Data

    static let shared = A2UIImageLoader()

    let maxPixelSize: Int
    let maxBytes: Int
    private let fetch: Fetch
    private let cache = NSCache<NSURL, CGImage>()
    private var loads: [URL: Task<CGImage?, Never>] = [:]

    init(
        maxPixelSize: Int = 1200,
        maxBytes: Int = 20_000_000,
        costLimit: Int = 64 * 1024 * 1024,
        fetch: @escaping Fetch = { try await A2UIImageLoader.download($0, maxBytes: $1) }
    ) {
        self.maxPixelSize = maxPixelSize
        self.maxBytes = maxBytes
        self.fetch = fetch
        cache.totalCostLimit = costLimit
    }

    func cachedImage(for url: URL) -> CGImage? {
        cache.object(forKey: url as NSURL)
    }

    func image(for url: URL) async -> CGImage? {
        if let image = cachedImage(for: url) { return image }
        if let load = loads[url] { return await load.value }
        let fetch = self.fetch
        let maxPixelSize = self.maxPixelSize
        let maxBytes = self.maxBytes
        let load = Task.detached(priority: .utility) { () -> CGImage? in
            guard let data = try? await fetch(url, maxBytes), data.count <= maxBytes else { return nil }
            return Self.downsample(data, maxPixelSize: maxPixelSize)
        }
        loads[url] = load
        let image = await load.value
        loads[url] = nil
        if let image {
            cache.setObject(image, forKey: url as NSURL, cost: image.bytesPerRow * image.height)
        }
        return image
    }

    nonisolated static func downsample(_ data: Data, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    // The agent links to the image, so its server could send any amount: the download stops as
    // soon as it would pass `maxBytes`, or before it starts when the server says it would.
    nonisolated static func download(_ url: URL, maxBytes: Int, session: URLSession = .shared) async throws -> Data {
        let (bytes, response) = try await session.bytes(from: url)
        if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
            throw URLError(.badServerResponse)
        }
        guard response.expectedContentLength <= Int64(maxBytes) else {
            throw URLError(.dataLengthExceedsMaximum)
        }
        var data = Data()
        if response.expectedContentLength > 0 {
            data.reserveCapacity(Int(response.expectedContentLength))
        }
        for try await byte in bytes {
            guard data.count < maxBytes else {
                throw URLError(.dataLengthExceedsMaximum)
            }
            data.append(byte)
        }
        return data
    }
}
