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

    // MARK: - File Request

    /// Creates a request for downloading or previewing a file.
    ///
    /// Resolves the URL through the CDN (signing, rewriting) and packages the
    /// result into a ready-to-use request with any required HTTP headers.
    /// Pass the returned request to `downloadAttachment` or load it in a web view.
    ///
    /// - Parameters:
    ///   - url: The original file URL to resolve.
    ///   - options: Options controlling file request behavior.
    ///   - completion: A completion handler called on the main actor with the resolved request.
    func loadFileRequest(
        for url: URL,
        options: DownloadFileRequestOptions,
        completion: @escaping @MainActor (Result<MediaLoaderFileRequest, Error>) -> Void
    )
}

// MARK: - Convenience Extensions

extension MediaLoader {
    public func loadImage(
        url: URL?,
        completion: @escaping @MainActor (Result<MediaLoaderImage, Error>) -> Void
    ) {
        loadImage(url: url, options: ImageLoadOptions(), completion: completion)
    }

    public func loadVideoAsset(
        at url: URL,
        completion: @escaping @MainActor (Result<MediaLoaderVideoAsset, Error>) -> Void
    ) {
        loadVideoAsset(at: url, options: VideoLoadOptions(), completion: completion)
    }

    public func loadVideoPreview(
        with attachment: ChatMessageVideoAttachment,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        loadVideoPreview(with: attachment, options: VideoLoadOptions(), completion: completion)
    }

    public func loadVideoPreview(
        at url: URL,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        loadVideoPreview(at: url, options: VideoLoadOptions(), completion: completion)
    }

    public func loadFileRequest(
        for url: URL,
        completion: @escaping @MainActor (Result<MediaLoaderFileRequest, Error>) -> Void
    ) {
        loadFileRequest(for: url, options: DownloadFileRequestOptions(), completion: completion)
    }
}

// MARK: - Async/Await Extensions

extension MediaLoader {
    public func loadImage(
        url: URL?,
        options: ImageLoadOptions = ImageLoadOptions()
    ) async throws -> MediaLoaderImage {
        try await withCheckedThrowingContinuation { continuation in
            loadImage(url: url, options: options) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func loadVideoAsset(
        at url: URL,
        options: VideoLoadOptions = VideoLoadOptions()
    ) async throws -> MediaLoaderVideoAsset {
        try await withCheckedThrowingContinuation { continuation in
            loadVideoAsset(at: url, options: options) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func loadVideoPreview(
        at url: URL,
        options: VideoLoadOptions = VideoLoadOptions()
    ) async throws -> MediaLoaderVideoPreview {
        try await withCheckedThrowingContinuation { continuation in
            loadVideoPreview(at: url, options: options) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func loadFileRequest(
        for url: URL,
        options: DownloadFileRequestOptions = DownloadFileRequestOptions()
    ) async throws -> MediaLoaderFileRequest {
        try await withCheckedThrowingContinuation { continuation in
            loadFileRequest(for: url, options: options) { result in
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
}

/// Options for loading video content through a ``MediaLoader``.
public struct VideoLoadOptions: Sendable {
    public init() {}
}

/// Options for creating a file download request through a ``MediaLoader``.
public struct DownloadFileRequestOptions: Sendable {
    public init() {}
}

// MARK: - Result Types

/// The result of loading a single image through a ``MediaLoader``.
public struct MediaLoaderImage: Sendable {
    /// The loaded image.
    public var image: UIImage
    /// Whether the image is an animated format (e.g. GIF).
    public var isAnimated: Bool
    /// The raw image data for animated rendering. `nil` for static images.
    public var animatedImageData: Data?
    /// The caching key used by the CDN requester, if any.
    /// UI layers can use this to maintain a synchronous cache lookup table.
    public var cachingKey: String?

    public init(image: UIImage, isAnimated: Bool = false, animatedImageData: Data? = nil, cachingKey: String? = nil) {
        self.image = image
        self.isAnimated = isAnimated
        self.animatedImageData = animatedImageData
        self.cachingKey = cachingKey
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

/// The result of resolving a file download request through a ``MediaLoader``.
public struct MediaLoaderFileRequest: Sendable {
    /// A ready-to-use URL request with CDN-resolved URL and any required HTTP headers.
    public var urlRequest: URLRequest

    public init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
    }
}

