//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

/// A policy describing how video attachments are cached on disk.
@available(iOS 14.0, *)
public final class VideoAttachmentCachingPolicy: Sendable {
    /// The maximum total size of the video attachment disk cache, in bytes.
    public let maxCacheSize: Int

    /// The content types eligible for caching.
    ///
    /// Defaults to `[.movie]`, which caches standard video files (mp4, mov, …) while
    /// excluding HLS playlists (`.m3u8`).
    public let allowedContentTypes: Set<UTType>

    /// Creates a video attachment caching policy.
    /// - Parameters:
    ///   - maxCacheSize: The maximum total size of the disk cache, in bytes. Caching is disabled when `<= 0`.
    ///   - allowedContentTypes: The content types eligible for caching. Defaults to `[.movie]`.
    public init(maxCacheSize: Int, allowedContentTypes: Set<UTType> = [.movie]) {
        self.maxCacheSize = maxCacheSize
        self.allowedContentTypes = allowedContentTypes
    }
}
