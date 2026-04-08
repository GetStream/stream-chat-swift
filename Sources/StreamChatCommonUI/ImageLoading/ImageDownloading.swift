//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// A thin abstraction over an image downloading pipeline (e.g. Nuke).
///
/// Each UI SDK provides its own conformance backed by its vendored image
/// loading library. ``StreamImageLoader`` uses this protocol internally
/// so that `StreamChatCommonUI` never depends on Nuke directly.
public protocol ImageDownloading: Sendable {
    /// Downloads an image from the given URL.
    ///
    /// - Parameters:
    ///   - url: The image URL to download.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - cachingKey: Optional caching key. If nil, the URL string is used.
    ///   - resize: Optional target size for client-side resizing.
    ///   - completion: Called on the main actor with the downloaded image.
    func downloadImage(
        url: URL,
        headers: [String: String]?,
        cachingKey: String?,
        resize: CGSize?,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    )
}
