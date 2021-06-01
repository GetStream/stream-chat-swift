//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// ImageCDN is providing set of functions to improve handling of images from CDN.
public protocol ImageCDN {
    /// Customised (filtered) key for image cache.
    /// - Parameter imageURL: URL of the image that should be customised (filtered).
    /// - Returns: String to be used as an image cache key.
    func cachingKey(forImage url: URL) -> String
    
    /// Enhance image URL with size parameters to get thumbnail
    /// - Parameters:
    ///   - originalURL: URL of the image to get the thumbnail for.
    ///   - preferredSize: The requested thumbnail size.
    ///
    /// Use view size in points for `preferredSize`, point to pixel ratio (scale) of the device is applied inside of this function.
    func thumbnailURL(originalURL: URL, preferredSize: CGSize) -> URL
}

public struct StreamImageCDN: ImageCDN {
    public static var streamCDNURL = "stream-io-cdn.com"
    
    public func cachingKey(forImage url: URL) -> String {
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
    
    public func thumbnailURL(originalURL: URL, preferredSize: CGSize) -> URL {
        guard
            var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: true),
            let host = components.host,
            host.contains(StreamImageCDN.streamCDNURL)
        else { return originalURL }

        let scale = UIScreen.main.scale
        components.queryItems = components.queryItems ?? []
        components.queryItems?.append(contentsOf: [
            URLQueryItem(name: "w", value: String(format: "%.0f", preferredSize.width * scale)),
            URLQueryItem(name: "h", value: String(format: "%.0f", preferredSize.height * scale)),
            URLQueryItem(name: "crop", value: "center"),
            URLQueryItem(name: "resize", value: "fill"),
            URLQueryItem(name: "ro", value: "0") // Required parameter.
        ])
        return components.url ?? originalURL
    }
}

public extension CGSize {
    /// Maximum size of avatar used in the UI.
    ///
    /// It's better to use single size of avatar thumbnail to utilise the cache.
    static var avatarThumbnailSize: CGSize { CGSize(width: 40, height: 40) }
}
