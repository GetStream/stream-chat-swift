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
    lazy var loadPreviewMockFunc = MockFunc.mock(for: loadPreview(at:completion:))

    func loadPreview(at url: URL, completion: @escaping @MainActor (Result<UIImage, Error>) -> Void) {
        loadPreviewMockFunc.call(with: (url, completion))
    }
}
