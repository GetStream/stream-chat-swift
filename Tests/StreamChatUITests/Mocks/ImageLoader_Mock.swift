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

    lazy var loadVideoPreviewForVideoMockFunc = MockFunc.mock(for: loadVideoPreview(at:options:completion:))
    lazy var videoAssetMockFunc = MockFunc<URL, AVURLAsset>(result: { AVURLAsset(url: $0) })

    func loadImage(
        url: URL?,
        options: ImageLoadOptions,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
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
            completion(.success(image))
        }
    }

    func loadImages(
        from urls: [URL],
        options: ImageBatchLoadOptions,
        completion: @escaping @MainActor ([UIImage]) -> Void
    ) {
        let images = urls.compactMap { url -> UIImage? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return UIImage(data: data)
        }
        MainActor.assumeIsolated {
            completion(images)
        }
    }

    func videoAsset(at url: URL, options: VideoLoadOptions) -> AVURLAsset {
        videoAssetMockFunc.callAndReturn(url)
    }

    func loadVideoPreview(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        loadVideoPreviewForVideoMockFunc.call(with: (url, options, completion))
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
            MainActor.assumeIsolated {
                completion(.failure(NSError(domain: "ImageLoader_Mock", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load image from url: \(url)"])))
            }
            return
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                completion(.success(image))
            }
        } else {
            DispatchQueue.main.async {
                completion(.success(image))
            }
        }
    }
}
