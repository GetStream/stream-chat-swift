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
    open func loadImage(
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
    open func downloadImage(
        from url: URL,
        with options: ImageDownloadOptions = ImageDownloadOptions(),
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

    open func downloadMultipleImages(
        from urlsAndOptions: [(url: URL, options: ImageDownloadOptions)],
        completion: @escaping (([Result<UIImage, Error>]) -> Void)
    ) {
        let group = DispatchGroup()
        var results: [Result<UIImage, Error>] = []

        for (url, downloadOptions) in urlsAndOptions {
            group.enter()

            downloadImage(from: url, with: downloadOptions) { result in
                results.append(result)

                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(results)
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
