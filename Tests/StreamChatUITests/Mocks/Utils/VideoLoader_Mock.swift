//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import StreamChatCommonUI
@testable import StreamChatTestTools
@testable import StreamChatUI
import UIKit

/// A mock implementation of video loader.
final class VideoLoader_Mock: VideoLoader, @unchecked Sendable {
    lazy var loadPreviewForVideoMockFunc = MockFunc.mock(for: loadPreview(at:cdnRequester:completion:))
    lazy var videoAssetMockFunc = MockFunc<URL, AVURLAsset>(result: { AVURLAsset(url: $0) })

    func loadPreview(at url: URL, cdnRequester: CDNRequester, completion: @escaping @MainActor (Result<UIImage, Error>) -> Void) {
        loadPreviewForVideoMockFunc.call(with: (url, cdnRequester, completion))
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
            MainActor.assumeIsolated {
                completion(.failure(NSError(domain: "VideoLoader_Mock", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load image from url: \(url)"])))
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

    func videoAsset(at url: URL, cdnRequester: CDNRequester) -> AVURLAsset {
        videoAssetMockFunc.callAndReturn(url)
    }
}
