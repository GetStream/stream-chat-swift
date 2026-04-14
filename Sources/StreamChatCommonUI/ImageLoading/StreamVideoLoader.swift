//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// The default video loader implementation using AVFoundation.
///
/// Uses the provided `CDNRequester` to sign video URLs before generating previews,
/// and falls back to the `ImageLoader` for loading thumbnail URLs.
open class StreamVideoLoader: VideoLoader, @unchecked Sendable {
    /// The CDN requester used for URL transformation before video access.
    public let cdnRequester: CDNRequester
    /// The image loader used for loading video thumbnail URLs.
    public let imageLoader: ImageLoader

    private let cache: NSCache<NSURL, UIImage>

    public init(cdnRequester: CDNRequester = StreamCDNRequester(), imageLoader: ImageLoader, countLimit: Int = 50) {
        self.cdnRequester = cdnRequester
        self.imageLoader = imageLoader
        self.cache = NSCache<NSURL, UIImage>()
        self.cache.countLimit = countLimit

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

    open func loadPreview(
        at url: URL,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        if let cached = cache.object(forKey: url as NSURL) {
            Task { @MainActor in
                completion(.success(cached))
            }
            return
        }

        generateVideoPreview(for: url, completion: completion)
    }

    open func loadPreview(
        with attachment: ChatMessageVideoAttachment,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        let videoURL = attachment.videoURL
        if let cached = cache.object(forKey: videoURL as NSURL) {
            Task { @MainActor in
                completion(.success(cached))
            }
            return
        }

        if let thumbnailURL = attachment.payload.thumbnailURL {
            imageLoader.loadImage(url: thumbnailURL, resize: nil) { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(image):
                    self.cache.setObject(image, forKey: videoURL as NSURL)
                    Task { @MainActor in
                        completion(.success(image))
                    }
                case .failure:
                    self.generateVideoPreview(for: videoURL, completion: completion)
                }
            }
        } else {
            generateVideoPreview(for: videoURL, completion: completion)
        }
    }

    // MARK: - Private

    private func generateVideoPreview(
        for url: URL,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        cdnRequester.fileRequest(for: url) { [weak self] result in
            guard let self else { return }

            let adjustedUrl: URL
            switch result {
            case let .success(cdnRequest):
                adjustedUrl = cdnRequest.url
            case let .failure(error):
                Task { @MainActor in
                    completion(.failure(error))
                }
                return
            }

            let asset = AVURLAsset(url: adjustedUrl)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            let frameTime = CMTime(seconds: 0.1, preferredTimescale: 600)

            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.generateCGImagesAsynchronously(forTimes: [.init(time: frameTime)]) { [cache = self.cache] _, image, _, _, error in
                let result: Result<UIImage, Error>
                if let thumbnail = image {
                    result = .success(UIImage(cgImage: thumbnail))
                } else if let error {
                    result = .failure(error)
                } else {
                    result = .failure(ClientError.Unknown("Both error and image are nil"))
                    return
                }

                if let image = try? result.get() {
                    cache.setObject(image, forKey: url as NSURL)
                }
                Task { @MainActor in
                    completion(result)
                }
            }
        }
    }

    @objc private func handleMemoryWarning(_ notification: NSNotification) {
        cache.removeAllObjects()
    }
}
