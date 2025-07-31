//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import UIKit

/// A mock implementation of the image loader which loads images synchronusly
final class ImageLoader_Mock: ImageLoading {
    func loadImage(into imageView: UIImageView, from url: URL?, with options: ImageLoaderOptions, completion: (@MainActor @Sendable(Result<UIImage, Error>) -> Void)?) -> Cancellable? {
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
        completion: @escaping (@MainActor @Sendable(Result<UIImage, Error>) -> Void)
    ) -> Cancellable? {
        nonisolated(unsafe) var image = UIImage(data: try! Data(contentsOf: request.url))!
        
        if let resize = request.options.resize {
            let cgSize = CGSize(width: resize.width, height: resize.height)
            image = NukeImageProcessor().scale(image: image, to: cgSize)
        }
        StreamConcurrency.onMain {
            completion(.success(image))
        }
        return nil
    }

    func downloadMultipleImages(
        with requests: [ImageDownloadRequest],
        completion: @escaping (@MainActor @Sendable([Result<UIImage, Error>]) -> Void)
    ) {
        let results = requests
            .map { request in
                let image = UIImage(data: try! Data(contentsOf: request.url))!
                guard let resize = request.options.resize else { return image }
                let cgSize = CGSize(width: resize.width, height: resize.height)
                return NukeImageProcessor().scale(image: image, to: cgSize)
            }
            .map { Result<UIImage, Error>.success($0) }
        StreamConcurrency.onMain {
            completion(results)
        }
    }
}
