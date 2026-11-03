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
                        .font(.title3)
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

// Loads the images the model links to: one download per URL, decoded off the main thread at no
// more than `maxPixelSize`, and kept in a small in-memory cache that drops the least recently
// shown images first.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class RemoteImageLoader {
    typealias Fetch = @Sendable (_ url: URL, _ maxBytes: Int) async throws -> Data

    static let shared = RemoteImageLoader()

    let maxPixelSize: Int
    let maxBytes: Int
    let costLimit: Int
    private let fetch: Fetch
    private var images: [URL: CGImage] = [:]
    private var recentlyUsed: [URL] = []
    private var cost = 0
    private var loads: [URL: Task<CGImage?, Never>] = [:]

    init(
        maxPixelSize: Int = 1200,
        maxBytes: Int = 20_000_000,
        costLimit: Int = 64 * 1024 * 1024,
        fetch: @escaping Fetch = { try await RemoteImageLoader.download($0, maxBytes: $1) }
    ) {
        self.maxPixelSize = maxPixelSize
        self.maxBytes = maxBytes
        self.costLimit = costLimit
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
        if let image { store(image, for: url) }
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
