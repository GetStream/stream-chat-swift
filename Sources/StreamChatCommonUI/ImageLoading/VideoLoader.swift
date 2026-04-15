//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// Options for loading video content through a ``VideoLoader``.
public struct VideoLoadOptions: Sendable {
    /// The CDN requester for URL transformation (signing, headers).
    public var cdnRequester: CDNRequester

    public init(cdnRequester: CDNRequester) {
        self.cdnRequester = cdnRequester
    }
}

/// A protocol for loading video preview thumbnails.
///
/// Configuration is passed via ``VideoLoadOptions`` on every call, so
/// concrete implementations remain stateless with respect to CDN configuration.
public protocol VideoLoader: AnyObject, Sendable {
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
    func loadPreview(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    )

    /// Loads a video preview from a video attachment.
    ///
    /// The default implementation calls ``loadPreview(at:options:completion:)`` with the video URL.
    /// Override this method to use the attachment's thumbnail URL for preview generation.
    ///
    /// - Parameters:
    ///   - attachment: A video attachment containing the video URL and optional thumbnail URL.
    ///   - options: Options controlling CDN behavior.
    ///   - completion: A completion handler called on the main actor with the preview image.
    func loadPreview(
        with attachment: ChatMessageVideoAttachment,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    )
}

extension VideoLoader {
    public func loadPreview(
        with attachment: ChatMessageVideoAttachment,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        loadPreview(at: attachment.videoURL, options: options, completion: completion)
    }
}
