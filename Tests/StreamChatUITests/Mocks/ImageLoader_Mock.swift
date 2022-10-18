//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import UIKit

/// A mock implementation of the image loader which loads images synchronusly
final class ImageLoader_Mock: ImageLoading {
    func downloadImage(from url: URL, with options: ImageDownloadOptions, completion: @escaping ((Result<UIImage, Error>) -> Void)) -> Cancellable? {
        let image = UIImage(data: try! Data(contentsOf: url))!
        completion(.success(image))
        return nil
    }

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

    func loadMultipleImages(from urls: [(URL, ImageLoaderOptions)], completion: @escaping (([UIImage]) -> Void)) {
        let images = urls.map(\.0).map { UIImage(data: try! Data(contentsOf: $0))! }
        completion(images)
    }
}
