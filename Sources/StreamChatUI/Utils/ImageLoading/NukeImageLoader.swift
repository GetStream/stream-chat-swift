//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension ImageTask: Cancellable {}

/// The class which is responsible for loading images from URLs.
/// Internally uses `Nuke`'s shared object of `ImagePipeline` to load the image.
open class NukeImageLoader: ImageLoading {
    public init() {}

    open var avatarThumbnailSize: CGSize {
        Components.default.avatarThumbnailSize
    }

    open var imageCDN: ImageCDN {
        Components.default.imageCDN
    }

    @discardableResult
    public func loadImage(
        into imageView: UIImageView,
        from url: URL?,
        with options: ImageLoaderOptions,
        completion: ((Result<UIImage, Error>) -> Void)?
    ) -> Cancellable? {
        imageView.currentImageLoadingTask?.cancel()

        guard let url = url else {
            imageView.image = options.placeholder
            return nil
        }

        let urlRequest = imageCDN.urlRequest(forImageUrl: url, resize: options.resize)
        let cachingKey = imageCDN.cachingKey(forImageUrl: url)

        var processors: [ImageProcessing] = []
        if let resize = options.resize {
            let cgSize = CGSize(width: resize.width, height: resize.height)
            processors.append(ImageProcessors.Resize(size: cgSize))
        }

        let request = ImageRequest(
            urlRequest: urlRequest,
            processors: processors,
            userInfo: [.imageIdKey: cachingKey]
        )

        let nukeOptions = ImageLoadingOptions(placeholder: options.placeholder)
        imageView.currentImageLoadingTask = StreamChatUI.loadImage(
            with: request,
            options: nukeOptions,
            into: imageView
        ) { result in
            switch result {
            case let .success(imageResponse):
                completion?(.success(imageResponse.image))
            case let .failure(error):
                completion?(.failure(error))
            }
        }

        return imageView.currentImageLoadingTask
    }

    @discardableResult
    public func downloadImage(
        from url: URL,
        with options: ImageDownloadOptions,
        completion: @escaping ((Result<UIImage, Error>) -> Void)
    ) -> Cancellable? {
        let urlRequest = imageCDN.urlRequest(forImageUrl: url, resize: options.resize)
        let cachingKey = imageCDN.cachingKey(forImageUrl: url)

        var processors: [ImageProcessing] = []
        if let resize = options.resize {
            let cgSize = CGSize(width: resize.width, height: resize.height)
            processors.append(ImageProcessors.Resize(size: cgSize))
        }

        let request = ImageRequest(
            urlRequest: urlRequest,
            processors: processors,
            userInfo: [.imageIdKey: cachingKey]
        )

        let imageTask = ImagePipeline.shared.loadImage(with: request) { result in
            switch result {
            case let .success(imageResponse):
                completion(.success(imageResponse.image))
            case let .failure(error):
                completion(.failure(error))
            }
        }

        return imageTask
    }

    public func loadMultipleImages(
        from urls: [(URL, ImageLoaderOptions)],
        completion: @escaping (([UIImage]) -> Void)
    ) {
        let group = DispatchGroup()
        var images: [UIImage] = []

        for (url, loaderOptions) in urls {
            var placeholderIndex = 0

            group.enter()

            let downloadOptions = ImageDownloadOptions(resize: loaderOptions.resize)
            downloadImage(from: url, with: downloadOptions) { result in
                switch result {
                case let .success(image):
                    images.append(image)
                case .failure:
                    let placeholders = urls.map(\.1).compactMap(\.placeholder)
                    if !placeholders.isEmpty {
                        // Rotationally use the placeholders
                        images.append(placeholders[placeholderIndex])
                        placeholderIndex += 1
                        if placeholderIndex == placeholders.count {
                            placeholderIndex = 0
                        }
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(images)
        }
    }
}

private extension UIImageView {
    static var nukeLoadingTaskKey: UInt8 = 0

    var currentImageLoadingTask: ImageTask? {
        get { objc_getAssociatedObject(self, &Self.nukeLoadingTaskKey) as? ImageTask }
        set { objc_setAssociatedObject(self, &Self.nukeLoadingTaskKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
