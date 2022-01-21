//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension ImageTask: Cancellable {}

/// The class which is resposible for loading images from URLs.
/// Internally uses `Nuke`'s shared object of `ImagePipeline` to load the image.
open class NukeImageLoader: ImageLoading {
    public init() {}

    @discardableResult
    open func loadImage(
        using urlRequest: URLRequest,
        cachingKey: String?,
        completion: @escaping ((Result<UIImage, Error>) -> Void)
    ) -> Cancellable? {
        var userInfo: [ImageRequest.UserInfoKey: Any]?
        if let cachingKey = cachingKey {
            userInfo = [.imageIdKey: cachingKey]
        }
        
        let request = ImageRequest(
            urlRequest: urlRequest,
            userInfo: userInfo
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
    
    open func loadImages(
        from urls: [URL],
        placeholders: [UIImage],
        loadThumbnails: Bool,
        thumbnailSize: CGSize,
        imageCDN: ImageCDN,
        completion: @escaping (([UIImage]) -> Void)
    ) {
        let group = DispatchGroup()
        var images: [UIImage] = []
        
        for avatarUrl in urls {
            var placeholderIndex = 0
            
            let thumbnailUrl = imageCDN.thumbnailURL(originalURL: avatarUrl, preferredSize: .avatarThumbnailSize)
            let imageRequest = imageCDN.urlRequest(forImage: thumbnailUrl)
            let cachingKey = imageCDN.cachingKey(forImage: avatarUrl)

            group.enter()

            loadImage(using: imageRequest, cachingKey: cachingKey) { result in
                switch result {
                case let .success(image):
                    images.append(image)
                case .failure:
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
    
    @discardableResult
    open func loadImage(
        into imageView: UIImageView,
        url: URL?,
        imageCDN: ImageCDN,
        placeholder: UIImage?,
        resize: Bool = true,
        preferredSize: CGSize? = nil,
        completion: ((_ result: Result<UIImage, Error>) -> Void)? = nil
    ) -> Cancellable? {
        imageView.currentImageLoadingTask?.cancel()

        guard var url = url else {
            imageView.image = placeholder
            return nil
        }

        let urlRequest = imageCDN.urlRequest(forImage: url)
        let size = preferredSize ?? .zero
        let canResize = resize && size != .zero

        // If we don't have a valid size, we will not be able to resize using our CDN.
        if canResize {
            url = imageCDN.thumbnailURL(originalURL: url, preferredSize: size)
        }

        // At this point, if the image will be resized using our CDN, the url will contain the size values as
        // parameters, and this will create a unique caching key for that url with this size. Only in this case we can
        // successfully cache the resized image.
        let cachingKey = imageCDN.cachingKey(forImage: url)

        // If we don't have a size, we cannot properly create a 1:1 matching between a caching key and the resized image
        // that LateResize will create. Therefore, we use/cache the original resolution image.
        let processors: [ImageProcessing] = canResize
            ? [ImageProcessors.LateResize(id: cachingKey, sizeProvider: { imageView.bounds.size })]
            : []

        let request = ImageRequest(urlRequest: urlRequest, processors: processors, userInfo: [.imageIdKey: cachingKey])
        let options = ImageLoadingOptions(placeholder: placeholder)
        imageView.currentImageLoadingTask = StreamChatUI.loadImage(
            with: request,
            options: options,
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
}

private extension UIImageView {
    static var nukeLoadingTaskKey: UInt8 = 0

    var currentImageLoadingTask: ImageTask? {
        get { objc_getAssociatedObject(self, &Self.nukeLoadingTaskKey) as? ImageTask }
        set { objc_setAssociatedObject(self, &Self.nukeLoadingTaskKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
