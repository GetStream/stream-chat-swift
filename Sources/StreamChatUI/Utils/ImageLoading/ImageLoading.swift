//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// ImageLoading is providing set of functions for downloading of images from URLs.
public protocol ImageLoading: AnyObject {
    /// Load an image from using the given URL request
    /// - Parameters:
    ///   - urlRequest: The `URLRequest` object used to fetch the image
    ///   - cachingKey: The key to be used for caching this image
    ///   - completion: Completion that gets called when the download is finished
    @discardableResult
    func loadImage(
        using urlRequest: URLRequest,
        cachingKey: String?,
        completion: @escaping ((_ result: Result<UIImage, Error>) -> Void)
    ) -> Cancellable?
}
