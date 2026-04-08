//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
@testable import StreamChatUI
import UIKit

/// A mock implementation of the image loader which loads images synchronously.
final class ImageLoader_Mock: ImageLoader, @unchecked Sendable {
    func loadImage(
        url: URL?,
        resize: ImageResize?,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        guard let url else {
            Task { @MainActor in
                completion(.failure(NSError(domain: "mock", code: 0)))
            }
            return
        }

        let image = UIImage(data: try! Data(contentsOf: url))!
        Task { @MainActor in
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
        Task { @MainActor in
            completion(images)
        }
    }
}
