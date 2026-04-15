//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Options for loading a single image through an ``ImageLoader``.
public struct ImageLoadOptions: Sendable {
    /// Optional resize parameters for server-side resizing.
    public var resize: ImageResize?
    /// The CDN requester for URL transformation (signing, headers, resizing).
    public var cdnRequester: CDNRequester

    public init(resize: ImageResize? = nil, cdnRequester: CDNRequester) {
        self.resize = resize
        self.cdnRequester = cdnRequester
    }
}

/// Options for loading multiple images through an ``ImageLoader``.
public struct ImageBatchLoadOptions: Sendable {
    /// Placeholder images used rotationally when a URL fails to load.
    public var placeholders: [UIImage]
    /// Whether to load thumbnail-sized versions of the images.
    public var loadThumbnails: Bool
    /// The desired thumbnail size in points.
    public var thumbnailSize: CGSize
    /// The CDN requester for URL transformation (signing, headers, resizing).
    public var cdnRequester: CDNRequester

    public init(
        placeholders: [UIImage] = [],
        loadThumbnails: Bool = true,
        thumbnailSize: CGSize = CGSize(width: 40, height: 40),
        cdnRequester: CDNRequester
    ) {
        self.placeholders = placeholders
        self.loadThumbnails = loadThumbnails
        self.thumbnailSize = thumbnailSize
        self.cdnRequester = cdnRequester
    }
}

/// A protocol for loading and caching images.
///
/// Configuration is passed via options structs on every call, so concrete
/// implementations remain stateless with respect to CDN configuration.
/// Changing the requester on `ChatClient` takes effect immediately
/// without recreating loaders.
public protocol ImageLoader: AnyObject, Sendable {
    /// Loads a single image from the given URL.
    ///
    /// - Parameters:
    ///   - url: The image URL. If nil, the completion is called with a failure.
    ///   - options: Options controlling resize and CDN behavior.
    ///   - completion: A completion handler called on the main actor with the loaded image.
    func loadImage(
        url: URL?,
        options: ImageLoadOptions,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    )

    /// Loads multiple images from the given URLs.
    ///
    /// - Parameters:
    ///   - urls: The image URLs to load.
    ///   - options: Options controlling placeholders, thumbnails, and CDN behavior.
    ///   - completion: A completion handler called on the main actor with all loaded images.
    func loadImages(
        from urls: [URL],
        options: ImageBatchLoadOptions,
        completion: @escaping @MainActor ([UIImage]) -> Void
    )
}

// MARK: - Async/Await Extensions

extension ImageLoader {
    /// Loads a single image from the given URL.
    public func loadImage(
        url: URL?,
        options: ImageLoadOptions
    ) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            loadImage(url: url, options: options) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Loads multiple images from the given URLs.
    public func loadImages(
        from urls: [URL],
        options: ImageBatchLoadOptions
    ) async -> [UIImage] {
        await withCheckedContinuation { continuation in
            loadImages(from: urls, options: options) { images in
                continuation.resume(returning: images)
            }
        }
    }
}
