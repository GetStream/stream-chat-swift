//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// A protocol responsible to configure the image CDN by intercepting the image url requests.
public protocol ImageCDN {
    /// Intercept the image url request.
    ///
    /// This can be used to change the host of the CDN, adding HTTP Headers etc.
    /// If your custom CDN supports resizing capabilities, you can also make use of the `resize` parameter.
    ///
    /// - Parameters:
    ///   - url: The image url to be loaded.
    ///   - resize: The resize configuration of the image to be loaded, if resizing was provided.
    /// - Returns: An `URLRequest` that represents the image request.
    func urlRequest(forImageUrl url: URL, resize: ImageResize?) -> URLRequest

    /// The cachingKey for each image url.
    ///
    /// If the CDN has unique query parameters in the url like random IDs, it is important to remove
    /// those query parameters from it, otherwise it won't be able to load images from the cache,
    /// since the key will always be different. If the CDN supports resizing capabilities, it might have
    /// width and height query parameters, these ones you should not remove so that there are different
    /// caches for each size of the image.
    ///
    /// - Parameter imageURL: The URL of the loaded image.
    /// - Returns: A String to be used as an image cache key.
    func cachingKey(forImageUrl url: URL) -> String
}

open class StreamImageCDN: ImageCDN {
    public static var streamCDNURL = "stream-io-cdn.com"

    public init() {}

    open func urlRequest(forImageUrl url: URL, resize: ImageResize?) -> URLRequest {
        // In case it is not an image from Stream's CDN, don't do nothing.
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host, host.contains(StreamImageCDN.streamCDNURL) else {
            return URLRequest(url: url)
        }

        // If there is not resize, not need to add query parameters to the URL.
        guard let resize = resize else {
            return URLRequest(url: url)
        }

        let scale = UIScreen.main.scale
        var queryItems: [String: String] = [
            "w": resize.width == 0 ? "*" : String(format: "%.0f", resize.width * scale),
            "h": resize.height == 0 ? "*" : String(format: "%.0f", resize.height * scale),
            "resize": resize.mode.value,
            "ro": "0" // Required parameter.
        ]
        if let cropValue = resize.mode.cropValue {
            queryItems["crop"] = cropValue
        }

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
        return URLRequest(url: components.url ?? url)
    }

    open func cachingKey(forImageUrl url: URL) -> String {
        let key = url.absoluteString

        // In case it is not an image from Stream's CDN, don't do nothing.
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host, host.contains(StreamImageCDN.streamCDNURL) else {
            return key
        }

        let persistedParameters = ["w", "h", "resize", "crop"]

        let newParameters = components.queryItems?.filter { persistedParameters.contains($0.name) } ?? []
        components.queryItems = newParameters.isEmpty ? nil : newParameters
        return components.string ?? key
    }
}

public extension CGSize {
    static var avatarThumbnailSize: CGSize { CGSize(width: 40, height: 40) }
}
