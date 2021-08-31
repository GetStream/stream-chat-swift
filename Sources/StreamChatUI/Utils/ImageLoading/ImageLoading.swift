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
    
    /// Load images from a given URLs
    /// - Parameters:
    ///   - urls: The URLs to load the images from
    ///   - placeholders: The placeholder images. Placeholders are used when an image fails to load from a URL. The placeholders are used rotationally
    ///   - loadThumbnails: Should load the images as thumbnails. If this is set to `true`, the thumbnail URL is derived from the `imageCDN` object
    ///   - thumbnailSize: The size of the thumbnail. This parameter is used only if the `loadThumbnails` parameter is true
    ///   - imageCDN: The imageCDN to be used
    ///   - completion: Completion that gets called when all the images finish downloading
    func loadImages(
        from urls: [URL],
        placeholders: [UIImage],
        loadThumbnails: Bool,
        thumbnailSize: CGSize,
        imageCDN: ImageCDN,
        completion: @escaping (([UIImage]) -> Void)
    )
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
    
    func loadImages(
        from urls: [URL],
        placeholders: [UIImage],
        loadThumbnails: Bool = true,
        thumbnailSize: CGSize = .avatarThumbnailSize,
        imageCDN: ImageCDN,
        completion: @escaping (([UIImage]) -> Void)
    ) {
        loadImages(
            from: urls,
            placeholders: placeholders,
            loadThumbnails: loadThumbnails,
            thumbnailSize: thumbnailSize,
            imageCDN: imageCDN,
            completion: completion
        )
    }
}
