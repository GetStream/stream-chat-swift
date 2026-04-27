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
/// Handles image resize query parameters for the configured CDN host
/// and provides cache keys that strip dynamic parameters while
/// preserving resize-related ones.
///
/// For file/video requests, returns the URL unchanged.
/// To add signing, custom headers, or different CDN behavior,
/// implement ``CDNRequester`` directly. You can delegate to a
/// `StreamCDNRequester` instance for default resize and caching logic.
public final class StreamCDNRequester: CDNRequester, Sendable {
    /// The CDN host used to match URLs for resize and caching logic.
    public let cdnHost: String

    public init(cdnHost: String = "stream-io-cdn.com") {
        self.cdnHost = cdnHost
    }

    public func imageRequest(
        for url: URL,
        options: ImageRequestOptions,
        completion: @escaping (Result<CDNRequest, Error>) -> Void
    ) {
        let finalURL = buildImageURL(from: url, resize: options.resize)
        let cachingKey = buildCachingKey(for: finalURL)
        completion(.success(CDNRequest(url: finalURL, cachingKey: cachingKey)))
    }

    public func fileRequest(
        for url: URL,
        options: FileRequestOptions,
        completion: @escaping (Result<CDNRequest, Error>) -> Void
    ) {
        completion(.success(CDNRequest(url: url)))
    }

    // MARK: - URL Building

    private func buildImageURL(from url: URL, resize: CDNImageResize?) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host, host.contains(cdnHost) else {
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

    private func buildCachingKey(for url: URL) -> String {
        let key = url.absoluteString

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host, host.contains(cdnHost) else {
            return key
        }

        let persistedParameters = ["w", "h", "resize", "crop"]
        // Sort the persisted parameters so the caching key is independent
        // of the upstream query-item insertion order. Without sorting, two
        // URLs that describe the same image at the same size but were
        // assembled in different orders would hash to different cache
        // entries — `buildImageURL` builds them from a `[String: String]`
        // dictionary whose iteration order is not stable across calls.
        let newParameters = (components.queryItems ?? [])
            .filter { persistedParameters.contains($0.name) }
            .sorted { $0.name < $1.name }
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
