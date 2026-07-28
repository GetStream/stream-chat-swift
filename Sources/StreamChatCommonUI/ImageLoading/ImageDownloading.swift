//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// A thin abstraction over an image downloading pipeline.
///
/// ``StreamMediaLoader`` uses this protocol internally, with ``StreamImageDownloader``
/// as the default conformance. A custom implementation can back image loading
/// with a different pipeline.
public protocol ImageDownloading: Sendable {
    /// Downloads an image from the given URL.
    ///
    /// - Parameters:
    ///   - url: The image URL to download.
    ///   - options: Options controlling headers, caching, and resizing.
    ///   - completion: Called on the main actor with the downloaded image.
    func downloadImage(
        url: URL,
        options: ImageDownloadingOptions,
        completion: @escaping @MainActor (Result<DownloadedImage, Error>) -> Void
    )

    /// Evicts least-recently-used images from the in-memory cache until its
    /// total cost drops to the given limit in bytes.
    func trimMemoryCache(toCost limit: Int)
}

// MARK: - Default Implementations

extension ImageDownloading {
    /// Does nothing by default.
    public func trimMemoryCache(toCost limit: Int) {}
}

// MARK: - Options

/// Options for downloading an image through ``ImageDownloading``.
public struct ImageDownloadingOptions: Sendable {
    /// Optional HTTP headers to include in the request.
    public var headers: [String: String]?
    /// Optional caching key. If nil, the URL string is used.
    public var cachingKey: String?
    /// Optional target size for client-side resizing.
    public var resize: CGSize?

    public init(
        headers: [String: String]? = nil,
        cachingKey: String? = nil,
        resize: CGSize? = nil
    ) {
        self.headers = headers
        self.cachingKey = cachingKey
        self.resize = resize
    }
}

// MARK: - Result Types

/// The result of downloading an image through ``ImageDownloading``.
public struct DownloadedImage: Sendable {
    /// The downloaded image.
    public var image: UIImage
    /// The raw image data for animated rendering. `nil` for static images.
    public var animatedImageData: Data?

    public init(image: UIImage, animatedImageData: Data? = nil) {
        self.image = image
        self.animatedImageData = animatedImageData
    }
}
