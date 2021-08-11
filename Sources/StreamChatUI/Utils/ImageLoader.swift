//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import UIKit

/// Cancellable provides a set of functions that enable cancelling a task
public protocol Cancellable {
    func cancel()
}

extension ImageTask: Cancellable {}

/// ImageLoading is providing set of functions for downloading of images from URLs.
public protocol ImageLoading: AnyObject {
    /// Load an image from the given URL
    /// - Parameters:
    ///   - url: The URL of the image
    ///   - imageCDN: The CDN to be used for downloading the image
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

/// The class which is resposible for loading images from URLs.
/// Internally uses `Nuke`'s shared object of `ImagePipeline` to load the image.
open class DefaultImageLoader: ImageLoading {
    /// The CDN to be used
    open var imageCDN: ImageCDN
    
    public init(imageCDN: ImageCDN) {
        self.imageCDN = imageCDN
    }
    
    @discardableResult
    open func loadImage(
        from url: URL,
        resize: Bool = true,
        preferredSize: CGSize? = .avatarThumbnailSize,
        completion: @escaping ((Result<UIImage, Error>) -> Void)
    ) -> Cancellable? {
        guard !SystemEnvironment.isTests else {
            // When running tests, we load the images synchronously
            let image = UIImage(data: try! Data(contentsOf: url))!
            completion(.success(image))
            return nil
        }

        var imageUrl = url
        let size = preferredSize ?? .zero
        if resize && size != .zero {
            imageUrl = imageCDN.thumbnailURL(originalURL: url, preferredSize: size)
        }
        
        let imageKey = imageCDN.cachingKey(forImage: imageUrl)
        let urlRequest = imageCDN.urlRequest(forImage: imageUrl)
        let request = ImageRequest(
            urlRequest: urlRequest,
            options: ImageRequestOptions(filteredURL: imageKey)
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
}
