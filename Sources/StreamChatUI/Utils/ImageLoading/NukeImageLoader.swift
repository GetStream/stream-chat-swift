//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import UIKit

extension ImageTask: Cancellable {}

/// The class which is resposible for loading images from URLs.
/// Internally uses `Nuke`'s shared object of `ImagePipeline` to load the image.
open class NukeImageLoader: ImageLoading {
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
        let cachingKey = imageCDN.cachingKey(forImage: url)
        
        let processors: [ImageProcessing] = resize
            ? [ImageProcessors.LateResize(sizeProvider: { imageView.bounds.size })]
            : []
        
        let size = preferredSize ?? imageView.bounds.size
        if resize && size != .zero {
            url = imageCDN.thumbnailURL(originalURL: url, preferredSize: size)
        }
        
        let request = ImageRequest(
            urlRequest: urlRequest,
            processors: processors,
            userInfo: [.imageIdKey: cachingKey]
        )
        
        let options = ImageLoadingOptions(placeholder: placeholder)
        imageView.currentImageLoadingTask = Nuke.loadImage(
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
