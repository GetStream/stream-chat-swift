//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// A unified protocol for loading images, video previews, and resolving file URLs.
///
/// The ``CDNRequester`` is provided as a constructor dependency of the concrete
/// implementation (e.g. ``StreamMediaLoader``), so callers don't need to pass
/// it on every call. Configuring the CDN requester in one place ensures all
/// content loading automatically picks it up.
public protocol MediaLoader: AnyObject, Sendable {
    // MARK: - Image Loading

    /// Loads a single image from the given URL.
    ///
    /// - Parameters:
    ///   - url: The image URL. If nil, the completion is called with a failure.
    ///   - options: Options controlling resize behavior.
    ///   - completion: A completion handler called on the main actor with the loaded image.
    func loadImage(
        url: URL?,
        options: ImageLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderImage, Error>) -> Void
    )

    // MARK: - Video Loading

    /// Returns a video asset for the given URL.
    ///
    /// The implementation resolves the URL through its CDN requester before
    /// creating the asset.
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
    ///   - options: Options controlling video load behavior.
    ///   - completion: A completion handler called on the main actor with the preview image.
    func loadVideoPreview(
        with attachment: ChatMessageVideoAttachment,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    )

    /// Generates a video preview thumbnail from a URL.
    ///
    /// This is primarily intended for **local videos** (e.g., files picked from the
    /// photo library or camera) that don't have a remote attachment or thumbnail URL.
    /// It generates a preview frame directly from the video using AVFoundation.
    ///
    /// For remote videos that have an associated ``ChatMessageVideoAttachment``,
    /// prefer ``loadVideoPreview(with:options:completion:)`` instead, as it can
    /// take advantage of remote thumbnail URLs when available.
    ///
    /// - Parameters:
    ///   - url: The video URL (typically a local `file://` URL).
    ///   - options: Options controlling video load behavior.
    ///   - completion: A completion handler called on the main actor with the preview image.
    func loadVideoPreview(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    )

    // MARK: - File URL Resolution

    /// Resolves a file URL through the CDN (signing, headers, etc.).
    ///
    /// Use this before passing a URL to `downloadAttachment` or displaying
    /// content in a web view that requires CDN-signed URLs.
    ///
    /// - Parameters:
    ///   - url: The original file URL to resolve.
    ///   - completion: A completion handler called on the main actor with the resolved CDN request.
    func resolveFileURL(
        _ url: URL,
        completion: @escaping @MainActor (Result<CDNRequest, Error>) -> Void
    )
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

    /// Generates a video preview thumbnail from a URL.
    public func loadVideoPreview(
        at url: URL,
        options: VideoLoadOptions
    ) async throws -> MediaLoaderVideoPreview {
        try await withCheckedThrowingContinuation { continuation in
            loadVideoPreview(at: url, options: options) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Resolves a file URL through the CDN.
    public func resolveFileURL(_ url: URL) async throws -> CDNRequest {
        try await withCheckedThrowingContinuation { continuation in
            resolveFileURL(url) { result in
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

    public init(resize: ImageResize? = nil) {
        self.resize = resize
    }

    @available(*, deprecated, message: "CDNRequester is now a dependency of StreamMediaLoader. Pass it when creating the loader instead.")
    public init(resize: ImageResize? = nil, cdnRequester: CDNRequester) {
        self.resize = resize
    }
}

/// Options for loading video content through a ``MediaLoader``.
public struct VideoLoadOptions: Sendable {
    public init() {}

    @available(*, deprecated, message: "CDNRequester is now a dependency of StreamMediaLoader. Pass it when creating the loader instead.")
    public init(cdnRequester: CDNRequester) {}
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
