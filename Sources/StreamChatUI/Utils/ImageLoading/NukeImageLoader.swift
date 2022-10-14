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

            let imageRequest = imageCDN.urlRequest(forImageUrl: avatarUrl, resize: .init(thumbnailSize))
            let cachingKey = imageCDN.cachingKey(forImageUrl: avatarUrl)

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

        guard let url = url else {
            imageView.image = placeholder
            return nil
        }

        let size = preferredSize ?? imageView.bounds.size
        let processors: [ImageProcessing] = size != .zero
            ? [ImageProcessors.Resize(size: size)]
            : []

        let cachingKey = imageCDN.cachingKey(forImageUrl: url)
        let urlRequest = imageCDN.urlRequest(forImageUrl: url, resize: .init(size))
        let request = ImageRequest(
            urlRequest: urlRequest,
            processors: processors,
            userInfo: [.imageIdKey: cachingKey]
        )
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
