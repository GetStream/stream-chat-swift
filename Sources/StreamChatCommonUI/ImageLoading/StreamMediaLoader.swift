//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// The default ``MediaLoader`` implementation.
///
/// Delegates URL transformation to its ``CDNRequester`` dependency,
/// image downloading to an ``ImageDownloading`` backend (typically Nuke),
/// and video preview generation to AVFoundation.
open class StreamMediaLoader: MediaLoader, @unchecked Sendable {
    /// The CDN requester used for URL transformation (signing, headers, resizing).
    public let cdnRequester: CDNRequester

    /// The backend that performs the actual image download and caching.
    public let downloader: ImageDownloading

    /// The video preview thumbnails local cache used for videos that
    /// don't have remote thumbnails available.
    private let videoPreviewCache: NSCache<NSURL, UIImage>
    /// The limit of the local  video preview thumbnails cache.
    private let videoPreviewCacheCountLimit: Int = 50

    public init(
        cdnRequester: CDNRequester = StreamCDNRequester(),
        downloader: ImageDownloading
    ) {
        self.cdnRequester = cdnRequester
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

        let downloader = self.downloader
        cdnRequester.imageRequest(for: url, options: ImageRequestOptions(imageResize: options.resize)) { result in
            switch result {
            case let .success(cdnRequest):
                let resizeSize: CGSize? = options.resize.map { CGSize(width: $0.width, height: $0.height) }
                let downloadOptions = ImageDownloadingOptions(
                    headers: cdnRequest.headers,
                    cachingKey: cdnRequest.cachingKey,
                    resize: resizeSize
                )
                let cachingKey = cdnRequest.cachingKey
                downloader.downloadImage(url: cdnRequest.url, options: downloadOptions) { imageResult in
                    completion(imageResult.map {
                        MediaLoaderImage(
                            image: $0.image,
                            isAnimated: $0.isAnimated,
                            animatedImageData: $0.animatedImageData,
                            cachingKey: cachingKey
                        )
                    })
                }
            case let .failure(error):
                StreamConcurrency.onMain {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Video Loading

    open func loadVideoAsset(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoAsset, Error>) -> Void
    ) {
        cdnRequester.fileRequest(for: url, options: .init()) { result in
            switch result {
            case let .success(cdnRequest):
                var assetOptions: [String: Any] = [:]
                if let headers = cdnRequest.headers, !headers.isEmpty {
                    assetOptions["AVURLAssetHTTPHeaderFieldsKey"] = headers
                }
                let asset = AVURLAsset(url: cdnRequest.url, options: assetOptions.isEmpty ? nil : assetOptions)
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

    // MARK: - Video Preview Thumbnail Loading

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
            loadImage(url: thumbnailURL, options: ImageLoadOptions()) { [weak self] result in
                guard let self else {
                    StreamConcurrency.onMain {
                        completion(.failure(ClientError.Unknown("MediaLoader was deallocated")))
                    }
                    return
                }
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

    // MARK: - URL-Based Video Preview

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

    // MARK: - Private

    private func generateVideoPreview(
        for url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        cdnRequester.fileRequest(for: url, options: .init()) { [weak self] result in
            guard let self else {
                StreamConcurrency.onMain {
                    completion(.failure(ClientError.Unknown("MediaLoader was deallocated")))
                }
                return
            }

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
                guard let self else {
                    StreamConcurrency.onMain {
                        completion(.failure(ClientError.Unknown("MediaLoader was deallocated")))
                    }
                    return
                }

                let result: Result<MediaLoaderVideoPreview, Error>
                if let thumbnail = image {
                    result = .success(MediaLoaderVideoPreview(image: UIImage(cgImage: thumbnail)))
                } else if let error {
                    result = .failure(error)
                } else {
                    result = .failure(ClientError.Unknown("Both error and image are nil"))
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

    // MARK: - File Loading

    open func loadFile(
        at url: URL,
        options: FileLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderFile, Error>) -> Void
    ) {
        cdnRequester.fileRequest(for: url, options: .init()) { result in
            StreamConcurrency.onMain {
                completion(result.map { MediaLoaderFile(url: $0.url, headers: $0.headers) })
            }
        }
    }

    @objc private func handleMemoryWarning(_ notification: NSNotification) {
        videoPreviewCache.removeAllObjects()
    }
}
