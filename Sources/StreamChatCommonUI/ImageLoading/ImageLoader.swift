//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A protocol for loading and caching images.
///
/// The `CDN` dependency is injected into the concrete implementation at init time,
/// not passed as a parameter to protocol methods.
public protocol ImageLoader: AnyObject, Sendable {
    /// Loads a single image from the given URL.
    ///
    /// - Parameters:
    ///   - url: The image URL. If nil, the completion is called with a failure.
    ///   - resize: Optional resize parameters for server-side resizing.
    ///   - completion: A completion handler called on the main actor with the loaded image.
    func loadImage(
        url: URL?,
        resize: ImageResize?,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    )

    /// Loads multiple images from the given URLs.
    ///
    /// - Parameters:
    ///   - urls: The image URLs to load.
    ///   - placeholders: Placeholder images used rotationally when a URL fails to load.
    ///   - loadThumbnails: Whether to load thumbnail-sized versions of the images.
    ///   - thumbnailSize: The desired thumbnail size in points.
    ///   - completion: A completion handler called on the main actor with all loaded images.
    func loadImages(
        from urls: [URL],
        placeholders: [UIImage],
        loadThumbnails: Bool,
        thumbnailSize: CGSize,
        completion: @escaping @MainActor ([UIImage]) -> Void
    )
}

// MARK: - Async/Await Extensions

extension ImageLoader {
    /// Loads a single image from the given URL.
    public func loadImage(
        url: URL?,
        resize: ImageResize? = nil
    ) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            loadImage(url: url, resize: resize) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Loads multiple images from the given URLs.
    public func loadImages(
        from urls: [URL],
        placeholders: [UIImage],
        loadThumbnails: Bool = true,
        thumbnailSize: CGSize = CGSize(width: 40, height: 40)
    ) async -> [UIImage] {
        await withCheckedContinuation { continuation in
            loadImages(from: urls, placeholders: placeholders, loadThumbnails: loadThumbnails, thumbnailSize: thumbnailSize) { images in
                continuation.resume(returning: images)
            }
        }
    }
}
