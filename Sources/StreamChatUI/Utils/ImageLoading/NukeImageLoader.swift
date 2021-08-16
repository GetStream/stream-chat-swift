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
        guard !SystemEnvironment.isTests else {
            // When running tests, we load the images synchronously
            let image = UIImage(data: try! Data(contentsOf: urlRequest.url!))!
            completion(.success(image))
            return nil
        }

        let request = ImageRequest(
            urlRequest: urlRequest,
            options: ImageRequestOptions(filteredURL: cachingKey)
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
