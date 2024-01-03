//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A protocol that provides a set of functions for loading images.
public protocol ImageLoading: AnyObject {
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

    /// Load an image into an imageView from a given `ImageAttachmentPayload`.
    /// - Parameters:
    ///   - imageView: The image view where the image will be loaded.
    ///   - attachmentPayload: The image attachment payload.
    ///   - maxResolutionInPixels: The maximum number of pixels the loaded image should have.
    ///   - completion: The completion when the loading is finished.
    /// - Returns: A cancellable task.
    @discardableResult
    func loadImage(
        into imageView: UIImageView,
        from attachmentPayload: ImageAttachmentPayload?,
        maxResolutionInPixels: Double,
        completion: ((_ result: Result<UIImage, Error>) -> Void)?
    ) -> Cancellable?

    /// Download an image from the given `URL`.
    /// - Parameters:
    ///   - request: The url and options information of an image download request.
    ///   - completion: The completion when the loading is finished.
    /// - Returns: A cancellable task.
    @discardableResult
    func downloadImage(
        with request: ImageDownloadRequest,
        completion: @escaping ((_ result: Result<UIImage, Error>) -> Void)
    ) -> Cancellable?

    /// Load a batch of images and get notified when all of them complete loading.
    /// - Parameters:
    ///   - requests: The urls and options information of each image download request.
    ///   - completion: The completion when the loading is finished.
    ///   It returns an array of image and errors in case the image failed to load.
    func downloadMultipleImages(
        with requests: [ImageDownloadRequest],
        completion: @escaping (([Result<UIImage, Error>]) -> Void)
    )

    // MARK: - Deprecations

    @available(*, deprecated, message: "use downloadImage() instead.")
    @discardableResult
    func loadImage(
        using urlRequest: URLRequest,
        cachingKey: String?,
        completion: @escaping ((_ result: Result<UIImage, Error>) -> Void)
    ) -> Cancellable?

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

// MARK: - Image Attachment Helper API

public extension ImageLoading {
    @discardableResult
    func loadImage(
        into imageView: UIImageView,
        from attachmentPayload: ImageAttachmentPayload?,
        maxResolutionInPixels: Double,
        completion: ((_ result: Result<UIImage, Error>) -> Void)?
    ) -> Cancellable? {
        guard let originalWidth = attachmentPayload?.originalWidth,
              let originalHeight = attachmentPayload?.originalHeight else {
            return loadImage(
                into: imageView,
                from: attachmentPayload?.imageURL,
                with: ImageLoaderOptions(),
                completion: completion
            )
        }

        let imageSizeCalculator = ImageSizeCalculator()
        let newSize = imageSizeCalculator.calculateSize(
            originalWidthInPixels: originalWidth,
            originalHeightInPixels: originalHeight,
            maxResolutionTotalPixels: maxResolutionInPixels
        )

        return loadImage(
            into: imageView,
            from: attachmentPayload?.imageURL,
            with: ImageLoaderOptions(resize: .init(newSize)),
            completion: completion
        )
    }

    @discardableResult
    func loadImage(
        into imageView: UIImageView,
        from attachmentPayload: ImageAttachmentPayload?,
        maxResolutionInPixels: Double
    ) -> Cancellable? {
        loadImage(
            into: imageView,
            from: attachmentPayload,
            maxResolutionInPixels: maxResolutionInPixels,
            completion: nil
        )
    }
}

// MARK: - Default Parameters

public extension ImageLoading {
    @discardableResult
    func loadImage(
        into imageView: UIImageView,
        from url: URL?
    ) -> Cancellable? {
        loadImage(into: imageView, from: url, with: ImageLoaderOptions(), completion: nil)
    }

    @discardableResult
    func loadImage(
        into imageView: UIImageView,
        from url: URL?,
        with options: ImageLoaderOptions
    ) -> Cancellable? {
        loadImage(into: imageView, from: url, with: options, completion: nil)
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
            with: ImageDownloadRequest(url: url, options: ImageDownloadOptions()),
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
                resize: preferredSize.map { ImageResize($0) },
                placeholder: placeholder
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
        let requests = urls.map { url in
            ImageDownloadRequest(url: url, options: .init(resize: .init(thumbnailSize)))
        }

        downloadMultipleImages(with: requests) { results in
            let imagesMapper = ImageResultsMapper(results: results)
            let images = imagesMapper.mapErrors(with: placeholders)
            completion(images)
        }
    }
}
