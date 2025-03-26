// The MIT License (MIT)
//
// Copyright (c) 2015-2024 Alexander Grebenyuk (github.com/kean).

import Foundation

/// A registry of image codecs.
final class ImageDecoderRegistry: @unchecked Sendable {
    /// A shared registry.
    static let shared = ImageDecoderRegistry()

    private var matches = [(ImageDecodingContext) -> (any ImageDecoding)?]()
    private let lock = NSLock()

    /// Initializes a custom registry.
    init() {
        register(ImageDecoders.Default.init)
    }

    /// Returns a decoder that matches the given context.
    func decoder(for context: ImageDecodingContext) -> (any ImageDecoding)? {
        lock.lock()
        defer { lock.unlock() }

        for match in matches.reversed() {
            if let decoder = match(context) {
                return decoder
            }
        }
        return nil
    }

    /// Registers a decoder to be used in a given decoding context.
    ///
    /// **Progressive Decoding**
    ///
    /// The decoder is created once and is used for the entire decoding session,
    /// including progressively decoded images. If the decoder doesn't support
    /// progressive decoding, return `nil` when `isCompleted` is `false`.
    func register(_ match: @escaping (ImageDecodingContext) -> (any ImageDecoding)?) {
        lock.lock()
        defer { lock.unlock() }

        matches.append(match)
    }

    /// Removes all registered decoders.
    func clear() {
        lock.lock()
        defer { lock.unlock() }

        matches = []
    }
}

/// Image decoding context used when selecting which decoder to use.
struct ImageDecodingContext: @unchecked Sendable {
    var request: ImageRequest
    var data: Data
    /// Returns `true` if the download was completed.
    var isCompleted: Bool
    var urlResponse: URLResponse?
    var cacheType: ImageResponse.CacheType?

    init(request: ImageRequest, data: Data, isCompleted: Bool = true, urlResponse: URLResponse? = nil, cacheType: ImageResponse.CacheType? = nil) {
        self.request = request
        self.data = data
        self.isCompleted = isCompleted
        self.urlResponse = urlResponse
        self.cacheType = cacheType
    }
}
