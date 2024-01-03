//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

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
