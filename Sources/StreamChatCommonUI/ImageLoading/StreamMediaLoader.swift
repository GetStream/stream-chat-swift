//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// The default ``MediaLoader`` implementation.
///
/// Delegates URL transformation to the ``CDNRequester`` provided via options,
/// image downloading to an ``ImageDownloading`` backend (typically Nuke),
/// and video preview generation to AVFoundation.
open class StreamMediaLoader: MediaLoader, @unchecked Sendable {
    /// The backend that performs the actual image download and caching.
    public let downloader: ImageDownloading

    private let videoPreviewCache: NSCache<NSURL, UIImage>

    public init(downloader: ImageDownloading, videoPreviewCacheCountLimit: Int = 50) {
        self.downloader = downloader
        self.videoPreviewCache = NSCache<NSURL, UIImage>()
        self.videoPreviewCache.countLimit = videoPreviewCacheCountLimit

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning(_:)),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Image Loading

    open func loadImage(
        url: URL?,
        options: ImageLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderImage, Error>) -> Void
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
                let downloadOptions = ImageDownloadingOptions(
                    headers: cdnRequest.headers,
                    cachingKey: cdnRequest.cachingKey,
                    resize: resizeSize
                )
                self?.downloader.downloadImage(url: cdnRequest.url, options: downloadOptions) { imageResult in
                    completion(imageResult.map { MediaLoaderImage(image: $0.image) })
                }
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
        completion: @escaping @MainActor ([MediaLoaderImage]) -> Void
    ) {
        let group = DispatchGroup()
        let batchResult = BatchLoadingResult()

        for (index, avatarUrl) in urls.enumerated() {
            group.enter()

            let resize: ImageResize? = options.loadThumbnails ? ImageResize(options.thumbnailSize) : nil
            let imageOptions = ImageLoadOptions(resize: resize, cdnRequester: options.cdnRequester)
            loadImage(url: avatarUrl, options: imageOptions) { result in
                switch result {
                case let .success(loaded):
                    batchResult.images.append(loaded)
                case .failure:
                    if !options.placeholders.isEmpty {
                        let placeholderIndex = index % options.placeholders.count
                        batchResult.images.append(MediaLoaderImage(image: options.placeholders[placeholderIndex]))
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            StreamConcurrency.onMain {
                completion(batchResult.images)
            }
        }
    }

    // MARK: - Video Loading

    open func videoAsset(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoAsset, Error>) -> Void
    ) {
        options.cdnRequester.fileRequest(for: url, options: .init()) { result in
            switch result {
            case let .success(cdnRequest):
                let asset = AVURLAsset(url: cdnRequest.url)
                StreamConcurrency.onMain {
                    completion(.success(MediaLoaderVideoAsset(asset: asset)))
                }
            case let .failure(error):
                StreamConcurrency.onMain {
                    completion(.failure(error))
                }
            }
        }
    }

    open func loadVideoPreview(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        if let cached = videoPreviewCache.object(forKey: url as NSURL) {
            StreamConcurrency.onMain {
                completion(.success(MediaLoaderVideoPreview(image: cached)))
            }
            return
        }

        generateVideoPreview(for: url, options: options, completion: completion)
    }

    open func loadVideoPreview(
        with attachment: ChatMessageVideoAttachment,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        let videoURL = attachment.videoURL
        if let cached = videoPreviewCache.object(forKey: videoURL as NSURL) {
            StreamConcurrency.onMain {
                completion(.success(MediaLoaderVideoPreview(image: cached)))
            }
            return
        }

        if let thumbnailURL = attachment.payload.thumbnailURL {
            let imageOptions = ImageLoadOptions(cdnRequester: options.cdnRequester)
            loadImage(url: thumbnailURL, options: imageOptions) { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(loaded):
                    self.videoPreviewCache.setObject(loaded.image, forKey: videoURL as NSURL)
                    StreamConcurrency.onMain {
                        completion(.success(MediaLoaderVideoPreview(image: loaded.image)))
                    }
                case .failure:
                    self.generateVideoPreview(for: videoURL, options: options, completion: completion)
                }
            }
        } else {
            generateVideoPreview(for: videoURL, options: options, completion: completion)
        }
    }

    // MARK: - Private

    private func generateVideoPreview(
        for url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        options.cdnRequester.fileRequest(for: url, options: .init()) { [weak self] result in
            guard let self else { return }

            let adjustedUrl: URL
            switch result {
            case let .success(cdnRequest):
                adjustedUrl = cdnRequest.url
            case let .failure(error):
                StreamConcurrency.onMain {
                    completion(.failure(error))
                }
                return
            }

            let asset = AVURLAsset(url: adjustedUrl)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            let frameTime = CMTime(seconds: 0.1, preferredTimescale: 600)

            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.generateCGImagesAsynchronously(forTimes: [.init(time: frameTime)]) { [weak self] _, image, _, _, error in
                guard let self else { return }

                let result: Result<MediaLoaderVideoPreview, Error>
                if let thumbnail = image {
                    result = .success(MediaLoaderVideoPreview(image: UIImage(cgImage: thumbnail)))
                } else if let error {
                    result = .failure(error)
                } else {
                    result = .failure(ClientError.Unknown("Both error and image are nil"))
                    return
                }

                if let preview = try? result.get() {
                    self.videoPreviewCache.setObject(preview.image, forKey: url as NSURL)
                }
                StreamConcurrency.onMain {
                    completion(result)
                }
            }
        }
    }

    @objc private func handleMemoryWarning(_ notification: NSNotification) {
        videoPreviewCache.removeAllObjects()
    }
}

private final class BatchLoadingResult: @unchecked Sendable {
    var images: [MediaLoaderImage] = []
}
