//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// The default Stream CDN implementation.
///
/// Handles image resize query parameters for `stream-io-cdn.com` URLs
/// and provides cache keys that strip dynamic parameters while
/// preserving resize-related ones.
///
/// For file/video requests, returns the URL unchanged.
/// Subclass to add signing, custom headers, or different CDN behavior.
open class StreamCDNRequester: CDNRequester, @unchecked Sendable {
    public nonisolated(unsafe) static var streamCDNURL = "stream-io-cdn.com"

    public init() {}

    open func imageRequest(
        for url: URL,
        options: ImageRequestOptions,
        completion: @escaping (Result<CDNRequest, Error>) -> Void
    ) {
        let finalURL = buildImageURL(from: url, resize: options.resize)
        let cachingKey = buildCachingKey(for: url)
        completion(.success(CDNRequest(url: finalURL, cachingKey: cachingKey)))
    }

    open func fileRequest(
        for url: URL,
        options: FileRequestOptions,
        completion: @escaping (Result<CDNRequest, Error>) -> Void
    ) {
        completion(.success(CDNRequest(url: url)))
    }

    // MARK: - URL Building

    /// Builds an image URL with resize query parameters for Stream CDN URLs.
    open func buildImageURL(from url: URL, resize: CDNImageResize?) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host, host.contains(StreamCDNRequester.streamCDNURL) else {
            return url
        }

        guard let resize else {
            return url
        }

        let scale = Self.screenScale
        var queryItems: [String: String] = [
            "w": resize.width == 0 ? "*" : String(format: "%.0f", resize.width * scale),
            "h": resize.height == 0 ? "*" : String(format: "%.0f", resize.height * scale),
            "resize": resize.resizeMode,
            "ro": "0"
        ]
        if let crop = resize.crop {
            queryItems["crop"] = crop
        }

        var items = components.queryItems ?? []
        for (key, value) in queryItems {
            if let index = items.firstIndex(where: { $0.name == key }) {
                items[index].value = value
            } else {
                items.append(URLQueryItem(name: key, value: value))
            }
        }

        components.queryItems = items
        return components.url ?? url
    }

    /// Builds a caching key for the given URL, stripping dynamic parameters
    /// but preserving resize-related query parameters.
    open func buildCachingKey(for url: URL) -> String {
        let key = url.absoluteString

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host, host.contains(StreamCDNRequester.streamCDNURL) else {
            return key
        }

        let persistedParameters = ["w", "h", "resize", "crop"]
        let newParameters = components.queryItems?.filter { persistedParameters.contains($0.name) } ?? []
        components.queryItems = newParameters.isEmpty ? nil : newParameters
        return components.string ?? key
    }

    // MARK: - Screen Scale

    private static let screenScale: CGFloat = {
        #if canImport(UIKit) && !os(watchOS)
        return UITraitCollection.current.displayScale
        #else
        return 1.0
        #endif
    }()
}
