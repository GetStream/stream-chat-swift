//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ImageIO
import SwiftUI

// An image the model links to, with a neutral placeholder and a failure state.
@available(iOS 17.0, macOS 14.0, *)
struct RemoteImage: View {
    let url: String?
    var contentMode: ContentMode = .fill
    var alt: String?
    @Environment(\.openUITheme) private var theme
    @Environment(\.openUIMediaURL) private var mediaURL
    @Environment(OpenUIRuntime.self) private var runtime: OpenUIRuntime?
    @State private var loaded: LoadedImage?
    @State private var failedURL: URL?

    private struct LoadedImage {
        let url: URL
        let image: CGImage
    }

    // A web link the model wrote or a tool returned, which the host lets load.
    private var source: URL? {
        guard let url, runtime?.allowsImageLink(url) != false else { return nil }
        return RemoteImageLoader.url(from: url).flatMap(mediaURL)
    }

    var body: some View {
        if let resolved = source {
            let image = loaded?.url == resolved ? loaded?.image : RemoteImageLoader.shared.cachedImage(for: resolved)
            Group {
                if let image {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } else if failedURL == resolved {
                    placeholder(systemImage: "photo")
                } else {
                    placeholder(systemImage: nil)
                }
            }
            .task(id: resolved) {
                guard RemoteImageLoader.shared.cachedImage(for: resolved) == nil else { return }
                if let image = await RemoteImageLoader.shared.image(for: resolved) {
                    withAnimation(.easeInOut(duration: 0.2)) { loaded = LoadedImage(url: resolved, image: image) }
                } else if !Task.isCancelled {
                    failedURL = resolved
                }
            }
            .modifier(ImageAccessibility(alt: alt))
        } else {
            placeholder(systemImage: "photo")
                .modifier(ImageAccessibility(alt: alt))
        }
    }

    private func placeholder(systemImage: String?) -> some View {
        ZStack {
            theme.colors.sunkenSurface
            if let systemImage {
                VStack(spacing: 4) {
                    Image(systemName: systemImage)
                        .font(theme.fonts.bodyLarge)
                    if let alt, !alt.isEmpty {
                        Text(alt)
                            .font(theme.fonts.caption)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                .foregroundStyle(theme.colors.textTertiary)
                .padding(8)
            } else {
                ProgressView()
            }
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct ImageAccessibility: ViewModifier {
    let alt: String?

    func body(content: Content) -> some View {
        if let alt, !alt.isEmpty {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(alt))
                .accessibilityAddTraits(.isImage)
        } else {
            content.accessibilityHidden(true)
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension RemoteImage {
    /// Fills a full-width box of the given height without letting the image's size affect layout.
    func filling(height: CGFloat, cornerRadius: CGFloat) -> some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay { self }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Fills a full-width box with the given aspect ratio.
    func filling(aspectRatio: CGFloat, cornerRadius: CGFloat) -> some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay { self }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// Loads the images the model links to: one download per URL and `maxDownloads` at a time, decoded
// off the main thread at no more than `maxPixelSize`, and kept in a small in-memory cache that
// drops the least recently shown images first. A download stops once no view waits for it, and a
// URL that failed isn't downloaded again for `failureLifetime`.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class RemoteImageLoader {
    typealias Fetch = @Sendable (_ url: URL, _ maxBytes: Int) async throws -> Data

    static let shared = RemoteImageLoader()
    static let maxFailures = 256

    let maxPixelSize: Int
    let maxBytes: Int
    let costLimit: Int
    let maxDownloads: Int
    let failureLifetime: Duration
    private let fetch: Fetch
    private var images: [URL: CGImage] = [:]
    private var recentlyUsed: [URL] = []
    private var cost = 0
    private var loads: [URL: Load] = [:]
    private var queued: [URL] = []
    private var downloading = 0
    private var failures: [URL: ContinuousClock.Instant] = [:]
    private var lastID = 0

    private struct Load {
        let id: Int
        var task: Task<Void, Never>?
        var waiters: [Int: CheckedContinuation<CGImage?, Never>] = [:]
    }

    init(
        maxPixelSize: Int = 1200,
        maxBytes: Int = 20_000_000,
        costLimit: Int = 64 * 1024 * 1024,
        maxDownloads: Int = 4,
        failureLifetime: Duration = .seconds(300),
        fetch: @escaping Fetch = { try await RemoteImageLoader.download($0, maxBytes: $1) }
    ) {
        self.maxPixelSize = maxPixelSize
        self.maxBytes = maxBytes
        self.costLimit = costLimit
        self.maxDownloads = max(1, maxDownloads)
        self.failureLifetime = failureLifetime
        self.fetch = fetch
    }

    nonisolated static func url(from string: String?) -> URL? {
        guard let string, let url = URL(string: string), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }
        return url
    }

    func cachedImage(for url: URL) -> CGImage? {
        guard let image = images[url] else { return nil }
        markUsed(url)
        return image
    }

    func hasFailed(_ url: URL) -> Bool {
        guard let failed = failures[url] else { return false }
        if failed.duration(to: .now) < failureLifetime { return true }
        failures[url] = nil
        return false
    }

    // The image, or nil when it fails or the calling task is cancelled.
    func image(for url: URL) async -> CGImage? {
        if let image = cachedImage(for: url) { return image }
        guard !hasFailed(url), !Task.isCancelled else { return nil }
        let waiter = nextID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                wait(for: url, waiter: waiter, continuation: continuation)
            }
        } onCancel: {
            _ = Task { @MainActor in self.stopWaiting(for: url, waiter: waiter) }
        }
    }

    private func nextID() -> Int {
        lastID += 1
        return lastID
    }

    private func wait(for url: URL, waiter: Int, continuation: CheckedContinuation<CGImage?, Never>) {
        if loads[url] == nil {
            loads[url] = Load(id: nextID())
            queued.append(url)
        }
        loads[url]?.waiters[waiter] = continuation
        startQueuedLoads()
    }

    private func stopWaiting(for url: URL, waiter: Int) {
        guard let continuation = loads[url]?.waiters.removeValue(forKey: waiter) else { return }
        continuation.resume(returning: nil)
        guard loads[url]?.waiters.isEmpty == true else { return }
        loads[url]?.task?.cancel()
        loads[url] = nil
        queued.removeAll { $0 == url }
    }

    private func startQueuedLoads() {
        while downloading < maxDownloads, !queued.isEmpty {
            let url = queued.removeFirst()
            guard let load = loads[url], load.task == nil else { continue }
            downloading += 1
            let id = load.id
            loads[url]?.task = Task { await self.download(url, id: id) }
        }
    }

    private func download(_ url: URL, id: Int) async {
        let fetch = self.fetch
        let maxPixelSize = self.maxPixelSize
        let maxBytes = self.maxBytes
        let work = Task.detached(priority: .utility) { () -> CGImage? in
            guard let data = try? await fetch(url, maxBytes), data.count <= maxBytes else { return nil }
            return Self.downsample(data, maxPixelSize: maxPixelSize)
        }
        let image = await withTaskCancellationHandler {
            await work.value
        } onCancel: {
            work.cancel()
        }
        downloading -= 1
        finish(url, id: id, image: image)
        startQueuedLoads()
    }

    // Hands the image to the views still waiting. A load they all left was cancelled, which is
    // no failure.
    private func finish(_ url: URL, id: Int, image: CGImage?) {
        guard let load = loads[url], load.id == id else { return }
        loads[url] = nil
        if let image {
            store(image, for: url)
        } else {
            rememberFailure(url)
        }
        for continuation in load.waiters.values {
            continuation.resume(returning: image)
        }
    }

    private func rememberFailure(_ url: URL) {
        failures[url] = .now
        if failures.count > Self.maxFailures, let oldest = failures.min(by: { $0.value < $1.value })?.key {
            failures[oldest] = nil
        }
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

    // The model links to the image, so its server could send any amount: the download stops as
    // soon as it would go over `maxBytes`, or before it starts when the server says it would.
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

    private static func cost(of image: CGImage) -> Int {
        image.bytesPerRow * image.height
    }

    private func store(_ image: CGImage, for url: URL) {
        let imageCost = Self.cost(of: image)
        guard imageCost <= costLimit else { return }
        if let previous = images.updateValue(image, forKey: url) {
            cost -= Self.cost(of: previous)
        }
        cost += imageCost
        markUsed(url)
        while cost > costLimit, let oldest = recentlyUsed.first {
            recentlyUsed.removeFirst()
            if let removed = images.removeValue(forKey: oldest) {
                cost -= Self.cost(of: removed)
            }
        }
    }

    private func markUsed(_ url: URL) {
        if let index = recentlyUsed.lastIndex(of: url) {
            if index == recentlyUsed.count - 1 { return }
            recentlyUsed.remove(at: index)
        }
        recentlyUsed.append(url)
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct OpenUIMediaURLKey: EnvironmentKey {
    static let defaultValue: @Sendable (URL) -> URL? = { $0 }
}

@available(iOS 17.0, macOS 14.0, *)
extension EnvironmentValues {
    // The URL an image loads from, given the one the model wrote, or `nil` to not load it.
    var openUIMediaURL: @Sendable (URL) -> URL? {
        get { self[OpenUIMediaURLKey.self] }
        set { self[OpenUIMediaURLKey.self] = newValue }
    }
}
