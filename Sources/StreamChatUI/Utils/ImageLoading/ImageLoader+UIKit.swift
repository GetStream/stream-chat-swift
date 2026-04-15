//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import UIKit

extension ImageLoader {
    /// Loads an image into a UIImageView with the given options.
    @discardableResult
    @MainActor public func loadImage(
        into imageView: UIImageView,
        from url: URL?,
        with options: ImageLoaderOptions,
        completion: (@MainActor (Result<UIImage, Error>) -> Void)? = nil
    ) -> ImageLoadingTask {
        let task = ImageLoadingTask()
        imageView.currentImageLoadingTask?.cancel()

        guard let url else {
            imageView.image = options.placeholder
            return task
        }

        imageView.currentImageLoadingTask = task

        let loadOptions = ImageLoadOptions(resize: options.resize, cdnRequester: options.cdnRequester)
        loadImage(url: url, options: loadOptions) { result in
            guard !task.isCancelled else { return }
            switch result {
            case let .success(image):
                imageView.image = image
                completion?(.success(image))
            case let .failure(error):
                completion?(.failure(error))
            }
        }

        return task
    }

    /// Downloads an image with the given request options.
    public func downloadImage(
        with request: ImageDownloadRequest,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        let loadOptions = ImageLoadOptions(resize: request.options.resize, cdnRequester: request.options.cdnRequester)
        loadImage(url: request.url, options: loadOptions, completion: completion)
    }

    /// Downloads multiple images and returns all results.
    public func downloadMultipleImages(
        with requests: [ImageDownloadRequest],
        completion: @escaping @MainActor ([Result<UIImage, Error>]) -> Void
    ) {
        let group = DispatchGroup()
        let batchResult = ImageBatchResult(count: requests.count)

        for (index, request) in requests.enumerated() {
            group.enter()
            downloadImage(with: request) { result in
                batchResult.results[index] = result
                group.leave()
            }
        }

        if group.wait(timeout: .now()) == .success {
            StreamConcurrency.onMain {
                completion(batchResult.results)
            }
        } else {
            group.notify(queue: .main) {
                StreamConcurrency.onMain {
                    completion(batchResult.results)
                }
            }
        }
    }

    /// Loads an image from an `ImageAttachmentPayload`, using resolution metadata for optimal sizing.
    @discardableResult
    @MainActor public func loadImage(
        into imageView: UIImageView,
        from attachmentPayload: ImageAttachmentPayload?,
        maxResolutionInPixels: Double,
        cdnRequester: CDNRequester,
        completion: (@MainActor (Result<UIImage, Error>) -> Void)? = nil
    ) -> ImageLoadingTask {
        guard let originalWidth = attachmentPayload?.originalWidth,
              let originalHeight = attachmentPayload?.originalHeight else {
            return loadImage(
                into: imageView,
                from: attachmentPayload?.imageURL,
                with: ImageLoaderOptions(cdnRequester: cdnRequester),
                completion: completion
            )
        }

        let imageSizeCalculator = ImageSizeCalculator()
        let newSize = imageSizeCalculator.calculateSize(
            originalWidthInPixels: originalWidth,
            originalHeightInPixels: originalHeight,
            maxResolutionTotalPixels: maxResolutionInPixels
        )

        return loadImage(
            into: imageView,
            from: attachmentPayload?.imageURL,
            with: ImageLoaderOptions(resize: ImageResize(newSize), cdnRequester: cdnRequester),
            completion: completion
        )
    }
}

final class ImageBatchResult: @unchecked Sendable {
    var results: [Result<UIImage, Error>]
    init(count: Int) {
        results = Array(repeating: .failure(NSError(domain: NSURLErrorDomain, code: URLError.Code.unknown.rawValue)), count: count)
    }
}

/// A cancellable image loading task.
public class ImageLoadingTask: Cancellable, @unchecked Sendable {
    public private(set) var isCancelled = false

    public func cancel() {
        isCancelled = true
    }
}

private extension UIImageView {
    static var imageLoadingTaskKey: UInt8 = 0

    var currentImageLoadingTask: ImageLoadingTask? {
        get { objc_getAssociatedObject(self, &Self.imageLoadingTaskKey) as? ImageLoadingTask }
        set { objc_setAssociatedObject(self, &Self.imageLoadingTaskKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
