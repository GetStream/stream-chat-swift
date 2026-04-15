//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The default image loader implementation.
///
/// Delegates URL transformation to the ``CDNRequester`` provided via
/// ``ImageLoadOptions``, and actual downloading to an ``ImageDownloading``
/// backend (typically Nuke, supplied by each UI SDK).
open class StreamImageLoader: ImageLoader, @unchecked Sendable {
    /// The backend that performs the actual image download and caching.
    public let downloader: ImageDownloading

    public init(downloader: ImageDownloading) {
        self.downloader = downloader
    }

    open func loadImage(
        url: URL?,
        options: ImageLoadOptions,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        guard let url else {
            StreamConcurrency.onMain {
                completion(.failure(ClientError.Unknown()))
            }
            return
        }

        options.cdnRequester.imageRequest(for: url, options: ImageRequestOptions(imageResize: options.resize)) { [weak self] result in
            switch result {
            case let .success(cdnRequest):
                let resizeSize: CGSize? = options.resize.map { CGSize(width: $0.width, height: $0.height) }
                self?.downloader.downloadImage(
                    url: cdnRequest.url,
                    headers: cdnRequest.headers,
                    cachingKey: cdnRequest.cachingKey,
                    resize: resizeSize,
                    completion: completion
                )
            case let .failure(error):
                StreamConcurrency.onMain {
                    completion(.failure(error))
                }
            }
        }
    }

    open func loadImages(
        from urls: [URL],
        options: ImageBatchLoadOptions,
        completion: @escaping @MainActor ([UIImage]) -> Void
    ) {
        let group = DispatchGroup()
        let batchLoadingResult = ImageBatchLoadingResult()

        for (index, avatarUrl) in urls.enumerated() {
            group.enter()

            let resize: ImageResize? = options.loadThumbnails ? ImageResize(options.thumbnailSize) : nil
            let imageOptions = ImageLoadOptions(resize: resize, cdnRequester: options.cdnRequester)
            loadImage(url: avatarUrl, options: imageOptions) { result in
                switch result {
                case let .success(image):
                    batchLoadingResult.images.append(image)
                case .failure:
                    if !options.placeholders.isEmpty {
                        let placeholderIndex = index % options.placeholders.count
                        batchLoadingResult.images.append(options.placeholders[placeholderIndex])
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            StreamConcurrency.onMain {
                completion(batchLoadingResult.images)
            }
        }
    }
}

private final class ImageBatchLoadingResult: @unchecked Sendable {
    var images: [UIImage] = []
}
