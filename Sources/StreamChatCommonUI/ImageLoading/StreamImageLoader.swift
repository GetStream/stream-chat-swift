//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The default image loader implementation.
///
/// Uses the provided ``CDNRequester`` to transform image URLs before loading,
/// and delegates actual downloading to an ``ImageDownloading`` backend
/// (typically Nuke, supplied by each UI SDK).
open class StreamImageLoader: ImageLoader, @unchecked Sendable {
    /// The CDN requester used for URL transformation before image loading.
    public let cdnRequester: CDNRequester
    /// The backend that performs the actual image download and caching.
    public let downloader: ImageDownloading

    public init(cdnRequester: CDNRequester = StreamCDNRequester(), downloader: ImageDownloading) {
        self.cdnRequester = cdnRequester
        self.downloader = downloader
    }

    open func loadImage(
        url: URL?,
        resize: ImageResize?,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        guard let url else {
            StreamConcurrency.onMain {
                completion(.failure(ClientError.Unknown()))
            }
            return
        }

        cdnRequester.imageRequest(for: url, options: ImageRequestOptions(imageResize: resize)) { [weak self] result in
            switch result {
            case let .success(cdnRequest):
                let resizeSize: CGSize? = resize.map { CGSize(width: $0.width, height: $0.height) }
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
        placeholders: [UIImage],
        loadThumbnails: Bool,
        thumbnailSize: CGSize,
        completion: @escaping @MainActor ([UIImage]) -> Void
    ) {
        let group = DispatchGroup()
        let batchLoadingResult = ImageBatchLoadingResult()

        for (index, avatarUrl) in urls.enumerated() {
            group.enter()

            let resize: ImageResize? = loadThumbnails ? ImageResize(thumbnailSize) : nil
            loadImage(url: avatarUrl, resize: resize) { result in
                switch result {
                case let .success(image):
                    batchLoadingResult.images.append(image)
                case .failure:
                    if !placeholders.isEmpty {
                        let placeholderIndex = index % placeholders.count
                        batchLoadingResult.images.append(placeholders[placeholderIndex])
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
