//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The default image loader implementation.
///
/// Uses the provided ``CDN`` to transform image URLs before loading,
/// and delegates actual downloading to an ``ImageDownloading`` backend
/// (typically Nuke, supplied by each UI SDK).
open class StreamImageLoader: ImageLoader, @unchecked Sendable {
    /// The CDN used for URL transformation before image loading.
    public let cdn: CDN
    /// The backend that performs the actual image download and caching.
    public let downloader: ImageDownloading

    public init(cdn: CDN = StreamCDN(), downloader: ImageDownloading) {
        self.cdn = cdn
        self.downloader = downloader
    }

    open func loadImage(
        url: URL?,
        resize: ImageResize?,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        guard let url else {
            Task { @MainActor in
                completion(.failure(ClientError.Unknown()))
            }
            return
        }

        cdn.imageRequest(for: url, resize: resize) { [weak self] result in
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
                Task { @MainActor in
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
        final class BatchLoadingResult: @unchecked Sendable {
            var images: [UIImage] = []
        }
        let batchLoadingResult = BatchLoadingResult()

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
            Task { @MainActor in
                completion(batchLoadingResult.images)
            }
        }
    }
}
