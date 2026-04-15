//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// A thin abstraction over an image downloading pipeline (e.g. Nuke).
///
/// Each UI SDK provides its own conformance backed by its vendored image
/// loading library. ``StreamMediaLoader`` uses this protocol internally
/// so that `StreamChatCommonUI` never depends on Nuke directly.
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

    public init(image: UIImage) {
        self.image = image
    }
}
