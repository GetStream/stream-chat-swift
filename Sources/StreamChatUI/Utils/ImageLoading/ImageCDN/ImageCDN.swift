//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
