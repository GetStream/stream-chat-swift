//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Nuke-backed implementation of ``ImageDownloading`` for the UIKit SDK.
public final class StreamImageDownloader: ImageDownloading, Sendable {
    public init() {}

    public func downloadImage(
        url: URL,
        options: ImageDownloadingOptions,
        completion: @escaping @MainActor (Result<DownloadedImage, Error>) -> Void
    ) {
        var urlRequest = URLRequest(url: url)
        if let headers = options.headers {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        var processors = [ImageProcessing]()
        if let resize = options.resize, resize != .zero {
            processors.append(ImageProcessors.Resize(size: resize))
        }

        let request = ImageRequest(
            urlRequest: urlRequest,
            processors: processors,
            userInfo: options.cachingKey.map { [.imageIdKey: $0] }
        )

        ImagePipeline.shared.loadImage(with: request) { result in
            StreamConcurrency.onMain {
                switch result {
                case let .success(imageResponse):
                    let isAnimated = imageResponse.container.type == .gif
                    completion(.success(DownloadedImage(
                        image: imageResponse.image,
                        isAnimated: isAnimated,
                        animatedImageData: isAnimated ? imageResponse.container.data : nil
                    )))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }
}
