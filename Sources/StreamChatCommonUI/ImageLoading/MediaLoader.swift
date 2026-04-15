//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// Options for loading a single image through a ``MediaLoader``.
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

/// Options for loading multiple images through a ``MediaLoader``.
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

/// Options for loading video content through a ``MediaLoader``.
public struct VideoLoadOptions: Sendable {
    /// The CDN requester for URL transformation (signing, headers).
    public var cdnRequester: CDNRequester

    public init(cdnRequester: CDNRequester) {
        self.cdnRequester = cdnRequester
    }
}

/// A unified protocol for loading images and video previews.
///
/// Merges the responsibilities of image loading and video preview generation
/// into a single protocol, eliminating stale-reference problems when customers
/// replace just one of the two loaders.
///
/// Configuration is passed via options structs on every call, so concrete
/// implementations remain stateless with respect to CDN configuration.
/// Changing the requester on `ChatClient` takes effect immediately without
/// recreating the loader.
public protocol MediaLoader: AnyObject, Sendable {
    // MARK: - Image Loading

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

    // MARK: - Video Loading

    /// Returns a video asset for the given URL.
    ///
    /// Implementers should use the CDN requester in options to adjust the URL
    /// before creating the asset.
    func videoAsset(at url: URL, options: VideoLoadOptions) -> AVURLAsset

    /// Loads a video preview thumbnail from a URL.
    ///
    /// - Parameters:
    ///   - url: The video URL.
    ///   - options: Options controlling CDN behavior.
    ///   - completion: A completion handler called on the main actor with the preview image.
    func loadVideoPreview(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    )

    /// Loads a video preview from a video attachment.
    ///
    /// The default implementation calls ``loadVideoPreview(at:options:completion:)``
    /// with the video URL. Override this method to use the attachment's thumbnail
    /// URL for preview generation.
    ///
    /// - Parameters:
    ///   - attachment: A video attachment containing the video URL and optional thumbnail URL.
    ///   - options: Options controlling CDN behavior.
    ///   - completion: A completion handler called on the main actor with the preview image.
    func loadVideoPreview(
        with attachment: ChatMessageVideoAttachment,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    )
}

// MARK: - Default Implementations

extension MediaLoader {
    public func videoAsset(at url: URL, options: VideoLoadOptions) -> AVURLAsset {
        AVURLAsset(url: url)
    }

    public func loadVideoPreview(
        with attachment: ChatMessageVideoAttachment,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        loadVideoPreview(at: attachment.videoURL, options: options, completion: completion)
    }
}

// MARK: - Async/Await Extensions

extension MediaLoader {
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
