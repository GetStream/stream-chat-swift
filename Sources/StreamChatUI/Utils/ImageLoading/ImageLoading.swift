//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// Cancellable provides a set of functions that enable cancelling a task
public protocol Cancellable {
    func cancel()
}

/// ImageLoading is providing set of functions for downloading of images from URLs.
public protocol ImageLoading: AnyObject {
    /// Load an image from the given URL
    /// - Parameters:
    ///   - url: The URL of the image
    ///   - resize: Whether the image should be resized
    ///   - preferredSize: The preferred size of the image to be downloaded
    ///   - completion: Completion that gets called when the download is finished
    @discardableResult
    func loadImage(
        from url: URL,
        resize: Bool,
        preferredSize: CGSize?,
        completion: @escaping ((_ result: Result<UIImage, Error>) -> Void)
    ) -> Cancellable?
}
