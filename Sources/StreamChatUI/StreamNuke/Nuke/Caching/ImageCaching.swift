// The MIT License (MIT)
//
// Copyright (c) 2015-2024 Alexander Grebenyuk (github.com/kean).

import Foundation

/// In-memory image cache.
///
/// The implementation must be thread safe.
protocol ImageCaching: AnyObject, Sendable {
    /// Access the image cached for the given request.
    subscript(key: ImageCacheKey) -> ImageContainer? { get set }

    /// Removes all caches items.
    func removeAll()
}

/// An opaque container that acts as a cache key.
///
/// In general, you don't construct it directly, and use ``ImagePipeline`` or ``ImagePipeline/Cache-swift.struct`` APIs.
struct ImageCacheKey: Hashable, Sendable {
    let key: Inner

    // This is faster than using AnyHashable (and it shows in performance tests).
    enum Inner: Hashable, Sendable {
        case custom(String)
        case `default`(MemoryCacheKey)
    }

    init(key: String) {
        self.key = .custom(key)
    }

    init(request: ImageRequest) {
        self.key = .default(MemoryCacheKey(request))
    }
}
