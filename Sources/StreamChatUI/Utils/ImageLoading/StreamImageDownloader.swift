//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatCommonUI
import UIKit

/// Nuke-backed implementation of ``ImageDownloading`` for the UIKit SDK.
open class StreamImageDownloader: ImageDownloading, @unchecked Sendable {
    public init() {}

    open func downloadImage(
        url: URL,
        headers: [String: String]?,
        cachingKey: String?,
        resize: CGSize?,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        var urlRequest = URLRequest(url: url)
        if let headers {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        var processors = [ImageProcessing]()
        if let resize, resize != .zero {
            processors.append(ImageProcessors.Resize(size: resize))
        }

        let request = ImageRequest(
            urlRequest: urlRequest,
            processors: processors,
            userInfo: cachingKey.map { [.imageIdKey: $0] }
        )

        ImagePipeline.shared.loadImage(with: request) { result in
            StreamConcurrency.onMain {
                switch result {
                case let .success(imageResponse):
                    completion(.success(imageResponse.image))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }
}
