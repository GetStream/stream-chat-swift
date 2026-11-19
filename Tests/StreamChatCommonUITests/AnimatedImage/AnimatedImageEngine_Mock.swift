//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import UIKit

@MainActor
final class AnimatedImageEngine_Mock: AnimatedImageEngine {
    var onFrame: ((UIImage) -> Void)?
    var visibilityCheck: (() -> Bool)?
    var isPlaying = false

    var loadResult = true
    var loadedData: [Data] = []
    var playCallCount = 0
    var stopCallCount = 0
    var unloadCallCount = 0

    var loadCallCount: Int { loadedData.count }

    func load(data: Data, targetPixelSize: CGSize?) -> Bool {
        loadedData.append(data)
        isPlaying = false
        return loadResult
    }

    func play() {
        playCallCount += 1
        isPlaying = true
    }

    func stop() {
        stopCallCount += 1
        isPlaying = false
    }

    func unload() {
        unloadCallCount += 1
        isPlaying = false
    }

    func deliver(frame: UIImage) {
        onFrame?(frame)
    }
}
