//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// A protocol for loading video preview thumbnails.
///
/// The `CDNRequester` is passed on every call, so concrete implementations
/// remain stateless with respect to CDN configuration.
public protocol VideoLoader: AnyObject, Sendable {
    /// Returns a video asset for the given URL.
    ///
    /// Implementers should use the CDN requester to adjust the URL
    /// before creating the asset.
    func videoAsset(at url: URL, cdnRequester: CDNRequester) -> AVURLAsset

    /// Loads a video preview thumbnail from a URL.
    ///
    /// - Parameters:
    ///   - url: The video URL.
    ///   - cdnRequester: The CDN requester for URL transformation.
    ///   - completion: A completion handler called on the main actor with the preview image.
    func loadPreview(
        at url: URL,
        cdnRequester: CDNRequester,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    )

    /// Loads a video preview from a video attachment.
    ///
    /// The default implementation calls ``loadPreview(at:cdnRequester:completion:)`` with the video URL.
    /// Override this method to use the attachment's thumbnail URL for preview generation.
    ///
    /// - Parameters:
    ///   - attachment: A video attachment containing the video URL and optional thumbnail URL.
    ///   - cdnRequester: The CDN requester for URL transformation.
    ///   - completion: A completion handler called on the main actor with the preview image.
    func loadPreview(
        with attachment: ChatMessageVideoAttachment,
        cdnRequester: CDNRequester,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    )
}

extension VideoLoader {
    public func loadPreview(
        with attachment: ChatMessageVideoAttachment,
        cdnRequester: CDNRequester,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        loadPreview(at: attachment.videoURL, cdnRequester: cdnRequester, completion: completion)
    }
}
