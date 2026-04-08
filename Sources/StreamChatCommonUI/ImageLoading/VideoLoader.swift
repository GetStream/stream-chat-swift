//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A protocol for loading video preview thumbnails.
///
/// The `CDN` dependency is injected into the concrete implementation at init time,
/// not passed as a parameter to protocol methods.
public protocol VideoLoader: AnyObject, Sendable {
    /// Loads a video preview thumbnail from a URL.
    ///
    /// - Parameters:
    ///   - url: The video URL.
    ///   - completion: A completion handler called on the main actor with the preview image.
    func loadPreview(
        at url: URL,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    )

    /// Loads a video preview from a video attachment.
    ///
    /// The default implementation calls ``loadPreview(at:completion:)`` with the video URL.
    /// Override this method to use the attachment's thumbnail URL for preview generation.
    ///
    /// - Parameters:
    ///   - attachment: A video attachment containing the video URL and optional thumbnail URL.
    ///   - completion: A completion handler called on the main actor with the preview image.
    func loadPreview(
        with attachment: ChatMessageVideoAttachment,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    )
}

extension VideoLoader {
    public func loadPreview(
        with attachment: ChatMessageVideoAttachment,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        loadPreview(at: attachment.videoURL, completion: completion)
    }
}
