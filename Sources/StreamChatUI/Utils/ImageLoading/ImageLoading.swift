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
    
    /// Load an image into an imageView from the given URL
    /// - Parameters:
    ///   - imageView: The `UIImageView` object in which the image should be loaded
    ///   - url: The `URL` from which the image is to be loaded
    ///   - imageCDN: The `ImageCDN`object which is to be used
    ///   - placeholder: The placeholder `UIImage` to be used
    ///   - resize: Whether to resize the image or not
    ///   - preferredSize: The preferred size of the image to be loaded
    ///   - completion: Completion that gets called when the download is finished
    @discardableResult
    func loadImage(
        into imageView: UIImageView,
        url: URL?,
        imageCDN: ImageCDN,
        placeholder: UIImage?,
        resize: Bool,
        preferredSize: CGSize?,
        completion: ((_ result: Result<UIImage, Error>) -> Void)?
    ) -> Cancellable?
}

public extension ImageLoading {
    @discardableResult
    func loadImage(
        into imageView: UIImageView,
        url: URL?,
        imageCDN: ImageCDN,
        placeholder: UIImage? = nil,
        resize: Bool = true,
        preferredSize: CGSize? = nil,
        completion: ((_ result: Result<UIImage, Error>) -> Void)? = nil
    ) -> Cancellable? {
        loadImage(
            into: imageView,
            url: url,
            imageCDN: imageCDN,
            placeholder: placeholder,
            resize: resize,
            preferredSize: preferredSize,
            completion: completion
        )
    }
}
