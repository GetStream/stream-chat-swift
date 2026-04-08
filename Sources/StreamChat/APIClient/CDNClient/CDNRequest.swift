//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The result of a CDN URL transformation, containing the final URL,
/// optional HTTP headers, and an optional caching key.
public struct CDNRequest: Sendable {
    /// The (potentially rewritten/signed) URL to load.
    public var url: URL
    /// Optional HTTP headers to include in the load request.
    public var headers: [String: String]?
    /// Optional caching key. If nil, the loader defaults to using the URL string.
    public var cachingKey: String?

    public init(url: URL, headers: [String: String]? = nil, cachingKey: String? = nil) {
        self.url = url
        self.headers = headers
        self.cachingKey = cachingKey
    }
}
