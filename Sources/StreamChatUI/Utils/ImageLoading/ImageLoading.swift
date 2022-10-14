//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// A protocol that provides a set of functions for loading images.
public protocol ImageLoading: AnyObject {
    /// Download an image from the given `URL`.
    /// - Parameters:
    ///   - url: The `URL` of the image.
    ///   - options: The loading options on how to fetch the image.
    ///   - completion: The completion when the loading is finished.
    /// - Returns: A cancellable task.
    @discardableResult
    func downloadImage(
        from url: URL,
        with options: ImageDownloadOptions,
        completion: @escaping ((_ result: Result<UIImage, Error>) -> Void)
    ) -> Cancellable?

    /// Load an image into an imageView from the given `URL`.
    /// - Parameters:
    ///   - imageView: The image view where the image will be loaded.
    ///   - url: The `URL` of the image. If `nil` it will load the placeholder.
    ///   - options: The loading options on how to fetch the image.
    ///   - completion: The completion when the loading is finished.
    /// - Returns: A cancellable task.
    @discardableResult
    func loadImage(
        into imageView: UIImageView,
        from url: URL?,
        with options: ImageLoaderOptions,
        completion: ((_ result: Result<UIImage, Error>) -> Void)?
    ) -> Cancellable?

    /// Load a batch of images and get notified when all of them complete loading.
    /// - Parameters:
    ///   - urls: A tuple of urls and the options on how to fetch the image.
    ///   - completion: The completion when the loading is finished.
    func loadMultipleImages(
        from urls: [(URL, ImageLoaderOptions)],
        completion: @escaping (([UIImage]) -> Void)
    )

    // MARK: - Deprecations

    /// Load an image from using the given URL request
    /// - Parameters:
    ///   - urlRequest: The `URLRequest` object used to fetch the image
    ///   - cachingKey: The key to be used for caching this image
    ///   - completion: Completion that gets called when the download is finished
    @available(*, deprecated, message: "use downloadImage() instead.")
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
    @available(*, deprecated, message: "use loadImage(into:from:with:) instead.")
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
    @available(*, deprecated, message: "use loadMultipleImages() instead.")
    func loadImages(
        from urls: [URL],
        placeholders: [UIImage],
        loadThumbnails: Bool,
        thumbnailSize: CGSize,
        imageCDN: ImageCDN,
        completion: @escaping (([UIImage]) -> Void)
    )
}

// MARK: - Default Parameters

public extension ImageLoading {
    func downloadImage(
        from url: URL,
        with options: ImageDownloadOptions = .init(),
        completion: @escaping ((_ result: Result<UIImage, Error>) -> Void)
    ) -> Cancellable? {
        downloadImage(from: url, with: options, completion: completion)
    }

    func loadImage(
        into imageView: UIImageView,
        from url: URL?,
        with options: ImageLoaderOptions = .init(),
        completion: ((_ result: Result<UIImage, Error>) -> Void)? = nil
    ) -> Cancellable? {
        loadImage(into: imageView, from: url, with: options, completion: completion)
    }
}

// MARK: Deprecation fallbacks

public extension ImageLoading {
    @available(*, deprecated, message: "use downloadImage() instead.")
    func loadImage(
        using urlRequest: URLRequest,
        cachingKey: String?, completion: @escaping ((Result<UIImage, Error>) -> Void)
    ) -> Cancellable? {
        guard let url = urlRequest.url else {
            completion(.failure(NSError(domain: "io.getstream.imageDeprecation.invalidUrl", code: 1)))
            return nil
        }

        return downloadImage(
            from: url,
            with: ImageDownloadOptions(resize: nil),
            completion: completion
        )
    }

    @available(*, deprecated, message: "use loadImage(into:from:with:) instead.")
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
            from: url,
            with: ImageLoaderOptions(
                placeholder: placeholder,
                resize: preferredSize.map { ImageResize($0) }
            ),
            completion: completion
        )
    }

    @available(*, deprecated, message: "use loadMultipleImages() instead.")
    func loadImages(
        from urls: [URL],
        placeholders: [UIImage],
        loadThumbnails: Bool = true,
        thumbnailSize: CGSize = Components.default.avatarThumbnailSize,
        imageCDN: ImageCDN,
        completion: @escaping (([UIImage]) -> Void)
    ) {
        let options = placeholders.map {
            ImageLoaderOptions(
                placeholder: $0,
                resize: .init(thumbnailSize)
            )
        }

        let urls = zip(urls, options)
            .map { ($0.0, $0.1) }

        loadMultipleImages(from: urls, completion: completion)
    }
}
