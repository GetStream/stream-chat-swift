//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import AVKit
@testable import StreamChatTestTools
@testable import StreamChatUI
import UIKit

/// A mock implementation of video loader
final class MockVideoLoader: VideoLoading {
    lazy var loadPreviewForVideoMockFunc = MockFunc.mock(for: loadPreviewForVideo)
    lazy var videoAssetMockFunc = MockFunc.mock(for: videoAsset)

    func loadPreviewForVideo(at url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        loadPreviewForVideoMockFunc.call(with: (url, completion))
    }
    
    func videoAsset(at url: URL) -> AVURLAsset {
        videoAssetMockFunc.call(with: url)
        return .init(url: url)
    }
}
