//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatCommonUI
@testable import StreamChatUI
import UIKit

/// A mock implementation of the image loader which loads images synchronously.
///
/// Completions are invoked inline (synchronously) so that snapshot tests
/// capture the final view state without needing an extra run-loop tick.
/// This works because snapshot tests always run on the main thread.
final class ImageLoader_Mock: ImageLoader, @unchecked Sendable {
    private let imageProcessor = StreamImageProcessor()

    func loadImage(
        url: URL?,
        resize: ImageResize?,
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

        if let resize {
            let size = CGSize(width: resize.width, height: resize.height)
            image = imageProcessor.scale(image: image, to: size)
        }
        MainActor.assumeIsolated {
            completion(.success(image))
        }
    }

    func loadImages(
        from urls: [URL],
        placeholders: [UIImage],
        loadThumbnails: Bool,
        thumbnailSize: CGSize,
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
}
