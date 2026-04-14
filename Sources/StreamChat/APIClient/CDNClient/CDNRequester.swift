//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol for transforming CDN URLs before loading images and files.
///
/// Implement this protocol to add signing, authentication headers,
/// resize query parameters, or to rewrite the CDN host.
///
/// All methods use completion handlers to support asynchronous operations
/// such as fetching pre-signed URLs from a server.
public protocol CDNRequester: Sendable {
    /// Transforms an image URL for loading.
    ///
    /// Called before every image load. Use this to add signing,
    /// auth headers, resize query params, or rewrite the host.
    ///
    /// - Parameters:
    ///   - url: The original image URL.
    ///   - options: Options for the image request, such as resize parameters.
    ///   - completion: A completion handler with the transformed request.
    func imageRequest(
        for url: URL,
        options: ImageRequestOptions,
        completion: @escaping (Result<CDNRequest, Error>) -> Void
    )

    /// Transforms a file or video URL for loading or playback.
    ///
    /// Called before loading non-image media. Use this to add signing
    /// or auth headers for file and video access.
    ///
    /// - Parameters:
    ///   - url: The original file/video URL.
    ///   - options: Options for the file request.
    ///   - completion: A completion handler with the transformed request.
    func fileRequest(
        for url: URL,
        options: FileRequestOptions,
        completion: @escaping (Result<CDNRequest, Error>) -> Void
    )
}

// MARK: - Async/Await Extensions

extension CDNRequester {
    /// Transforms an image URL for loading.
    public func imageRequest(for url: URL, options: ImageRequestOptions = .init()) async throws -> CDNRequest {
        try await withCheckedThrowingContinuation { continuation in
            imageRequest(for: url, options: options) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Transforms a file or video URL for loading or playback.
    public func fileRequest(for url: URL, options: FileRequestOptions = .init()) async throws -> CDNRequest {
        try await withCheckedThrowingContinuation { continuation in
            fileRequest(for: url, options: options) { result in
                continuation.resume(with: result)
            }
        }
    }
}

/// Options for an image request through the CDN.
public struct ImageRequestOptions: Sendable {
    /// Optional resize parameters for server-side resizing.
    public var resize: ImageResize?

    public init(resize: ImageResize? = nil) {
        self.resize = resize
    }
}

/// Options for a file or video request through the CDN.
public struct FileRequestOptions: Sendable {
    public init() {}
}
