//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import StreamChatCommonUI
@testable import StreamChatTestTools
@testable import StreamChatUI
import UIKit

/// A mock implementation of the media loader which loads images synchronously.
///
/// Completions are invoked inline (synchronously) so that snapshot tests
/// capture the final view state without needing an extra run-loop tick.
/// This works because snapshot tests always run on the main thread.
final class ImageLoader_Mock: MediaLoader, @unchecked Sendable {
    private let imageProcessor = StreamImageProcessor()

    lazy var loadVideoPreviewMockFunc = MockFunc.mock(for: loadVideoPreview(with:options:completion:))
    lazy var videoAssetMockFunc = MockFunc.mock(for: loadVideoAsset(at:options:completion:))

    func loadImage(
        url: URL?,
        options: ImageLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderImage, Error>) -> Void
    ) {
        guard let url else {
            MainActor.assumeIsolated {
                completion(.failure(NSError(domain: "mock", code: 0)))
            }
            return
        }

        guard let data = try? Data(contentsOf: url), var image = UIImage(data: data) else {
            MainActor.assumeIsolated {
                completion(.failure(NSError(domain: "mock", code: 0)))
            }
            return
        }

        if let resize = options.resize {
            let size = CGSize(width: resize.width, height: resize.height)
            image = imageProcessor.scale(image: image, to: size)
        }
        MainActor.assumeIsolated {
            completion(.success(MediaLoaderImage(image: image)))
        }
    }

    func loadVideoAsset(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoAsset, Error>) -> Void
    ) {
        videoAssetMockFunc.call(with: (url, options, completion))
        MainActor.assumeIsolated {
            completion(.success(MediaLoaderVideoAsset(asset: AVURLAsset(url: url))))
        }
    }

    func loadVideoPreview(
        with attachment: ChatMessageVideoAttachment,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        loadVideoPreviewMockFunc.call(with: (attachment, options, completion))
        let url = attachment.payload.thumbnailURL ?? attachment.videoURL
        loadVideoPreview(at: url, options: options, completion: completion)
    }

    func loadVideoPreview(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
            MainActor.assumeIsolated {
                completion(.failure(NSError(domain: "ImageLoader_Mock", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load image from url: \(url)"])))
            }
            return
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                completion(.success(MediaLoaderVideoPreview(image: image)))
            }
        } else {
            DispatchQueue.main.async {
                completion(.success(MediaLoaderVideoPreview(image: image)))
            }
        }
    }
}
