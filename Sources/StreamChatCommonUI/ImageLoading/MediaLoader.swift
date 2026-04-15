//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// A unified protocol for loading images and video previews.
///
/// Merges the responsibilities of image loading and video preview generation
/// into a single protocol, eliminating stale-reference problems when customers
/// replace just one of the two loaders.
///
/// Configuration is passed via options structs on every call, so concrete
/// implementations remain stateless with respect to CDN configuration.
/// Changing the requester on `ChatClientConfig` takes effect immediately without
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
        completion: @escaping @MainActor (Result<MediaLoaderImage, Error>) -> Void
    )

    // MARK: - Video Loading

    /// Returns a video asset for the given URL.
    ///
    /// Implementers should use the CDN requester in options to adjust the URL
    /// before creating the asset.
    func loadVideoAsset(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoAsset, Error>) -> Void
    )

    /// Loads a video preview from a video attachment.
    ///
    /// When the attachment has a ``VideoAttachmentPayload/thumbnailURL``,
    /// implementations should prefer loading the remote thumbnail and fall back
    /// to generating a preview frame from the video URL.
    ///
    /// - Parameters:
    ///   - attachment: A video attachment containing the video URL and optional thumbnail URL.
    ///   - options: Options controlling CDN behavior.
    ///   - completion: A completion handler called on the main actor with the preview image.
    func loadVideoPreview(
        with attachment: ChatMessageVideoAttachment,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    )
}

// MARK: - Default Implementations

extension MediaLoader {
    public func loadVideoAsset(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoAsset, Error>) -> Void
    ) {
        StreamConcurrency.onMain {
            completion(.success(MediaLoaderVideoAsset(asset: AVURLAsset(url: url))))
        }
    }
}

// MARK: - Async/Await Extensions

extension MediaLoader {
    /// Loads a single image from the given URL.
    public func loadImage(
        url: URL?,
        options: ImageLoadOptions
    ) async throws -> MediaLoaderImage {
        try await withCheckedThrowingContinuation { continuation in
            loadImage(url: url, options: options) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Returns a video asset for the given URL.
    public func loadVideoAsset(
        at url: URL,
        options: VideoLoadOptions
    ) async throws -> MediaLoaderVideoAsset {
        try await withCheckedThrowingContinuation { continuation in
            loadVideoAsset(at: url, options: options) { result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: - Options

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

/// Options for loading video content through a ``MediaLoader``.
public struct VideoLoadOptions: Sendable {
    /// The CDN requester for URL transformation (signing, headers).
    public var cdnRequester: CDNRequester

    public init(cdnRequester: CDNRequester) {
        self.cdnRequester = cdnRequester
    }
}

// MARK: - Result Types

/// The result of loading a single image through a ``MediaLoader``.
public struct MediaLoaderImage: Sendable {
    /// The loaded image.
    public var image: UIImage

    public init(image: UIImage) {
        self.image = image
    }
}

/// The result of loading a video asset through a ``MediaLoader``.
public struct MediaLoaderVideoAsset: Sendable {
    /// The video asset.
    public var asset: AVURLAsset

    public init(asset: AVURLAsset) {
        self.asset = asset
    }
}

/// The result of loading a video preview through a ``MediaLoader``.
public struct MediaLoaderVideoPreview: Sendable {
    /// The preview thumbnail image.
    public var image: UIImage

    public init(image: UIImage) {
        self.image = image
    }
}
