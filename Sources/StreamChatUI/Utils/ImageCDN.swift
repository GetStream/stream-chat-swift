//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// ImageCDN is providing set of functions to improve handling of images from CDN.
public protocol ImageCDN {
    /// Customised (filtered) key for image cache.
    /// - Parameter imageURL: URL of the image that should be customised (filtered).
    /// - Returns: String to be used as an image cache key.
    func cachingKey(forImage url: URL) -> String
    
    /// Prepare and return a `URLRequest` for the given image `URL`
    /// This function can be used to inject custom headers for image loading request.
    func urlRequest(forImage url: URL) -> URLRequest
    
    /// Enhance image URL with size parameters to get thumbnail
    /// - Parameters:
    ///   - originalURL: URL of the image to get the thumbnail for.
    ///   - preferredSize: The requested thumbnail size.
    ///
    /// Use view size in points for `preferredSize`, point to pixel ratio (scale) of the device is applied inside of this function.
    func thumbnailURL(originalURL: URL, preferredSize: CGSize) -> URL
}

extension ImageCDN {
    public func urlRequest(forImage url: URL) -> URLRequest {
        URLRequest(url: url)
    }
}

open class StreamImageCDN: ImageCDN {
    public static var streamCDNURL = "stream-io-cdn.com"
    
    // Initializer required for subclasses
    public init() {}
    
    open func cachingKey(forImage url: URL) -> String {
        let key = url.absoluteString
        
        guard
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let host = components.host,
            host.contains(StreamImageCDN.streamCDNURL)
        else { return key }
        
        // Keep these parameters in the cache key as they determine the image size.
        let persistedParameters = ["w", "h"]
        
        let newParameters = components.queryItems?.filter { persistedParameters.contains($0.name) } ?? []
        components.queryItems = newParameters.isEmpty ? nil : newParameters
        return components.string ?? key
    }
    
    // Although this is the same as the default impl, we still need it
    // so subclasses can safely override it
    open func urlRequest(forImage url: URL) -> URLRequest {
        URLRequest(url: url)
    }
    
    open func thumbnailURL(originalURL: URL, preferredSize: CGSize) -> URL {
        guard
            var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: true),
            let host = components.host,
            host.contains(StreamImageCDN.streamCDNURL)
        else { return originalURL }

        let scale = UIScreen.main.scale
        let queryItems: [String: String] = [
            "w": preferredSize.width == 0 ? "*" : String(format: "%.0f", preferredSize.width * scale),
            "h": preferredSize.height == 0 ? "*" : String(format: "%.0f", preferredSize.height * scale),
            "crop": "center",
            "resize": "fill",
            "ro": "0" // Required parameter.
        ]

        var items = components.queryItems ?? []

        for (key, value) in queryItems {
            if let index = items.firstIndex(where: { $0.name == key }) {
                items[index].value = value
            } else {
                let item = URLQueryItem(name: key, value: value)
                items += [item]
            }
        }

        components.queryItems = items
        return components.url ?? originalURL
    }
}

public extension CGSize {
    /// Maximum size of avatar used in the UI.
    ///
    /// It's better to use single size of avatar thumbnail to utilise the cache.
    static var avatarThumbnailSize: CGSize { CGSize(width: 40, height: 40) }
}
