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
    lazy var loadPreviewForVideoMockFunc = MockFunc.mock(for: loadPreview(at:completion:))
    lazy var videoAssetMockFunc = MockFunc<URL, AVURLAsset>(result: { AVURLAsset(url: $0) })

    func loadPreview(at url: URL, completion: @escaping @MainActor (Result<UIImage, Error>) -> Void) {
        loadPreviewForVideoMockFunc.call(with: (url, completion))
        guard let image = UIImage(data: try! Data(contentsOf: url)) else {
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

    func videoAsset(at url: URL) -> AVURLAsset {
        videoAssetMockFunc.callAndReturn(url)
    }
}
