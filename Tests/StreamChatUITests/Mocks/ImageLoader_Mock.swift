//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import UIKit

/// A mock implementation of the image loader which loads images synchronusly
final class ImageLoader_Mock: ImageLoading {
    func loadImage(into imageView: UIImageView, from url: URL?, with options: ImageLoaderOptions, completion: ((Result<UIImage, Error>) -> Void)?) -> Cancellable? {
        if let url = url {
            let image = UIImage(data: try! Data(contentsOf: url))!
            imageView.image = image
            completion?(.success(image))
        } else {
            imageView.image = options.placeholder
        }

        return nil
    }
    
    func downloadImage(
        with request: ImageDownloadRequest,
        completion: @escaping ((Result<UIImage, Error>) -> Void)
    ) -> Cancellable? {
        let image = UIImage(data: try! Data(contentsOf: request.url))!
        completion(.success(image))
        return nil
    }

    func downloadMultipleImages(
        with requests: [ImageDownloadRequest],
        completion: @escaping (([Result<UIImage, Error>]) -> Void)
    ) {
        let results = requests.map(\.url).map {
            Result<UIImage, Error>.success(UIImage(data: try! Data(contentsOf: $0))!)
        }
        completion(results)
    }
}
